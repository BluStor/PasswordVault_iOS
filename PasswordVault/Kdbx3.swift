//
//  Kdbx3.swift
//  PasswordVault
//

import Foundation

class Kdbx3: KdbxProtocol {

    internal let header: Kdbx3Header
    internal var database: KdbxXml.KeePassFile

    required init(header: Kdbx3Header, database: KdbxXml.KeePassFile) {
        self.header = header
        self.database = database
    }

    convenience init(data: Data, compositeKey: [UInt8]) throws {
        let dataReadStream = DataReadStream(data: data)

        do {
            let header = try Kdbx3Header(dataReadStream: dataReadStream)

            let encryptedBytes = try dataReadStream.readBytes(size: dataReadStream.bytesAvailable)
            let payload = try Kdbx3Payload(encryptedBytes: encryptedBytes, compositeKey: compositeKey, header: header)

            self.init(header: header, database: payload.database)
        } catch Kdbx3Header.ReadError.unknownVersion {
            throw KdbxError.databaseVersionUnsupportedError
        }
    }

    func delete(groupUUID: String) -> Bool {
        if let index = database.root.group.groups.index(where: { $0.uuid == groupUUID }) {
            database.root.group.groups.remove(at: index)
            return true
        }

        for (index, _) in database.root.group.groups.enumerated() {
            if database.root.group.groups[index].delete(groupUUID: groupUUID) {
                return true
            }
        }

        return false
    }

    func delete(entryUUID: String) -> Bool {
        if let index = database.root.group.entries.index(where: { $0.uuid == entryUUID }) {
            database.root.group.groups.remove(at: index)
        }

        for (index, _) in database.root.group.groups.enumerated() {
            if database.root.group.groups[index].delete(entryUUID: entryUUID) {
                return true
            }
        }

        return false
    }

    func encrypt(compositeKey: [UInt8]) throws -> Data {
        guard let xmlData = database.build().xml.data(using: .utf8) else {
            throw KdbxError.databaseWriteError
        }

        header.masterKeySeed = [UInt8].random(size: 32)
        header.transformSeed = [UInt8].random(size: 32)
        header.encryptionIv = [UInt8].random(size: 16)
        header.protectedStreamKey = [UInt8].random(size: 32)
        header.streamStartBytes = [UInt8].random(size: 32)

        let hashedCompositeKey = compositeKey.sha256()
        let transformedCompositeKey = try KdbxCrypto.aesTransform(
                bytes: header.transformSeed,
                key: hashedCompositeKey,
                rounds: Int(header.transformRounds)
        )
        let transformedCompositeKeyHashed = transformedCompositeKey.sha256()
        let masterKey = (header.masterKeySeed + transformedCompositeKeyHashed).sha256()

        let dataWriteStream = DataWriteStream()

        try dataWriteStream.write(Data(bytes: Kdbx.magicNumbers))
        try dataWriteStream.write(UInt16(1))
        try dataWriteStream.write(UInt16(3))

        try dataWriteStream.write(Kdbx3Header.ReadType.cipherUuid.rawValue)
        switch header.cipherType {
        case .aes:
            let data = KdbxCrypto.aesUuid.data
            try dataWriteStream.write(UInt16(data.count))
            try dataWriteStream.write(KdbxCrypto.aesUuid.data)
        }

        try dataWriteStream.write(Kdbx3Header.ReadType.compressionType.rawValue)
        try dataWriteStream.write(UInt16(4))
        try dataWriteStream.write(header.compressionType.rawValue)

        try dataWriteStream.write(Kdbx3Header.ReadType.masterKeySeed.rawValue)
        try dataWriteStream.write(UInt16(header.masterKeySeed.count))
        try dataWriteStream.write(Data(bytes: header.masterKeySeed))

        try dataWriteStream.write(Kdbx3Header.ReadType.transformSeed.rawValue)
        try dataWriteStream.write(UInt16(header.transformSeed.count))
        try dataWriteStream.write(Data(bytes: header.transformSeed))

        try dataWriteStream.write(Kdbx3Header.ReadType.transformRounds.rawValue)
        try dataWriteStream.write(UInt16(8))
        try dataWriteStream.write(header.transformRounds)

        try dataWriteStream.write(Kdbx3Header.ReadType.encryptionIv.rawValue)
        try dataWriteStream.write(UInt16(header.encryptionIv.count))
        try dataWriteStream.write(Data(bytes: header.encryptionIv))

        try dataWriteStream.write(Kdbx3Header.ReadType.protectedStreamKey.rawValue)
        try dataWriteStream.write(UInt16(header.protectedStreamKey.count))
        try dataWriteStream.write(Data(bytes: header.protectedStreamKey))

        try dataWriteStream.write(Kdbx3Header.ReadType.streamStartBytes.rawValue)
        try dataWriteStream.write(UInt16(header.streamStartBytes.count))
        try dataWriteStream.write(Data(bytes: header.streamStartBytes))

        try dataWriteStream.write(Kdbx3Header.ReadType.innerAlgorithm.rawValue)
        try dataWriteStream.write(UInt16(4))
        try dataWriteStream.write(header.innerAlgorithm.rawValue)

        try dataWriteStream.write(Kdbx3Header.ReadType.end.rawValue)
        try dataWriteStream.write(UInt16(4))
        try dataWriteStream.write(Data(bytes: [UInt8](repeating: 0x0, count: 4)))

        let payloadData: Data
        switch header.compressionType {
        case .none:
            payloadData = xmlData
        case .gzip:
            payloadData = try xmlData.gzipped()
        }

        let encDataWriteStream = DataWriteStream()
        try encDataWriteStream.write(Data(bytes: header.streamStartBytes))
        try encDataWriteStream.write(UInt32(0))
        try encDataWriteStream.write(Data(bytes: [UInt8](payloadData).sha256()))
        try encDataWriteStream.write(UInt32(payloadData.count))
        try encDataWriteStream.write(payloadData)

        guard let encData = encDataWriteStream.data else {
            throw KdbxError.databaseWriteError
        }

        let encryptedBytes = try KdbxCrypto.aes(operation: .encrypt, bytes: [UInt8](encData), key: masterKey, iv: header.encryptionIv)
        try dataWriteStream.write(Data(bytes: encryptedBytes))

        guard let data = dataWriteStream.data else {
            throw KdbxError.databaseWriteError
        }

        return data
    }

    func encrypt(password: String) throws -> Data {
        return try encrypt(compositeKey: password.sha256())
    }

    func update(entry: KdbxXml.Entry) -> Bool {
        if let index = database.root.group.entries.index(where: { $0.uuid == entry.uuid }) {
            database.root.group.entries[index] = entry
        } else {
            for (index, _) in database.root.group.groups.enumerated() {
                if database.root.group.groups[index].update(entry: entry) {
                    return true
                }
            }
        }

        return false
    }

    func update(group: KdbxXml.Group) -> Bool {
        if database.root.group.uuid == group.uuid {
            database.root.group = group
        } else {
            for (index, _) in database.root.group.groups.enumerated() {
                if database.root.group.groups[index].update(group: group) {
                    return true
                }
            }
        }

        return false
    }
}
