//
//  Kdbx3.swift
//  GateKeeper
//

import Foundation

class Kdbx3: KdbxProtocol {

    private var header: Kdbx3Header
    var database: KdbxXml.KeePassFile
    var transformationRounds: Int {
        get {
            return Int(header.transformRounds)
        }
        set {
            header.transformRounds = UInt64(newValue)
        }
    }

    required init(header: Kdbx3Header, database: KdbxXml.KeePassFile) {
        self.header = header
        self.database = database
    }

    convenience init(encryptedData: Data, compositeKey: [UInt8]) throws {
        let readStream = DataReadStream(data: encryptedData)

        do {
            let header = try Kdbx3Header(readStream: readStream)

            let encryptedBytes = try readStream.readBytes(size: readStream.bytesAvailable)
            let payload = try Kdbx3Payload(encryptedBytes: encryptedBytes, compositeKey: compositeKey, header: header)

            self.init(header: header, database: payload.database)
        } catch Kdbx3Header.ReadError.unknownVersion {
            throw KdbxError.databaseVersionUnsupported
        }
    }

    func delete(groupUUID: UUID) {
        if let index = database.root.group.groups.index(where: { $0.uuid == groupUUID }) {
            database.root.group.groups.remove(at: index)
        } else {
            for index in database.root.group.groups.indices {
                database.root.group.groups[index].delete(groupUUID: groupUUID)
            }
        }
    }

    func delete(entryUUID: UUID) {
        if let index = database.root.group.entries.index(where: { $0.uuid == entryUUID }) {
            database.root.group.entries.remove(at: index)
        } else {
            for index in database.root.group.groups.indices {
                database.root.group.groups[index].delete(entryUUID: entryUUID)
            }
        }
    }

    func encrypt(compositeKey: [UInt8]) throws -> Data {
        // XML

        guard let xmlData = database.build().xmlCompact.data(using: .utf8) else {
            throw KdbxError.encryptionFailed
        }

        // Randomize

        header.masterKeySeed = [UInt8].random(size: 32)
        header.transformSeed = [UInt8].random(size: 32)
        header.encryptionIv = [UInt8].random(size: 16)
        header.protectedStreamKey = [UInt8].random(size: 32)
        header.streamStartBytes = [UInt8].random(size: 32)

        // Master key

        let hashedCompositeKey = compositeKey.sha256()
        let transformedCompositeKey = try KdbxCrypto.aesTransform(
            bytes: header.transformSeed,
            key: hashedCompositeKey,
            rounds: Int(header.transformRounds)
        )
        let transformedCompositeKeyHashed = transformedCompositeKey.sha256()
        let masterKey = (header.masterKeySeed + transformedCompositeKeyHashed).sha256()

        // Write: Magic numbers, version

        let writeStream = DataWriteStream()

        try writeStream.write(Data(bytes: Kdbx.magicNumbers))
        try writeStream.write(UInt16(1))
        try writeStream.write(UInt16(3))

        // Write: Dynamic header

        try writeStream.write(Kdbx3Header.ReadType.cipherUuid.rawValue)
        switch header.cipherType {
        case .aes:
            let data = KdbxCrypto.aesUUID.data
            try writeStream.write(UInt16(data.count))
            try writeStream.write(KdbxCrypto.aesUUID.data)
        }

        try writeStream.write(Kdbx3Header.ReadType.compressionType.rawValue)
        try writeStream.write(UInt16(4))
        try writeStream.write(header.compressionType.rawValue)

        try writeStream.write(Kdbx3Header.ReadType.masterKeySeed.rawValue)
        try writeStream.write(UInt16(header.masterKeySeed.count))
        try writeStream.write(Data(bytes: header.masterKeySeed))

        try writeStream.write(Kdbx3Header.ReadType.transformSeed.rawValue)
        try writeStream.write(UInt16(header.transformSeed.count))
        try writeStream.write(Data(bytes: header.transformSeed))

        try writeStream.write(Kdbx3Header.ReadType.transformRounds.rawValue)
        try writeStream.write(UInt16(8))
        try writeStream.write(header.transformRounds)

        try writeStream.write(Kdbx3Header.ReadType.encryptionIv.rawValue)
        try writeStream.write(UInt16(header.encryptionIv.count))
        try writeStream.write(Data(bytes: header.encryptionIv))

        try writeStream.write(Kdbx3Header.ReadType.protectedStreamKey.rawValue)
        try writeStream.write(UInt16(header.protectedStreamKey.count))
        try writeStream.write(Data(bytes: header.protectedStreamKey))

        try writeStream.write(Kdbx3Header.ReadType.streamStartBytes.rawValue)
        try writeStream.write(UInt16(header.streamStartBytes.count))
        try writeStream.write(Data(bytes: header.streamStartBytes))

        try writeStream.write(Kdbx3Header.ReadType.streamAlgorithm.rawValue)
        try writeStream.write(UInt16(4))
        try writeStream.write(header.streamAlgorithm.rawValue)

        try writeStream.write(Kdbx3Header.ReadType.end.rawValue)
        try writeStream.write(UInt16(4))
        try writeStream.write(Data(bytes: [UInt8](repeating: 0x0, count: 4)))

        // Write: Payload block

        let payloadData: Data
        switch header.compressionType {
        case .none:
            payloadData = xmlData
        case .gzip:
            payloadData = try xmlData.gzipped()
        }

        let payloadWriteStream = DataWriteStream()
        try payloadWriteStream.write(Data(bytes: header.streamStartBytes))
        try payloadWriteStream.write(UInt32(0))
        try payloadWriteStream.write(Data(bytes: [UInt8](payloadData).sha256()))
        try payloadWriteStream.write(UInt32(payloadData.count))
        try payloadWriteStream.write(payloadData)
        try payloadWriteStream.write(UInt32(1))
        try payloadWriteStream.write(Data(bytes: [UInt8](repeating: 0x0, count: 32)))
        try payloadWriteStream.write(UInt32(0))

        let encryptedBytes = try KdbxCrypto.aes(operation: .encrypt, bytes: [UInt8](payloadWriteStream.data), key: masterKey, iv: header.encryptionIv)
        try writeStream.write(Data(bytes: encryptedBytes))

        return writeStream.data
    }

    func update(entry: KdbxXml.Entry) {
        if let index = database.root.group.entries.index(where: { $0.uuid == entry.uuid }) {
            database.root.group.entries[index] = entry
        } else {
            for index in database.root.group.groups.indices {
                database.root.group.groups[index].update(entry: entry)
            }
        }
    }

    func update(group: KdbxXml.Group) {
        if database.root.group.uuid == group.uuid {
            database.root.group = group
        } else {
            if let index = database.root.group.groups.index(where: { $0.uuid == group.uuid }) {
                database.root.group.groups[index] = group
            } else {
                for index in database.root.group.groups.indices {
                    database.root.group.groups[index].update(group: group)
                }
            }
        }
    }
}
