//
//  KdbxXml.swift
//  PasswordVault
//

import AEXML

class KdbxXml {

    struct Association {

        var window: String
        var keystrokeSequence: String

        static func parse(elem: AEXMLElement) -> Association? {
            guard elem.error == nil else {
                return nil
            }

            return Association(
                window: elem["Window"].string,
                keystrokeSequence: elem["KeystrokeSequence"].string
            )
        }

        func build() -> AEXMLElement {
            let elem = AEXMLElement(name: "Association")
            elem.addChild(name: "Window", value: window, attributes: [:])
            elem.addChild(name: "KeystrokeSequence", value: keystrokeSequence, attributes: [:])
            return elem
        }
    }

    struct AutoType {

        var enabled: Bool
        var dataTransferObfuscation: Int?
        var association: Association?

        static func parse(elem: AEXMLElement) -> AutoType {
            let association = Association.parse(elem: elem["Association"])

            return AutoType(
                enabled: elem["Enabled"].string == "True",
                dataTransferObfuscation: elem["DataTransferObfuscation"].int,
                association: association
            )
        }

        func build() -> AEXMLElement {
            let elem = AEXMLElement(name: "AutoType")
            elem.addChild(name: "Enabled", value: enabled.xmlString, attributes: [:])
            elem.addChild(name: "DataTransferObfuscation", value: dataTransferObfuscation?.xmlString, attributes: [:])

            if let association = association {
                elem.addChild(association.build())
            } else {
                elem.addChild(name: "Association")
            }

            return elem
        }
    }

    struct Binary {

        var id: String
        var compressed: Bool
        var content: String

        static func parse(elem: AEXMLElement) -> Binary {

            return Binary(
                id: elem.attributes["ID"]!,
                compressed: elem.attributes["Compressed"]!.xmlBool,
                content: elem.string
            )
        }

        func build() -> AEXMLElement {
            let elem = AEXMLElement(name: "Binary", value: content, attributes: [
                    "ID": id,
                    "Compressed": compressed.xmlString
                ]
            )
            return elem
        }
    }

    struct DeletedObject {

        var uuid: String
        var deletionTime: Date

        static func parse(elem: AEXMLElement) -> DeletedObject {
            return DeletedObject(
                uuid: elem["UUID"].string,
                deletionTime: elem["DeletionTime"].string.xmlDate!
            )
        }

        func build() -> AEXMLElement {
            let elem = AEXMLElement(name: "DeletedObject")
            elem.addChild(name: "UUID", value: uuid, attributes: [:])
            elem.addChild(name: "DeletionTime", value: deletionTime.xmlString, attributes: [:])
            return elem
        }
    }

    struct Entry {

        var uuid: String
        var iconId: Int
        var foregroundColor: String
        var backgroundColor: String
        var overrideURL: String
        var tags: String
        var times: Times
        var autoType: AutoType
        var strings: [Str]
        var histories: [Entry]

        static func parse(elem: AEXMLElement) -> Entry {
            let times = Times.parse(elem: elem["Times"])
            let autoType = AutoType.parse(elem: elem["AutoType"])

            var histories = [Entry]()
            if let children = elem["History"]["Entry"].all {
                for elem in children {
                    let entry = Entry.parse(elem: elem)
                    histories.append(entry)
                }
            }

            var strings = [Str]()
            if let children = elem["String"].all {
                for elem in children {
                    let str = Str.parse(elem: elem)
                    strings.append(str)
                }
            }

            return Entry(
                uuid: elem["UUID"].string,
                iconId: elem["IconID"].int!,
                foregroundColor: elem["ForegroundColor"].string,
                backgroundColor: elem["BackgroundColor"].string,
                overrideURL: elem["OverrideURL"].string,
                tags: elem["Tags"].string,
                times: times,
                autoType: autoType,
                strings: strings,
                histories: histories
            )
        }

        func build() -> AEXMLElement {
            let elem = AEXMLElement(name: "Entry")
            elem.addChild(name: "UUID", value: uuid, attributes: [:])
            elem.addChild(name: "IconID", value: iconId.xmlString, attributes: [:])
            elem.addChild(name: "ForegroundColor", value: foregroundColor, attributes: [:])
            elem.addChild(name: "BackgroundColor", value: backgroundColor, attributes: [:])
            elem.addChild(name: "OverrideURL", value: overrideURL, attributes: [:])
            elem.addChild(name: "Tags", value: tags, attributes: [:])
            elem.addChild(times.build())

            for str in strings {
                elem.addChild(str.build())
            }

            let historyElem = elem.addChild(name: "History")
            for entry in histories {
                historyElem.addChild(entry.build())
            }
            elem.addChild(historyElem)

            return elem
        }

        func getStr(key: String) -> Str? {
            guard let str = strings.first(where: { $0.key == key }) else {
                return nil
            }

            return str
        }

        mutating func setStr(key: String, value: String, isProtected: Bool) {
            if let i = strings.index(where: { $0.key == key }) {
                strings[i].value = value
                strings[i].isProtected = isProtected
            } else {
                strings.append(Str(key: key, value: value, isProtected: isProtected))
            }
        }

        mutating func unprotect(streamCipher: KdbxStreamCipher) throws {
            for i in strings.indices where strings[i].isProtected {
                strings[i].value = try streamCipher.unprotect(string: strings[i].value)
            }
        }
    }

    struct Group {

        var uuid: String
        var name: String
        var notes: String
        var iconId: Int
        var times: Times
        var isExpanded: Bool
        var defaultAutoTypeSequence: String
        var enableAutoType: Bool
        var enableSearching: Bool
        var lastTopVisibleEntry: String
        var groups: [Group]
        var entries: [Entry]

        var itemCount: Int {
            return groups.count + entries.count
        }

        static func parse(elem: AEXMLElement) -> Group {
            let times = Times.parse(elem: elem["Times"])

            var groups = [Group]()
            if let children = elem["Group"].all {
                for elem in children {
                    let group = Group.parse(elem: elem)
                    groups.append(group)
                }
            }

            var entries = [Entry]()
            if let children = elem["Entry"].all {
                for elem in children {
                    let entry = Entry.parse(elem: elem)
                    entries.append(entry)
                }
            }

            return Group(
                uuid: elem["UUID"].string,
                name: elem["Name"].string,
                notes: elem["Notes"].string,
                iconId: elem["IconID"].int!,
                times: times,
                isExpanded: elem["IsExpanded"].string == "True",
                defaultAutoTypeSequence: elem["DefaultAutoTypeSequence"].string,
                enableAutoType: elem["EnableAutoType"].string == "True",
                enableSearching: elem["EnableSearching"].string == "True",
                lastTopVisibleEntry: elem["LastTopVisibleEntry"].string,
                groups: groups,
                entries: entries
            )
        }

        mutating func add(groupUUID: String, entry: Entry) {
            if uuid == groupUUID {
                entries.append(entry)
            } else {
                for index in groups.indices {
                    groups[index].add(groupUUID: groupUUID, entry: entry)
                }
            }
        }

        mutating func add(groupUUID: String, group: Group) {
            if uuid == groupUUID {
                groups.append(group)
            } else {
                for index in groups.indices {
                    groups[index].add(groupUUID: groupUUID, group: group)
                }
            }
        }

        func build() -> AEXMLElement {
            let elem = AEXMLElement(name: "Group")
            elem.addChild(name: "UUID", value: uuid, attributes: [:])
            elem.addChild(name: "Name", value: name, attributes: [:])
            elem.addChild(name: "Notes", value: notes, attributes: [:])
            elem.addChild(name: "IconID", value: iconId.xmlString, attributes: [:])
            elem.addChild(times.build())
            elem.addChild(name: "IsExpanded", value: isExpanded.xmlString, attributes: [:])
            elem.addChild(name: "DefaultAutoTypeSequence", value: defaultAutoTypeSequence, attributes: [:])
            elem.addChild(name: "EnableAutoType", value: enableAutoType.xmlString, attributes: [:])
            elem.addChild(name: "EnableSearching", value: enableSearching.xmlString, attributes: [:])
            elem.addChild(name: "LastTopVisibleEntry", value: lastTopVisibleEntry, attributes: [:])

            for group in groups {
                elem.addChild(group.build())
            }

            for entry in entries {
                elem.addChild(entry.build())
            }

            return elem
        }

        mutating func delete(entryUUID: String) {
            if let index = entries.index(where: { $0.uuid == entryUUID}) {
                entries.remove(at: index)
                return
            } else {
                for index in groups.indices {
                    groups[index].delete(entryUUID: entryUUID)
                }
            }
        }

        mutating func delete(groupUUID: String) {
            if let index = groups.index(where: { $0.uuid == groupUUID}) {
                groups.remove(at: index)
                return
            } else {
                for index in groups.indices {
                    groups[index].delete(groupUUID: groupUUID)
                }
            }
        }

        func findEntries(title: String) -> [Entry] {
            var foundEntries = [Entry]()
            let lowercasedTitle = title.lowercased()

            let filteredEntries = entries.filter { (entry) -> Bool in
                if let title = entry.getStr(key: "Title")?.value {
                    return title.lowercased() == lowercasedTitle
                } else {
                    return false
                }
            }

            foundEntries.append(contentsOf: filteredEntries)

            groups.forEach { (group) in
                foundEntries.append(contentsOf: group.findEntries(title: title))
            }

            return foundEntries
        }

        func get(groupUUID: String) -> Group? {
            for group in groups {
                if group.uuid == groupUUID {
                    return group
                }

                if let foundGroup = group.get(groupUUID: groupUUID) {
                    return foundGroup
                }
            }

            return nil
        }

        func get(entryUUID: String) -> Entry? {
            for entry in entries where entry.uuid == entryUUID {
                return entry
            }

            for group in groups {
                if let foundEntry = group.get(entryUUID: entryUUID) {
                    return foundEntry
                }
            }
            return nil
        }

        mutating func unprotect(streamCipher: KdbxStreamCipher) throws {
            for i in entries.indices {
                try entries[i].unprotect(streamCipher: streamCipher)
            }

            for i in groups.indices {
                try groups[i].unprotect(streamCipher: streamCipher)
            }
        }

        mutating func update(group: Group) {
            if let index = groups.index(where: { $0.uuid == group.uuid }) {
                print("update group replacing entry at \(index) on '\(groups[index].name)'")
                groups[index] = group
            } else {
                for index in groups.indices {
                    print("update group checking subgroup \(index) of '\(groups[index].name)'")
                    groups[index].update(group: group)
                }
            }
        }

        mutating func update(entry: Entry) {
            if let index = entries.index(where: { $0.uuid == entry.uuid }) {
                print("update entry replacing entry at \(index) on '\(name)'")
                entries[index] = entry
            } else {
                for index in groups.indices {
                    print("update entry checking subgroup \(index) of '\(name)'")
                    groups[index].update(entry: entry)
                }
            }
        }
    }

    struct KeePassFile {

        var meta: Meta
        var root: Root

        static func parse(elem: AEXMLElement) -> KeePassFile {
            let meta = Meta.parse(elem: elem["Meta"])
            let root = Root.parse(elem: elem["Root"])
            return KeePassFile(meta: meta, root: root)
        }

        func build() -> AEXMLElement {
            let elem = AEXMLElement(name: "KeePassFile")
            elem.addChild(meta.build())
            elem.addChild(root.build())
            return elem
        }

        mutating func unprotect(streamCipher: KdbxStreamCipher) throws {
            for i in root.group.entries.indices {
                try root.group.entries[i].unprotect(streamCipher: streamCipher)
            }

            for i in root.group.groups.indices {
                try root.group.groups[i].unprotect(streamCipher: streamCipher)
            }
        }
    }

    struct MemoryProtection {

        var isTitleProtected: Bool
        var isUsernameProtected: Bool
        var isPasswordProtected: Bool
        var isUrlProtected: Bool
        var isNotesProtected: Bool

        static func parse(elem: AEXMLElement) -> MemoryProtection {
            return MemoryProtection(
                isTitleProtected: elem["ProtectTitle"].string == "True",
                isUsernameProtected: elem["ProtectUserName"].string == "True",
                isPasswordProtected: elem["ProtectPassword"].string == "True",
                isUrlProtected: elem["ProtectURL"].string == "True",
                isNotesProtected: elem["ProtectNotes"].string == "True"
            )
        }

        func build() -> AEXMLElement {
            let elem = AEXMLElement(name: "MemoryProtection")
            elem.addChild(name: "ProtectTitle", value: isTitleProtected.xmlString, attributes: [:])
            elem.addChild(name: "ProtectUserName", value: isUsernameProtected.xmlString, attributes: [:])
            elem.addChild(name: "ProtectPassword", value: isPasswordProtected.xmlString, attributes: [:])
            elem.addChild(name: "ProtectURL", value: isUrlProtected.xmlString, attributes: [:])
            elem.addChild(name: "ProtectNotes", value: isNotesProtected.xmlString, attributes: [:])
            return elem
        }
    }

    struct Meta {

        var generator: String
        var headerHash: String
        var databaseName: String
        var databaseNameChanged: Date?
        var databaseDescription: String
        var databaseDescriptionChanged: Date?
        var defaultUsername: String
        var defaultUsernameChanged: Date?
        var maintenanceHistoryDays: Int?
        var color: String
        var masterKeyChanged: Date?
        var masterKeyChangeRec: Int
        var masterKeyChangeForce: Int
        var memoryProtection: MemoryProtection
        var recycleBinEnabled: Bool
        var recycleBinUUID: String
        var recycleBinChanged: Date?
        var entryTemplatesGroup: String
        var entryTemplatesGroupChanged: Date?
        var historyMaxItems: Int
        var historyMaxSize: Int
        var lastSelectedGroup: String
        var lastTopVisibleGroup: String
        var binaries: [Binary]
        var customData: String

        static func parse(elem: AEXMLElement) -> Meta {
            var binaries = [Binary]()
            if let children = elem["Binaries"]["Binary"].all {
                for elem in children {
                    let binary = Binary.parse(elem: elem)
                    binaries.append(binary)
                }
            }

            return Meta(
                generator: elem["Generator"].string,
                headerHash: elem["HeaderHash"].string,
                databaseName: elem["DatabaseName"].string,
                databaseNameChanged: elem["DatabaseNameChanged"].string.xmlDate,
                databaseDescription: elem["DatabaseDescription"].string,
                databaseDescriptionChanged: elem["DatabaseDescriptionChanged"].string.xmlDate,
                defaultUsername: elem["DefaultUserName"].string,
                defaultUsernameChanged: elem["DefaultUserNameChanged"].string.xmlDate,
                maintenanceHistoryDays: elem["MaintenenceHistoryDays"].int,
                color: elem["Color"].string,
                masterKeyChanged: elem["MasterKeyChanged"].string.xmlDate,
                masterKeyChangeRec: elem["MasterKeyChangeRec"].int ?? -1,
                masterKeyChangeForce: elem["MasterKeyChangeForce"].int ?? -1,
                memoryProtection: MemoryProtection.parse(elem: elem["MemoryProtection"]),
                recycleBinEnabled: elem["RecycleBinEnabled"].string == "True",
                recycleBinUUID: elem["RecycleBinUUID"].string,
                recycleBinChanged: elem["RecycleBinChanged"].string.xmlDate,
                entryTemplatesGroup: elem["EntryTemplatesGroup"].string,
                entryTemplatesGroupChanged: elem["EntryTemplatesGroupChanged"].string.xmlDate,
                historyMaxItems: elem["HistoryMaxItems"].int!,
                historyMaxSize: elem["HistoryMaxSize"].int!,
                lastSelectedGroup: elem["LastSelectedGroup"].string,
                lastTopVisibleGroup: elem["LastTopVisibleGroup"].string,
                binaries: binaries,
                customData: elem["CustomData"].string
            )
        }

        func build() -> AEXMLElement {
            let elem = AEXMLElement(name: "Meta")
            elem.addChild(name: "Generator", value: "KdbxSwift", attributes: [:])
            elem.addChild(name: "HeaderHash", value: headerHash, attributes: [:])
            elem.addChild(name: "DatabaseName", value: databaseName, attributes: [:])
            elem.addChild(name: "DatabaseNameChanged", value: databaseNameChanged?.xmlString, attributes: [:])
            elem.addChild(name: "DatabaseDescription", value: databaseDescription, attributes: [:])
            elem.addChild(name: "DatabaseDescriptionChanged", value: databaseDescriptionChanged?.xmlString, attributes: [:])
            elem.addChild(name: "DefaultUserName", value: defaultUsername, attributes: [:])
            elem.addChild(name: "DefaultUserNameChanged", value: defaultUsernameChanged?.xmlString, attributes: [:])
            elem.addChild(name: "MaintenanceHistoryDays", value: maintenanceHistoryDays?.xmlString, attributes: [:])
            elem.addChild(name: "Color", value: color, attributes: [:])
            elem.addChild(name: "MasterKeyChanged", value: masterKeyChanged?.xmlString, attributes: [:])
            elem.addChild(name: "MasterKeyChangeRec", value: masterKeyChangeRec.xmlString, attributes: [:])
            elem.addChild(name: "MasterKeyChangeForce", value: masterKeyChangeForce.xmlString, attributes: [:])
            elem.addChild(memoryProtection.build())
            elem.addChild(name: "RecycleBinEnabled", value: recycleBinEnabled.xmlString, attributes: [:])
            elem.addChild(name: "RecycleBinUUID", value: recycleBinUUID, attributes: [:])
            elem.addChild(name: "RecycleBinChanged", value: recycleBinChanged?.xmlString, attributes: [:])
            elem.addChild(name: "EntryTemplatesGroup", value: entryTemplatesGroup, attributes: [:])
            elem.addChild(name: "EntryTemplatesGroupChanged", value: entryTemplatesGroupChanged?.xmlString, attributes: [:])
            elem.addChild(name: "HistoryMaxItems", value: historyMaxItems.xmlString, attributes: [:])
            elem.addChild(name: "HistoryMaxSize", value: historyMaxSize.xmlString, attributes: [:])
            elem.addChild(name: "LastSelectedGroup", value: lastSelectedGroup, attributes: [:])
            elem.addChild(name: "LastTopVisibleGroup", value: lastTopVisibleGroup, attributes: [:])
            elem.addChild(name: "CustomData", value: customData, attributes: [:])

            let binariesElem = elem.addChild(name: "Binaries")
            for binary in binaries {
                binariesElem.addChild(binary.build())
            }

            return elem
        }
    }

    struct Root {

        var group: Group
        var deletedObjects: [DeletedObject]

        static func parse(elem: AEXMLElement) -> Root {
            let group = Group.parse(elem: elem["Group"].first!)

            var deletedObjects = [DeletedObject]()
            if let children = elem["DevaredObjects"]["DevaredObject"].all {
                for elem in children {
                    let deletedObject = DeletedObject.parse(elem: elem)
                    deletedObjects.append(deletedObject)
                }
            }

            return Root(group: group, deletedObjects: deletedObjects)
        }

        func build() -> AEXMLElement {
            let elem = AEXMLElement(name: "Root")

            elem.addChild(group.build())

            let deletedObjectsElem = elem.addChild(name: "DeletedObjects")
            for deletedObject in deletedObjects {
                deletedObjectsElem.addChild(deletedObject.build())
            }

            return elem
        }
    }

    struct Str {

        var key: String
        var value: String
        var isProtected: Bool

        static func parse(elem: AEXMLElement) -> Str {
            return Str(
                key: elem["Key"].string,
                value: elem["Value"].string,
                isProtected: elem["Value"].attributes["Protected"]?.xmlBool ?? false
            )
        }

        func build() -> AEXMLElement {
            let elem = AEXMLElement(name: "String")
            elem.addChild(name: "Key", value: key, attributes: [:])
            elem.addChild(name: "Value", value: value, attributes: ["Protected": isProtected.xmlString])
            return elem
        }
    }

    struct Times {

        var lastModificationTime: Date?
        var creationTime: Date?
        var lastAccessTime: Date?
        var expiryTime: Date?
        var expires: Bool
        var usageCount: Int
        var locationChanged: Date?

        static func parse(elem: AEXMLElement) -> Times {
            return Times(
                lastModificationTime: elem["LastModificationTime"].string.xmlDate,
                creationTime: elem["CreationTime"].string.xmlDate,
                lastAccessTime: elem["LastAccessTime"].string.xmlDate,
                expiryTime: elem["ExpiryTime"].string.xmlDate,
                expires: elem["Expires"].string == "True",
                usageCount: elem["UsageCount"].int ?? 0,
                locationChanged: elem["LocationChanged"].string.xmlDate
            )
        }

        func build() -> AEXMLElement {
            let elem = AEXMLElement(name: "Times")
            elem.addChild(name: "LastModificationTime", value: lastModificationTime?.xmlString, attributes: [:])
            elem.addChild(name: "CreationTime", value: creationTime?.xmlString, attributes: [:])
            elem.addChild(name: "LastAccessTime", value: lastAccessTime?.xmlString, attributes: [:])
            elem.addChild(name: "ExpiryTime", value: expiryTime?.xmlString, attributes: [:])
            elem.addChild(name: "Expires", value: expires.xmlString, attributes: [:])
            elem.addChild(name: "UsageCount", value: usageCount.xmlString, attributes: [:])
            elem.addChild(name: "LocationChanged", value: locationChanged?.xmlString, attributes: [:])
            return elem
        }
    }

    class XmlDateFormatter {

        var formatter = DateFormatter()

        static var sharedInstance = XmlDateFormatter()

        func to(date: Date) -> String {
            return formatter.string(from: date)
        }

        func from(string: String) -> Date? {
            return formatter.date(from: string)
        }

        init() {
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        }
    }

    static func parse(data: Data) throws -> KeePassFile {
        let xmlDoc = try AEXMLDocument(xml: data)
        return KeePassFile.parse(elem: xmlDoc.root)
    }
}
