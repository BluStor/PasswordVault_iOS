//
//  Kdbx4.swift
//  PasswordVault
//

import Foundation

class Kdbx4: KdbxProtocol {

    internal let database: KdbxXml.KeePassFile
    internal let header: Kdbx4Header

    required init(database: KdbxXml.KeePassFile, header: Kdbx4Header) {
        self.database = database
        self.header = header
    }

    convenience init(data: Data, compositeKey: [UInt8]) throws {
        let dataReadStream = DataReadStream(data: data)

        do {
            let header = try Kdbx4Header(dataReadStream: dataReadStream)

            let encryptedBytes = try dataReadStream.readBytes(size: dataReadStream.bytesAvailable)
            let payload = try Kdbx4Payload(encryptedBytes: encryptedBytes, compositeKey: compositeKey, header: header)

            self.init(database: payload.database, header: header)
        } catch Kdbx4Header.ReadError.unknownVersion {
            throw KdbxError.databaseVersionUnsupportedError
        }
    }

    func delete(groupUUID: String) -> Bool {
        return false
    }

    func delete(entryUUID: String) -> Bool {
        return false
    }

    func encrypt(compositeKey: [UInt8]) throws -> Data {
        fatalError("Not implemented.")
    }

    func encrypt(password: String) throws -> Data {
        return try encrypt(compositeKey: password.sha256())
    }

    func unprotect() {
        fatalError("Not implemented.")
    }

    func update(entry: KdbxXml.Entry) -> Bool {
        return false
    }

    func update(group: KdbxXml.Group) -> Bool {
        return false
    }
}
