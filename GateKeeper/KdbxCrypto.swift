//
//  KdbxCrypto.swift
//  GateKeeper
//

import Foundation

class KdbxCrypto {

    public static let aesUUID = UUID(uuidString: "31C1F2E6-BF71-4350-BE58-05216AFC5AFF")!

    enum Operation: UInt32 {
        case decrypt
        case encrypt

        var cc: UInt32 {
            switch self {
            case .decrypt:
                return UInt32(kCCDecrypt)
            case .encrypt:
                return UInt32(kCCEncrypt)
            }
        }
    }

    enum CryptoError: Error {
        case dataError
    }

    static func aes(operation: Operation, bytes: [UInt8], key: [UInt8], iv: [UInt8]) throws -> [UInt8] {
        var buffer = [UInt8](repeating: 0x0, count: bytes.count + kCCBlockSizeAES128)

        print("aes: \(operation) \(bytes.count) bytes")

        var cryptoCount = 0
        let status = CCCrypt(
            operation.cc,
            UInt32(kCCAlgorithmAES128),
            UInt32(kCCOptionPKCS7Padding),
            key,
            kCCKeySizeAES256,
            iv,
            bytes,
            bytes.count,
            &buffer,
            buffer.count,
            &cryptoCount
        )

        guard status == Int32(kCCSuccess) else {
            switch operation {
            case .decrypt:
                throw KdbxError.decryptionFailed
            case .encrypt:
                throw KdbxError.encryptionFailed
            }
        }

        let output = Array(buffer.prefix(cryptoCount))
        print("aes: \(operation) output \(output.count) bytes")

        return output
    }

    static func aesTransform(bytes: [UInt8], key: [UInt8], rounds: Int) throws -> [UInt8] {
        let cryptor = UnsafeMutablePointer<CCCryptorRef?>.allocate(capacity: 1)

        CCCryptorCreate(
            UInt32(kCCEncrypt),
            UInt32(kCCAlgorithmAES128),
            UInt32(kCCOptionECBMode),
            bytes,
            kCCKeySizeAES256,
            nil,
            cryptor
        )

        var transformedKey = key

        print("aesTransform: \(rounds) rounds")

        for _ in 0..<rounds {
            let status = CCCryptorUpdate(cryptor.pointee, transformedKey, transformedKey.count, &transformedKey, transformedKey.count, nil)

            guard status == Int32(kCCSuccess) else {
                throw CryptoError.dataError
            }
        }

        print("aesTransform: complete")

        return transformedKey
    }
}
