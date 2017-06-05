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

        let readStream = DataReadStream(data: Data(bytes: decryptedBytes))

        // Verify stream start bytes

        let streamStartBytes = try readStream.readBytes(size: header.streamStartBytes.count)

        if streamStartBytes != header.streamStartBytes {
            throw KdbxError.decryptionFailed
        }

        // Read payload block (block 0 is XML)

        var payloadBytes = [UInt8]()
        repeat {
            let id = try readStream.read() as UInt32
            let hash = try readStream.readBytes(size: 32)
            let size = try readStream.read() as UInt32

            guard size > 0 else {
                throw KdbxError.decryptionFailed
            }

            let bytes = try readStream.readBytes(size: Int(size))

            guard bytes.sha256() == hash else {
                throw KdbxError.decryptionFailed
            }

            if id == 0 {
                payloadBytes.append(contentsOf: bytes)
                break
            }
        } while (readStream.hasBytesAvailable)

        guard !payloadBytes.isEmpty else {
            throw KdbxError.decryptionFailed
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

        var database = try KdbxXml.parse(data: payloadData)

        // Unprotect

        switch header.streamAlgorithm {
        case .salsa20:
            let salsaKey = header.protectedStreamKey.sha256()
            let iv = [0xE8, 0x30, 0x09, 0x4B, 0x97, 0x20, 0x5D, 0x2A] as [UInt8]

            let streamCipher = Salsa20(key: salsaKey, iv: iv)
            try database.unprotect(streamCipher: streamCipher)
        }

        self.init(database: database)
    }
}
