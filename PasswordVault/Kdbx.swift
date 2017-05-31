//
//  Kdbx.swift
//  PasswordVault
//

import Foundation

enum KdbxError: Error {
    case databaseVersionUnsupported
    case decryptionFailed
    case encryptionFailed
}

protocol KdbxProtocol {
    var database: KdbxXml.KeePassFile { get set }
    var transformationRounds: Int { get set }

    func delete(entryUUID: String)
    func delete(groupUUID: String)
    func encrypt(compositeKey: [UInt8]) throws -> Data
    func update(entry: KdbxXml.Entry)
    func update(group: KdbxXml.Group)
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

    private var kdbx: KdbxProtocol
    private var compositeKey: [UInt8]

    var database: KdbxXml.KeePassFile {
        return kdbx.database
    }

    var transformationRounds: Int {
        get {
            return kdbx.transformationRounds
        }
        set {
            kdbx.transformationRounds = newValue
        }
    }

    required init(encryptedData: Data, compositeKey: [UInt8]) throws {
        self.compositeKey = compositeKey

        do {
            kdbx = try Kdbx4(encryptedData: encryptedData, compositeKey: compositeKey)
        } catch KdbxError.databaseVersionUnsupported {
            kdbx = try Kdbx3(encryptedData: encryptedData, compositeKey: compositeKey)
        }
    }

    required init(compositeKey: [UInt8]) {
        let header = Kdbx3Header()

        let memoryProtection = KdbxXml.MemoryProtection(
            isTitleProtected: false,
            isUsernameProtected: false,
            isPasswordProtected: false,
            isUrlProtected: false,
            isNotesProtected: false
        )

        let meta = KdbxXml.Meta(
            generator: "PasswordVault",
            headerHash: "",
            databaseName: "Passwords",
            databaseNameChanged: nil,
            databaseDescription: "",
            databaseDescriptionChanged: nil,
            defaultUsername: "",
            defaultUsernameChanged: nil,
            maintenanceHistoryDays: nil,
            color: "",
            masterKeyChanged: nil,
            masterKeyChangeRec: -1,
            masterKeyChangeForce: -1,
            memoryProtection: memoryProtection,
            recycleBinEnabled: false,
            recycleBinUUID: "",
            recycleBinChanged: nil,
            entryTemplatesGroup: "",
            entryTemplatesGroupChanged: nil,
            historyMaxItems: 10,
            historyMaxSize: 6291456,
            lastSelectedGroup: "",
            lastTopVisibleGroup: "",
            binaries: [],
            customData: ""
        )

        let now = Date()

        let times = KdbxXml.Times(
            lastModificationTime: now,
            creationTime: now,
            lastAccessTime: now,
            expiryTime: now,
            expires: false,
            usageCount: 0,
            locationChanged: nil
        )

        let group = KdbxXml.Group(
            uuid: UUID().uuidString,
            name: "PasswordVault",
            notes: "",
            iconId: 49,
            times: times,
            isExpanded: true,
            defaultAutoTypeSequence: "{USERNAME}{TAB}{PASSWORD}",
            enableAutoType: false,
            enableSearching: true,
            lastTopVisibleEntry: "",
            groups: [],
            entries: []
        )

        let root = KdbxXml.Root(group: group, deletedObjects: [])
        let database = KdbxXml.KeePassFile(meta: meta, root: root)

        self.kdbx = Kdbx3(header: header, database: database)
        self.compositeKey = compositeKey
    }

    convenience init(encryptedData: Data, password: String) throws {
        try self.init(encryptedData: encryptedData, compositeKey: password.sha256())
    }

    convenience init(password: String) {
        self.init(compositeKey: password.sha256())
    }

    func add(groupUUID: String, entry: KdbxXml.Entry) {
        if kdbx.database.root.group.uuid == groupUUID {
            kdbx.database.root.group.entries.append(entry)
        } else {
            for index in kdbx.database.root.group.groups.indices {
                kdbx.database.root.group.groups[index].add(groupUUID: groupUUID, entry: entry)
            }
        }
    }

    func add(groupUUID: String, group: KdbxXml.Group) {
        if kdbx.database.root.group.uuid == groupUUID {
            kdbx.database.root.group.groups.append(group)
        } else {
            for index in kdbx.database.root.group.groups.indices {
                kdbx.database.root.group.groups[index].add(groupUUID: groupUUID, group: group)
            }
        }
    }

    func delete(entryUUID: String) {
        kdbx.delete(entryUUID: entryUUID)
    }

    func delete(groupUUID: String) {
        kdbx.delete(groupUUID: groupUUID)
    }

    func encrypt() throws -> Data {
        return try kdbx.encrypt(compositeKey: compositeKey)
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

    func setPassword(_ password: String) {
        compositeKey = password.sha256()
    }

    func update(entry: KdbxXml.Entry) {
        kdbx.update(entry: entry)
    }

    func update(group: KdbxXml.Group) {
        kdbx.update(group: group)
    }
}
