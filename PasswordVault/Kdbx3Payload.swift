//
//  Kdbx3Payload.swift
//  PasswordVault
//

import Gzip

class Kdbx3Payload {

    var database: KdbxXml.KeePassFile

    required init(database: KdbxXml.KeePassFile) {
        self.database = database
    }

    convenience init(encryptedBytes: [UInt8], compositeKey: [UInt8], header: Kdbx3Header) throws {
        let hashedCompositeKey = compositeKey.sha256()
        let transformedCompositeKey = try KdbxCrypto.aesTransform(
                seed: header.transformSeed,
                key: hashedCompositeKey,
                rounds: Int(header.transformRounds)
        )
        let transformedCompositeKeyHashed = transformedCompositeKey.sha256()
        let masterKey = (header.masterKeySeed + transformedCompositeKeyHashed).sha256()

        let decryptedBytes = try KdbxCrypto.aesDecrypt(key: masterKey, iv: header.encryptionIv, bytes: encryptedBytes)

        let dataReadStream = DataReadStream(data: Data(bytes: decryptedBytes))
        let streamStartBytes = try dataReadStream.readBytes(size: header.streamStartBytes.count)

        if streamStartBytes != header.streamStartBytes {
            throw KdbxError.databaseReadError
        }

        var payloadBytes: [UInt8]?
        repeat {
            let id = try dataReadStream.read() as UInt32
            let hash = try dataReadStream.readBytes(size: 32)
            let size = try dataReadStream.read() as UInt32

            guard size > 0 else {
                throw KdbxError.databaseReadError
            }

            let bytes = try dataReadStream.readBytes(size: Int(size))

            guard bytes.sha256() == hash else {
                throw KdbxError.databaseReadError
            }

            if id == 0 {
                payloadBytes = bytes
                break
            }
        } while (dataReadStream.hasBytesAvailable)

        if payloadBytes == nil {
            throw KdbxError.databaseReadError
        } else {
            let payloadData: Data
            if header.compressionType == .gzip {
                payloadData = try Data(bytes: payloadBytes!).gunzipped()
            } else {
                payloadData = Data(bytes: payloadBytes!)
            }

            let database = try KdbxXml.parse(data: payloadData)
            self.init(database: database)
        }
    }
}
