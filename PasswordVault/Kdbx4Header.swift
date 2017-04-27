//
//  Kdbx4Header.swift
//  PasswordVault
//

class Kdbx4Header {

    enum ReadError: Error {
        case unknownMagicNumbers
        case unknownVersion
    }

    struct Version {
        let major: UInt16
        let minor: UInt16
    }

    var magicNumbers: [UInt8]
    var version: Version

    required init(dataReadStream: DataReadStream) throws {
        magicNumbers = try dataReadStream.readBytes(size: 8)

        if magicNumbers != Kdbx.magicNumbers {
            throw ReadError.unknownMagicNumbers
        }

        let minor = try dataReadStream.read() as UInt16
        let major = try dataReadStream.read() as UInt16

        version = Version(major: major, minor: minor)

        if version.major != 4 {
            throw ReadError.unknownVersion
        }

        throw ReadError.unknownVersion
    }
}
