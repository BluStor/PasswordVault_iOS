//
//  Kdbx3Header.swift
//  PasswordVault
//

import Foundation

class Kdbx3Header {

    enum CompressionType: UInt32 {
        case none = 0
        case gzip = 1
    }

    enum InnerAlgorithm: UInt32 {
        case none = 0
        case arcFour = 1
        case salsa20 = 2
    }

    enum CipherType {
        case aes
    }

    enum ReadType: UInt8 {
        case end = 0
        case comment = 1
        case cipherUuid = 2
        case compressionType = 3
        case masterKeySeed = 4
        case transformSeed = 5
        case transformRounds = 6
        case encryptionIv = 7
        case protectedStreamKey = 8
        case streamStartBytes = 9
        case innerAlgorithm = 10
    }

    enum ReadError: Error {
        case unknownMagicNumbers
        case unknownVersion
        case unknownReadType
        case unknownCipherUuid
        case unknownCompressionType
        case unknownInnerAlgorithm
    }

    struct Version {
        let major: UInt16
        let minor: UInt16
    }

    var magicNumbers: [UInt8]
    var version: Version
    var cipherType = CipherType.aes
    var compressionType = CompressionType.none
    var masterKeySeed = [UInt8]()
    var transformSeed = [UInt8]()
    var transformRounds: UInt64 = 6000
    var encryptionIv = [UInt8]()
    var protectedStreamKey = [UInt8]()
    var streamStartBytes = [UInt8]()
    var innerAlgorithm = InnerAlgorithm.none

    required init(dataReadStream: DataReadStream) throws {
        magicNumbers = try dataReadStream.readBytes(size: 8)

        if magicNumbers != Kdbx.magicNumbers {
            throw ReadError.unknownMagicNumbers
        }

        let minor = try dataReadStream.read() as UInt16
        let major = try dataReadStream.read() as UInt16

        version = Version(major: major, minor: minor)

        if version.major != 3 {
            throw ReadError.unknownVersion
        }

        var readType: ReadType? = ReadType.end
        readLoop: repeat {
            let readTypeValue = try dataReadStream.read() as UInt8
            readType = ReadType(rawValue: readTypeValue)

            let size = Int(try dataReadStream.read() as Int16)

            if let readType = readType {
                switch readType {
                case .comment:
                    _ = try dataReadStream.readBytes(size: size)
                case .cipherUuid:
                    let b = try dataReadStream.readBytes(size: size)

                    let cipherUuid = UUID(uuid: (b[0], b[1], b[2], b[3], b[4], b[5], b[6], b[7], b[8], b[9], b[10], b[11], b[12], b[13], b[14], b[15]))

                    if cipherUuid == KdbxCrypto.aesUuid {
                        cipherType = .aes
                    } else {
                        throw ReadError.unknownCipherUuid
                    }
                case .compressionType:
                    let rawValue = try dataReadStream.read() as UInt32

                    if let c = CompressionType(rawValue: rawValue) {
                        compressionType = c
                    } else {
                        throw ReadError.unknownCompressionType
                    }
                case .masterKeySeed:
                    masterKeySeed = try dataReadStream.readBytes(size: size)
                case .transformSeed:
                    transformSeed = try dataReadStream.readBytes(size: size)
                case .transformRounds:
                    transformRounds = try dataReadStream.read() as UInt64
                case .encryptionIv:
                    encryptionIv = try dataReadStream.readBytes(size: size)
                case .protectedStreamKey:
                    protectedStreamKey = try dataReadStream.readBytes(size: size)
                case .streamStartBytes:
                    streamStartBytes = try dataReadStream.readBytes(size: size)
                case .innerAlgorithm:
                    let rawValue = try dataReadStream.read() as UInt32

                    if let algorithm = InnerAlgorithm(rawValue: rawValue) {
                        innerAlgorithm = algorithm
                    } else {
                        throw ReadError.unknownInnerAlgorithm
                    }
                case .end:
                    _ = try dataReadStream.readBytes(size: size)
                    break readLoop
                }
            } else {
                throw ReadError.unknownReadType
            }
        } while (readType != .end)
    }
}
