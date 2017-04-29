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
        // Master key

        let hashedCompositeKey = compositeKey.sha256()
        let transformedCompositeKey = try KdbxCrypto.aesTransform(
                bytes: header.transformSeed,
                key: hashedCompositeKey,
                rounds: Int(header.transformRounds)
        )
        let transformedCompositeKeyHashed = transformedCompositeKey.sha256()
        let masterKey = (header.masterKeySeed + transformedCompositeKeyHashed).sha256()

        // Decrypt with master key and initialization vector

        let decryptedBytes: [UInt8]
        switch header.cipherType {
        case .aes:
            decryptedBytes = try KdbxCrypto.aes(operation: .decrypt, bytes: encryptedBytes, key: masterKey, iv: header.encryptionIv)
        }

        let dataReadStream = DataReadStream(data: Data(bytes: decryptedBytes))

        // Verify stream start bytes

        let streamStartBytes = try dataReadStream.readBytes(size: header.streamStartBytes.count)

        if streamStartBytes != header.streamStartBytes {
            throw KdbxError.databaseReadError
        }

        // Read payload block (block 0 is XML)

        var payloadBytes = [UInt8]()
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
                payloadBytes.append(contentsOf: bytes)
                break
            }
        } while (dataReadStream.hasBytesAvailable)

        guard !payloadBytes.isEmpty else {
            throw KdbxError.databaseReadError
        }

        // Decompress

        let payloadData: Data
        switch header.compressionType {
        case .none:
            payloadData = Data(bytes: payloadBytes)
        case .gzip:
            payloadData = try Data(bytes: payloadBytes).gunzipped()
        }

        // Parse

        let database = try KdbxXml.parse(data: payloadData)

        self.init(database: database)
    }
}
