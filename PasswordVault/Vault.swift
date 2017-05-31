//
//  Vault.swift
//  PasswordVault
//

import Signals

class Vault {
    enum Status {
        case synced
        case syncInProgress
        case syncFailed
    }

    static let dbPath = "/passwordvault/db.kdbx"
    static var kdbx: Kdbx?
    static var cardUUID: UUID? {
        get {
            guard let uuidString = UserDefaults.standard.string(forKey: "Vault.cardUUID") else {
                print("Vault.cardUUID not found")
                return nil
            }

            guard let uuid = UUID(uuidString: uuidString) else {
                print("Vault.cardUUID could not be converted to a UUID")
                return nil
            }

            return uuid
        }
        set {
            if let uuidString = newValue?.uuidString {
                UserDefaults.standard.set(uuidString, forKey: "Vault.cardUUID")
            } else {
                UserDefaults.standard.removeObject(forKey: "Vault.cardUUID")
            }
        }
    }
    static let onStatus = Signal<Vault.Status>(retainLastData: true)

    static func close() {
        kdbx = nil
    }

    static func create(password: String) {
        kdbx = Kdbx(password: password)
        Vault.onStatus.fire(Vault.Status.synced)
    }

    static func open(encryptedData: Data, password: String) throws -> Kdbx {
        kdbx = try Kdbx(encryptedData: encryptedData, password: password)
        Vault.onStatus.fire(Vault.Status.synced)
        return kdbx!
    }

    static func open(encryptedData: Data, compositeKey: [UInt8]) throws -> Kdbx {
        kdbx = try Kdbx(encryptedData: encryptedData, compositeKey: compositeKey)
        Vault.onStatus.fire(Vault.Status.synced)
        return kdbx!
    }

    static func save() {
        DispatchQueue.global(qos: .background).async {
            guard let kdbx = kdbx else {
                print("database not found")
                return
            }

            guard let cardUUID = cardUUID else {
                print("card UUID not found")
                return
            }

            let encryptedData: Data
            do {
                encryptedData = try kdbx.encrypt()
            } catch {
                print(error)
                return
            }

            GKCard.checkBluetoothState()
            .then {
                guard let card = GKCard(uuid: cardUUID) else {
                    return
                }

                onStatus.fire(Vault.Status.syncInProgress)

                card.connect()
                .then {
                    card.put(path: Vault.dbPath, data: encryptedData)
                }
                .then {
                    card.close(path: Vault.dbPath)
                }
                .always {
                    card.disconnect().then {}
                    onStatus.fire(Vault.Status.synced)
                }
                .catch { error in
                    onStatus.fire(Vault.Status.syncFailed)
                }
            }
            .catch { error in
                print(error)
                onStatus.fire(Vault.Status.syncFailed)
            }
        }
    }
}
