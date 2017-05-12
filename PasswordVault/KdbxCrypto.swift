//
//  KdbxCrypto.swift
//  PasswordVault
//

import Foundation

protocol KdbxStreamCipher {
    func unprotect(string: String) throws -> String
    func protect(string: String) throws -> String
}

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
        case initializationError
    }

    static func aes(operation: Operation, bytes: [UInt8], key: [UInt8], iv: [UInt8]) throws -> [UInt8] {
        var result = [UInt8](repeating: 0x0, count: bytes.count)

        let status = CCCrypt(
            operation.cc,
            UInt32(kCCAlgorithmAES),
            UInt32(kCCOptionPKCS7Padding),
            key,
            key.count,
            iv,
            bytes,
            bytes.count,
            &result,
            result.count,
            nil
        )

        guard status == Int32(kCCSuccess) else {
            throw KdbxError.decryptionError
        }

        return result
    }

    static func aesTransform(bytes: [UInt8], key: [UInt8], rounds: Int) throws -> [UInt8] {
        let iv = [UInt8](repeating: 0x0, count: 16)

        let cryptor = UnsafeMutablePointer<CCCryptorRef?>.allocate(capacity: 1)

        CCCryptorCreate(
                UInt32(kCCEncrypt),
                UInt32(kCCAlgorithmAES),
                UInt32(kCCOptionECBMode),
                bytes,
                bytes.count,
                iv,
                cryptor
        )

        var transformedKey = key

        for _ in 0..<rounds {
            let status = CCCryptorUpdate(cryptor.pointee, transformedKey, transformedKey.count, &transformedKey, transformedKey.count, nil)

            guard status == Int32(kCCSuccess) else {
                throw CryptoError.dataError
            }
        }

        return transformedKey
    }
}
