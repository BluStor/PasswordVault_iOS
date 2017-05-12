//
//  GKBluetoothCard.swift
//  PasswordVault
//

import CoreBluetooth
import Foundation
import SwiftyBluetooth

class GKBluetoothCard {

    enum CardError: Error {
        case pathInvalid
        case scanFailed
        case unableToConnect
        case unableToRead
        case unableToWrite
    }

    static let serviceUUID = CBUUID(string: "423AD87A-B100-4F14-9EAA-5EB5839F2A54")
    static let controlPointUUID = CBUUID(string: "423AD87A-0001-4F14-9EAA-5EB5839F2A54")
    static let fileWriteUUID = CBUUID(string: "423AD87A-0002-4F14-9EAA-5EB5839F2A54")

    private let peripheral: Peripheral
    private let controlPointCharacteristic: CBCharacteristic? = nil
    private let fileWriteCharacteristic: CBCharacteristic? = nil

    required init(peripheral: Peripheral) {
        self.peripheral = peripheral

        let characteristicValueUpdate = Notification.Name(rawValue: PeripheralEvent.characteristicValueUpdate.rawValue)

        NotificationCenter.default.addObserver(forName: characteristicValueUpdate, object: self.peripheral, queue: nil) { (notification) in
            print("new notification")
            if let userInfo = notification.userInfo {
                let updatedCharacteristic = userInfo["characteristic"] as! CBCharacteristic
                if let newValue = updatedCharacteristic.value {
                    print("Characteristic value update: \(newValue)")
                }
            }
        }
    }

    static func listPeripherals(timeout: Double, singleResult: Bool, completion: @escaping ([Peripheral], CardError?) -> Void ) {
        let services = [GKBluetoothCard.serviceUUID]

        var peripherals = [Peripheral]()
        SwiftyBluetooth.scanForPeripherals(withServiceUUIDs: services, timeoutAfter: timeout) { scanResult in
            switch scanResult {
            case .scanStarted:
                print("scan started")
            case .scanResult(let peripheral, _, _):
                peripherals.append(peripheral)

                if singleResult {
                    SwiftyBluetooth.stopScan()
                }
            case .scanStopped(let error):
                print("scan stopped")
                if error == nil {
                    completion(peripherals, nil)
                } else {
                    completion(peripherals, CardError.scanFailed)
                }
            }
        }
    }

    private func isPathValid(_ path: String) -> Bool {
        return path.characters.count <= 30
    }

    private func writeControlPoint(command: UInt8, string: String, completion: @escaping (CardError?) -> Void) {
        let dataWriteStream = DataWriteStream()

        do {
            try dataWriteStream.write(command)
            try dataWriteStream.write(UInt8(truncatingBitPattern: string.characters.count))
            try dataWriteStream.writeBytes(value: string)
        } catch {
            completion(CardError.unableToWrite)
            return
        }

        guard let data = dataWriteStream.data else {
            completion(CardError.unableToWrite)
            return
        }

        peripheral.writeValue(ofCharacWithUUID: GKBluetoothCard.controlPointUUID, fromServiceWithUUID: GKBluetoothCard.serviceUUID, value: data, completion: { (error) in
            if error == nil {
                completion(nil)
            } else {
                completion(CardError.unableToWrite)
            }
        })
    }

    func connect(completion: @escaping (CardError?) -> Void) {
        peripheral.connect { (error) in
            if error == nil {
                completion(nil)
            } else {
                completion(CardError.unableToConnect)
            }
        }
    }

    func disconnect() {
        peripheral.disconnect { (error) in
            if let error = error {
                print(error)
            }
        }
    }

    func delete(path: String, completion: @escaping (GKResponse?, CardError?) -> Void) {
        guard isPathValid(path) else {
            completion(nil, CardError.pathInvalid)
            return
        }

        connect { (error) in
            if error == nil {

            } else {
                completion(nil, error)
            }
        }
    }

    func deletePath(path: String, completion: @escaping (GKResponse?, CardError?) -> Void) {
        guard isPathValid(path) else {
            completion(nil, CardError.pathInvalid)
            return
        }

        connect { (error) in
            if error == nil {

            } else {
                completion(nil, error)
            }
        }
    }

    func finalize(path: String, completion: @escaping (GKResponse?, CardError?) -> Void) {
        guard isPathValid(path) else {
            completion(nil, CardError.pathInvalid)
            return
        }

        connect { (error) in
            if error == nil {

            } else {
                completion(nil, error)
            }
        }
    }

    func get(path: String, completion: @escaping (GKResponse?, CardError?) -> Void) {
        print("get called")
        guard isPathValid(path) else {
            completion(nil, CardError.pathInvalid)
            return
        }

        connect { (error) in
            if error == nil {
                self.writeControlPoint(command: 2, string: path, completion: { (error) in
                    if error == nil {

                        completion(nil, error)
                    } else {
                        self.disconnect()
                        completion(nil, error)
                    }
                })
            } else {
                self.disconnect()
                completion(nil, error)
            }
        }
    }

    func list(path: String, completion: @escaping (GKResponse?, CardError?) -> Void) {
        guard isPathValid(path) else {
            completion(nil, CardError.pathInvalid)
            return
        }

        connect { (error) in
            if error == nil {

            } else {
                completion(nil, error)
            }
        }
    }

    func put(path: String, data: Data, completion: @escaping (GKResponse?, CardError?) -> Void) {
        guard isPathValid(path) else {
            completion(nil, CardError.pathInvalid)
            return
        }

        connect { (error) in
            if error == nil {

            } else {
                completion(nil, error)
            }
        }
    }

    func rename(fromPath: String, toPath: String, completion: @escaping (GKResponse?, CardError?) -> Void) {
        guard isPathValid(fromPath) && isPathValid(toPath) else {
            completion(nil, CardError.pathInvalid)
            return
        }

        connect { (error) in
            if error == nil {

            } else {
                completion(nil, error)
            }
        }
    }
}
