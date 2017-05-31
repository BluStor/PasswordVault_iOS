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
        case salsa20 = 2
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
    var cipherType = Kdbx.CipherType.aes
    var compressionType = CompressionType.gzip
    var masterKeySeed = [UInt8]()
    var transformSeed = [UInt8]()
    var transformRounds: UInt64 = 8000
    var encryptionIv = [UInt8]()
    var protectedStreamKey = [UInt8]()
    var streamStartBytes = [UInt8]()
    var innerAlgorithm = InnerAlgorithm.none

    required init() {
        magicNumbers = Kdbx.magicNumbers
        version = Version(major: 3, minor: 1)
        masterKeySeed = [UInt8].random(size: 32)
        transformSeed = [UInt8].random(size: 32)
        encryptionIv = [UInt8].random(size: 16)
        protectedStreamKey = [UInt8].random(size: 32)
        streamStartBytes = [UInt8].random(size: 32)
    }

    required init(readStream: DataReadStream) throws {
        // Verify magic numbers and version

        magicNumbers = try readStream.readBytes(size: 8)

        guard magicNumbers == Kdbx.magicNumbers else {
            throw ReadError.unknownMagicNumbers
        }

        let minor = try readStream.read() as UInt16
        let major = try readStream.read() as UInt16

        version = Version(major: major, minor: minor)

        guard version.major == 3 else {
            throw ReadError.unknownVersion
        }

        // Dynamic header

        readLoop: repeat {
            let readTypeInt = try readStream.read() as UInt8

            if let readType = ReadType(rawValue: readTypeInt) {
                let size = Int(try readStream.read() as Int16)

                switch readType {
                case .comment:
                    _ = try readStream.readBytes(size: size)
                case .cipherUuid:
                    let b = try readStream.readBytes(size: size)

                    let cipherUuid = UUID(uuid: (b[0], b[1], b[2], b[3], b[4], b[5], b[6], b[7], b[8], b[9], b[10], b[11], b[12], b[13], b[14], b[15]))

                    if cipherUuid == KdbxCrypto.aesUUID {
                        cipherType = .aes
                    } else {
                        throw ReadError.unknownCipherUuid
                    }
                case .compressionType:
                    let rawValue = try readStream.read() as UInt32

                    if let ct = CompressionType(rawValue: rawValue) {
                        compressionType = ct
                    } else {
                        throw ReadError.unknownCompressionType
                    }
                case .masterKeySeed:
                    masterKeySeed = try readStream.readBytes(size: size)
                case .transformSeed:
                    transformSeed = try readStream.readBytes(size: size)
                case .transformRounds:
                    transformRounds = try readStream.read() as UInt64
                case .encryptionIv:
                    encryptionIv = try readStream.readBytes(size: size)
                case .protectedStreamKey:
                    protectedStreamKey = try readStream.readBytes(size: size)
                case .streamStartBytes:
                    streamStartBytes = try readStream.readBytes(size: size)
                case .innerAlgorithm:
                    let rawValue = try readStream.read() as UInt32

                    if let algorithm = InnerAlgorithm(rawValue: rawValue) {
                        innerAlgorithm = algorithm
                    } else {
                        throw ReadError.unknownInnerAlgorithm
                    }
                case .end:
                    _ = try readStream.readBytes(size: size)
                    break readLoop
                }
            } else {
                throw ReadError.unknownReadType
            }
        } while (true)
    }
}
