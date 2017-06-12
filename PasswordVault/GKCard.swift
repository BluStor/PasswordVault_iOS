//
//  GKCard.swift
//  PasswordVault
//

import CoreBluetooth
import Hydra
import SwiftyBluetooth

class GKCard {

    static let serviceUUID = CBUUID(string: "423AD87A-B100-4F14-9EAA-5EB5839F2A54")
    static let controlPointUUID = CBUUID(string: "423AD87A-0001-4F14-9EAA-5EB5839F2A54")
    static let fileWriteUUID = CBUUID(string: "423AD87A-0002-4F14-9EAA-5EB5839F2A54")

    private let peripheral: Peripheral
    private var controlPointBuffer = Data()

    enum CardError: Error {
        case argumentInvalid
        case bluetoothNotPoweredOn
        case cardNotFound
        case cardNotPaired
        case characteristicReadFailure
        case characteristicWriteFailure
        case fileNotFound
        case invalidChecksum
        case makeCommandDataFailed
    }

    static func checkBluetoothState() -> Promise<Void> {
        return Promise { resolve, reject in
            SwiftyBluetooth.asyncState(completion: { state in
                switch state {
                case .poweredOn:
                    resolve()
                default:
                    reject(CardError.bluetoothNotPoweredOn)
                }
            })
        }
    }

    required init?(uuid: UUID) {
        let peripherals = SwiftyBluetooth.retrievePeripherals(withUUIDs: [uuid])

        guard let peripheral = peripherals.first else {
            return nil
        }

        print("card init")
        self.peripheral = peripheral

        NotificationCenter.default.addObserver(forName: Peripheral.PeripheralCharacteristicValueUpdate, object: self.peripheral, queue: nil) { notification in
            if let characteristic = notification.userInfo?["characteristic"] as? CBCharacteristic {
                if let value = characteristic.value {
                    self.controlPointBuffer.append(value)
                    print("controlPointBuffer -> +\(String(format: "%03d", value.count)) bytes = \(String(format: "%03d", self.controlPointBuffer.count)) bytes")
                }
            } else {
                print("update notification dropped")
            }
        }
    }

    private func makeCommandData(command: UInt8, string: String?) -> Promise<Data> {
        return Promise { resolve, reject in
            let dataWriteStream = DataWriteStream()

            do {
                try dataWriteStream.write(command)

                if let string = string {
                    try dataWriteStream.write(UInt8(truncatingBitPattern: string.characters.count))
                    for byte in [UInt8](string.utf8) {
                        try dataWriteStream.write(byte)
                    }
                    try dataWriteStream.write(0 as UInt8)
                }
            } catch {
                reject(CardError.makeCommandDataFailed)
            }

            resolve(dataWriteStream.data)
        }
    }

    private func fileWrite(data: Data) -> Promise<Void> {
        return Promise { resolve, reject in
            var offset = 0

            repeat {
                let chunkSize = (data.count - offset) > 128 ? 128 : data.count - offset
                let chunk = data.subdata(in: offset..<offset + chunkSize)

                print("fileWrite <- \(chunk.count) bytes")

                let semaphore = DispatchSemaphore(value: 0)

                self.peripheral.writeValue(ofCharacWithUUID: GKCard.fileWriteUUID, fromServiceWithUUID: GKCard.serviceUUID, value: chunk, type: .withoutResponse, completion: { result in
                    switch result {
                    case .failure(let error):
                        print(error)
                        reject(CardError.characteristicWriteFailure)
                        return
                    case .success:
                        semaphore.signal()
                    }
                })

                semaphore.wait()

                offset += chunkSize
            } while offset < data.count

            resolve()
        }
    }

    private func waitOnControlPointResult() -> Promise<Data> {
        return Promise { resolve, _ in
            var bufferCount = 0

            let timer = DispatchSource.makeTimerSource()
            timer.scheduleRepeating(deadline: .now() + 2.0, interval: 2.0)
            timer.setEventHandler {
                if bufferCount < self.controlPointBuffer.count {
                    bufferCount = self.controlPointBuffer.count
                } else {
                    timer.cancel()
                    print("controlPointBuffer: \(self.controlPointBuffer.count) bytes")
                    resolve(self.controlPointBuffer)
                    self.controlPointBuffer.removeAll()
                }
            }
            timer.resume()
        }
    }

    private func writeToControlPoint(data: Data) -> Promise<Void> {
        return Promise { resolve, reject in
            print("writeToControlPoint: \([UInt8](data).hexString)")
            self.peripheral.writeValue(
                ofCharacWithUUID: GKCard.controlPointUUID,
                fromServiceWithUUID: GKCard.serviceUUID,
                value: data,
                type: .withoutResponse,
                completion: { result in
                    switch result {
                    case .failure(let error):
                        reject(error)
                    case .success:
                        resolve()
                    }
                }
            )
        }
    }

    // MARK: Connection

    func connect(timeout: TimeInterval = 10.0) -> Promise<Void> {
        return Promise { resolve, reject in
            print("connect()")
            self.peripheral.connect(withTimeout: timeout, completion: { result in
                switch result {
                case .failure(let error):
                    reject(error)
                case .success:
                    self.peripheral.setNotifyValue(
                        toEnabled: true,
                        forCharacWithUUID: GKCard.controlPointUUID,
                        ofServiceWithUUID: GKCard.serviceUUID
                    ) { result in
                        switch result {
                        case .failure(let error):
                            let nsError = error as NSError
                            switch nsError.code {
                            case CBATTError.insufficientEncryption.rawValue:
                                reject(CardError.cardNotPaired)
                            default:
                                reject(error)
                            }
                        case .success:
                            print("connected")
                            resolve()
                        }
                    }
                }
            })
        }
    }

    func disconnect() -> Promise<Void> {
        return Promise { resolve, reject in
            print("disconnect()")
            self.peripheral.disconnect { result in
                switch result {
                case .failure(let error):
                    reject(error)
                case .success:
                    print("disconnected")
                    resolve()
                }
            }
        }
    }

    // MARK: Commands

    func checksum(data: Data) -> Promise<Void> {
        return Promise { resolve, reject in
            let ourChecksum = data.crc16()
            let ourChecksumBytes = [
                UInt8(truncatingBitPattern: ourChecksum >> 8),
                UInt8(truncatingBitPattern: ourChecksum)
            ]

            self.peripheral.readValue(ofCharacWithUUID: GKCard.fileWriteUUID, fromServiceWithUUID: GKCard.serviceUUID, completion: { result in
                if result.error == nil {
                    guard let value = result.value else {
                        reject(CardError.characteristicReadFailure)
                        return
                    }

                    let valueBytes = [UInt8](value)
                    print("card checksum: \(valueBytes.hexString)")
                    print("our checksum: \(ourChecksumBytes.hexString)")

                    if valueBytes == ourChecksumBytes {
                        resolve()
                    } else {
                        reject(CardError.invalidChecksum)
                    }
                } else {
                    reject(CardError.characteristicReadFailure)
                }
            })
        }
    }

    func close(path: String) -> Promise<Void> {
        return Promise { resolve, reject in
            GKCard.checkBluetoothState()
            .then {
                self.makeCommandData(command: 4, string: path)
            }
            .then(self.writeToControlPoint)
            .then(resolve)
            .catch(reject)
        }
    }

    func delete(path: String) -> Promise<Void> {
        return Promise { resolve, reject in
            guard path.characters.count <= 30 else {
                reject(CardError.argumentInvalid)
                return
            }

            GKCard.checkBluetoothState()
            .then {
                self.makeCommandData(command: 7, string: path)
            }
            .then(self.writeToControlPoint)
            .then(resolve)
            .catch(reject)
        }
    }

    func get(path: String) -> Promise<Data> {
        return Promise { resolve, reject in
            guard path.characters.count <= 30 else {
                reject(CardError.argumentInvalid)
                return
            }

            GKCard.checkBluetoothState()
            .then {
                self.makeCommandData(command: 2, string: path)
            }
            .then(self.writeToControlPoint)
            .then(self.waitOnControlPointResult)
            .then { data in
                if data.count == 0 {
                    reject(CardError.fileNotFound)
                } else {
                    resolve(data)
                }
            }
            .catch(reject)
        }
    }

    func rename(name: String) -> Promise<Void> {
        return Promise { resolve, reject in
            guard name.characters.count <= 11 else {
                reject(CardError.argumentInvalid)
                return
            }

            GKCard.checkBluetoothState()
            .then {
                self.makeCommandData(command: 8, string: name)
            }
            .then(self.writeToControlPoint)
            .then(resolve)
            .catch(reject)
        }
    }

    func put(data: Data) -> Promise<Void> {
        return Promise { resolve, reject in
            GKCard.checkBluetoothState()
            .then {
                self.makeCommandData(command: 3, string: nil)
            }
            .then(self.writeToControlPoint)
            .then {
                self.fileWrite(data: data)
            }
            .then(resolve)
            .catch(reject)
        }
    }
}
