//
//  Kdbx.swift
//  PasswordVault
//

import Foundation

protocol KdbxProtocol {

    var database: KdbxXml.KeePassFile { get }
    func delete(entryUUID: String) -> Bool
    func delete(groupUUID: String) -> Bool
    func encrypt(compositeKey: [UInt8]) throws -> Data
    func encrypt(password: String) throws -> Data
    func unprotect() throws
    func update(entry: KdbxXml.Entry) -> Bool
    func update(group: KdbxXml.Group) -> Bool
}

class Kdbx {

    enum CipherType {
        case aes
    }

    enum InnerAlgorithm {
        case none
        case salsa20
    }

    static let magicNumbers: [UInt8] = [0x03, 0xD9, 0xA2, 0x9A, 0x67, 0xFB, 0x4B, 0xB5]

    private let kdbx: KdbxProtocol

    internal var database: KdbxXml.KeePassFile {
        return kdbx.database
    }

    required init(data: Data, compositeKey: [UInt8]) throws {
        do {
            // TODO: KDBX4 support
            kdbx = try Kdbx4(data: data, compositeKey: compositeKey)
        } catch (KdbxError.databaseVersionUnsupportedError) {
            kdbx = try Kdbx3(data: data, compositeKey: compositeKey)
        }
    }

    convenience init(data: Data, password: String) throws {
        try self.init(data: data, compositeKey: password.sha256())
    }

    func delete(entryUUID: String) -> Bool {
        return kdbx.delete(entryUUID: entryUUID)
    }

    func delete(groupUUID: String) -> Bool {
        return kdbx.delete(groupUUID: groupUUID)
    }

    func encrypt(compositeKey: [UInt8]) throws -> Data {
        return try kdbx.encrypt(compositeKey: compositeKey)
    }

    func encrypt(password: String) throws -> Data {
        return try kdbx.encrypt(password: password)
    }

    func findEntries(title: String) -> [KdbxXml.Entry] {
        var entries = Array<KdbxXml.Entry>()
        entries.append(contentsOf: database.root.group.findEntries(title: title))
        database.root.group.groups.forEach({ (group) in
            entries.append(contentsOf: group.findEntries(title: title))
        })
        return entries
    }

    func get(groupUUID: String) -> KdbxXml.Group? {
        if database.root.group.uuid == groupUUID {
            return database.root.group
        } else {
            for group in database.root.group.groups {
                if group.uuid == groupUUID {
                    return group
                }
                if let foundGroup = group.get(groupUUID: groupUUID) {
                    return foundGroup
                }
            }
        }

        return nil
    }

    func get(entryUUID: String) -> KdbxXml.Entry? {
        for group in database.root.group.groups {
            if let foundEntry = group.get(entryUUID: entryUUID) {
                return foundEntry
            }
        }

        return nil
    }

    func unprotect() throws {
        try kdbx.unprotect()
    }

    func update(entry: KdbxXml.Entry) -> Bool {
        return kdbx.update(entry: entry)
    }

    func update(group: KdbxXml.Group) -> Bool {
        return kdbx.update(group: group)
    }
}
