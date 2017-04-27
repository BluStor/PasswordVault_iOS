//
//  Kdbx4Payload.swift
//  PasswordVault
//

import Gzip

class Kdbx4Payload {

    var database: KdbxXml.KeePassFile

    required init(database: KdbxXml.KeePassFile) {
        self.database = database
    }

    convenience init(encryptedBytes: [UInt8], compositeKey: [UInt8], header: Kdbx4Header) throws {
        fatalError("Not implemented.")
    }
}
