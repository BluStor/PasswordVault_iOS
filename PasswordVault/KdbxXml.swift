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
        var dataTransferObfuscation: Int
        var association: Association?

        static func parse(elem: AEXMLElement) -> AutoType {
            let association = Association.parse(elem: elem["Association"])

            return AutoType(
                    enabled: elem["Enabled"].string == "True",
                    dataTransferObfuscation: elem["DataTransferObfuscation"].int!,
                    association: association
            )
        }

        func build() -> AEXMLElement {
            let elem = AEXMLElement(name: "AutoType")
            elem.addChild(name: "Enabled", value: enabled.xmlString, attributes: [:])
            elem.addChild(name: "DataTransferObfuscation", value: dataTransferObfuscation.xmlString, attributes: [:])

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
        var title: String
        var isTitleProtected: Bool
        var username: String
        var isUsernameProtected: Bool
        var password: String
        var isPasswordProtected: Bool
        var url: String
        var isUrlProtected: Bool
        var notes: String
        var isNotesProtected: Bool
        var autoType: AutoType
        var history: [Entry]

        static func parse(elem: AEXMLElement) -> Entry {
            let times = Times.parse(elem: elem["Times"])
            let autoType = AutoType.parse(elem: elem["AutoType"])

            var history = [Entry]()
            if let children = elem["History"]["Entry"].all {
                for elem in children {
                    let entry = Entry.parse(elem: elem)
                    history.append(entry)
                }
            }

            var title = ""
            var isTitleProtected = false
            var username = ""
            var isUsernameProtected = false
            var password = ""
            var isPasswordProtected = false
            var url = ""
            var isUrlProtected = false
            var notes = ""
            var isNotesProtected = false

            if let children = elem["String"].all {
                for elem in children {
                    let str = Str.parse(elem: elem)
                    switch str.key {
                    case "Title":
                        title = str.value
                        isTitleProtected = str.isProtected
                    case "UserName":
                        username = str.value
                        isUsernameProtected = str.isProtected
                    case "Password":
                        password = str.value
                        isPasswordProtected = str.isProtected
                    case "URL":
                        url = str.value
                        isUrlProtected = str.isProtected
                    case "Notes":
                        notes = str.value
                        isNotesProtected = str.isProtected
                    default:
                        break
                    }
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
                    title: title,
                    isTitleProtected: isTitleProtected,
                    username: username,
                    isUsernameProtected: isUsernameProtected,
                    password: password,
                    isPasswordProtected: isPasswordProtected,
                    url: url,
                    isUrlProtected: isUrlProtected,
                    notes: notes,
                    isNotesProtected: isNotesProtected,
                    autoType: autoType,
                    history: history
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
            elem.addChild(Str(key: "Title", value: title, isProtected: isTitleProtected).build())
            elem.addChild(Str(key: "UserName", value: username, isProtected: isUsernameProtected).build())
            elem.addChild(Str(key: "Password", value: password, isProtected: isPasswordProtected).build())
            elem.addChild(Str(key: "URL", value: url, isProtected: isUrlProtected).build())
            elem.addChild(Str(key: "Notes", value: notes, isProtected: isNotesProtected).build())
            elem.addChild(autoType.build())

            let historyElem = elem.addChild(name: "History")
            for entry in history {
                historyElem.addChild(entry.build())
            }

            return elem
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

        mutating func delete(entryUUID: String) -> Bool {
            if let index = entries.index(where: { $0.uuid == entryUUID}) {
                entries.remove(at: index)
                return true
            }

            for (index, _) in groups.enumerated() {
                if groups[index].delete(entryUUID: entryUUID) {
                    return true
                }
            }

            return false
        }

        mutating func delete(groupUUID: String) -> Bool {
            if let index = groups.index(where: { $0.uuid == groupUUID}) {
                groups.remove(at: index)
                return true
            }

            for (index, _) in groups.enumerated() {
                if groups[index].delete(groupUUID: groupUUID) {
                    return true
                }
            }

            return false
        }

        func findEntries(title: String) -> [Entry] {
            var foundEntries = [Entry]()
            foundEntries.append(contentsOf: entries.filter({ $0.title.lowercased() == title.lowercased() }))
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
            for entry in entries {
                if entry.uuid == entryUUID {
                    return entry
                }
            }
            
            for group in groups {
                if let foundEntry = group.get(entryUUID: entryUUID) {
                    return foundEntry
                }
            }
            return nil
        }

        mutating func update(entry: Entry) -> Bool {
            if let index = entries.index(where: { $0.uuid == entry.uuid }) {
                entries[index] = entry
                return true
            }

            for (index, _) in groups.enumerated() {
                if groups[index].update(entry: entry) {
                    return true
                }
            }

            return false
        }

        mutating func update(group: Group) -> Bool {
            if let index = groups.index(where: { $0.uuid == group.uuid }) {
                if groups[index].uuid == group.uuid {
                    groups[index] = group
                    return true
                }
            }

            for (index, _) in groups.enumerated() {
                if groups[index].update(group: group) {
                    return true
                }
            }

            return false
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
    }

    struct MemoryProtection {

        var title: Bool
        var username: Bool
        var password: Bool
        var url: Bool
        var notes: Bool

        static func parse(elem: AEXMLElement) -> MemoryProtection {
            return MemoryProtection(
                    title: elem["ProtectTitle"].string == "True",
                    username: elem["ProtectUserName"].string == "True",
                    password: elem["ProtectPassword"].string == "True",
                    url: elem["ProtectURL"].string == "True",
                    notes: elem["ProtectNotes"].string == "True"
            )
        }

        func build() -> AEXMLElement {
            let elem = AEXMLElement(name: "MemoryProtection")
            elem.addChild(name: "ProtectTitle", value: title.xmlString, attributes: [:])
            elem.addChild(name: "ProtectUserName", value: username.xmlString, attributes: [:])
            elem.addChild(name: "ProtectPassword", value: password.xmlString, attributes: [:])
            elem.addChild(name: "ProtectURL", value: url.xmlString, attributes: [:])
            elem.addChild(name: "ProtectNotes", value: notes.xmlString, attributes: [:])
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
                    masterKeyChangeRec: elem["MasterKeyChangeRec"].int!,
                    masterKeyChangeForce: elem["MasterKeyChangeForce"].int!,
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
                    isProtected: elem["IsProtected"].string.xmlBool
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
                    usageCount: elem["UsageCount"].int!,
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

    static func parse(data: Data, innerAlgorithm: Kdbx.InnerAlgorithm) throws -> KeePassFile {
        let xmlDoc = try AEXMLDocument(xml: data)
        // TODO: Unprotect
        return KeePassFile.parse(elem: xmlDoc.root)
    }

    static func xml(keePassFile: KeePassFile, innerAlgorithm: Kdbx.InnerAlgorithm) -> String {
        let xmlDoc = AEXMLDocument(root: keePassFile.build(), options: AEXMLOptions())
        // TODO: Protect
        return xmlDoc.xml
    }
}
