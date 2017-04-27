//
//  KdbxCrypto.swift
//  PasswordVault
//

import Foundation

class KdbxCrypto {

    static let aesUuid = UUID(uuidString: "31C1F2E6-BF71-4350-BE58-05216AFC5AFF")!

    enum CryptoError: Error {

        case dataError
    }

    static func aesDecrypt(key: [UInt8], iv: [UInt8], bytes: [UInt8]) throws -> [UInt8] {
        var result = [UInt8](repeating: 0x0, count: bytes.count)
        let status = CCCrypt(UInt32(kCCDecrypt), UInt32(kCCAlgorithmAES), UInt32(kCCOptionPKCS7Padding), key, key.count, iv, bytes, bytes.count, &result, result.count, nil)

        guard status == Int32(kCCSuccess) else {
            throw KdbxError.decryptionError
        }

        return result
    }

    static func aesEncrypt(key: [UInt8], iv: [UInt8], bytes: [UInt8]) throws -> [UInt8] {
        var result = [UInt8](repeating: 0x0, count: bytes.count + kCCBlockSizeAES128)
        let status = CCCrypt(UInt32(kCCEncrypt), UInt32(kCCAlgorithmAES), UInt32(kCCOptionPKCS7Padding), key, key.count, iv, bytes, bytes.count, &result, result.count, nil)

        guard status == Int32(kCCSuccess) else {
            throw KdbxError.encryptionError
        }

        return result
    }

    static func aesTransform(seed: [UInt8], key: [UInt8], rounds: Int) throws -> [UInt8] {
        let iv = [UInt8](repeating: 0x0, count: 16)

        let cryptor = UnsafeMutablePointer<CCCryptorRef?>.allocate(capacity: 1)

        CCCryptorCreate(
                UInt32(kCCEncrypt),
                UInt32(kCCAlgorithmAES),
                UInt32(kCCOptionECBMode),
                seed,
                seed.count,
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
