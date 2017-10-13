//
//  Kdbx4.swift
//  GateKeeper
//

import Foundation

class Kdbx4: KdbxProtocol {

    private var header: Kdbx4Header
    var database: KdbxXml.KeePassFile
    var transformationRounds: Int {
        get {
            return Int(header.transformRounds)
        }
        set {
            header.transformRounds = UInt64(newValue)
        }
    }

    required init(database: KdbxXml.KeePassFile, header: Kdbx4Header) {
        self.database = database
        self.header = header
    }

    convenience init(encryptedData: Data, compositeKey: [UInt8]) throws {
        let readStream = DataReadStream(data: encryptedData)

        do {
            let header = try Kdbx4Header(readStream: readStream)

            let encryptedBytes = try readStream.readBytes(size: readStream.bytesAvailable)
            let payload = try Kdbx4Payload(encryptedBytes: encryptedBytes, compositeKey: compositeKey, header: header)

            self.init(database: payload.database, header: header)
        } catch Kdbx4Header.ReadError.unknownVersion {
            throw KdbxError.databaseVersionUnsupported
        }
    }

    func delete(groupUUID: UUID) {
        fatalError("Not implemented.")
    }

    func delete(entryUUID: UUID) {
        fatalError("Not implemented.")
    }

    func encrypt(compositeKey: [UInt8]) throws -> Data {
        fatalError("Not implemented.")
    }

    func update(entry: KdbxXml.Entry) {
        fatalError("Not implemented.")
    }

    func update(group: KdbxXml.Group) {
        fatalError("Not implemented.")
    }
}
