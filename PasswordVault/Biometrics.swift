//
//  Biometrics.swift
//  PasswordVault
//

import LocalAuthentication
import Security

class Biometrics {
    
    private static let serviceName = "PasswordVault"
    private static let accountName = "default"
    
    enum BiometricsError: Error {
        case DataConversionError
        case PasswordNotFound
        case SecAccessControlCreateWithFlagsError
        case SecItemAddError
        case SecItemCopyMatchingError
        case SecItemDeleteError
    }
    
    static func isAvailable() -> Bool {
        let context = LAContext()

        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }

    static func hasPassword() -> Bool {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: Biometrics.serviceName,
            kSecAttrAccount: Biometrics.accountName,
            kSecUseAuthenticationUI: kSecUseAuthenticationUIFail,
            kSecReturnData: false
            ] as CFDictionary
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query, &result)
        print(status)
        switch status {
        case errSecItemNotFound:
            return false
        default:
            return true
        }
    }
    
    static func deletePassword() throws {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: Biometrics.serviceName,
            kSecAttrAccount: Biometrics.accountName
            ] as CFDictionary
        
        let status = SecItemDelete(query)
        print(status)
        switch status {
        case noErr:
            break
        case errSecItemNotFound:
            throw BiometricsError.PasswordNotFound
        default:
            throw BiometricsError.SecItemDeleteError
        }
    }
    
    static func getPassword() throws -> String {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: Biometrics.serviceName,
            kSecAttrAccount: Biometrics.accountName,
            kSecReturnData: true
            ] as CFDictionary
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query, &result)
        print(status)
        switch status {
        case noErr:
            guard let data = result as? Data else {
                throw BiometricsError.DataConversionError
            }
            
            guard let password = String(data: data, encoding: .utf8) else {
                throw BiometricsError.DataConversionError
            }
            
            return password
        case errSecItemNotFound:
            throw BiometricsError.PasswordNotFound
        default:
            throw BiometricsError.SecItemCopyMatchingError
        }
    }
    
    static func setPassword(password: String) throws {
        guard let data = password.data(using: .utf8, allowLossyConversion: false) else {
            throw BiometricsError.DataConversionError
        }
        
        try? deletePassword()
        
        guard let accessControl = SecAccessControlCreateWithFlags(kCFAllocatorDefault, kSecAttrAccessibleWhenUnlockedThisDeviceOnly, .touchIDAny, nil) else {
            throw BiometricsError.SecAccessControlCreateWithFlagsError
        }
        
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccessControl: accessControl,
            kSecAttrService: Biometrics.serviceName,
            kSecAttrAccount: Biometrics.accountName,
            kSecValueData: data
            ] as CFDictionary
        
        let status = SecItemAdd(query, nil)
        print(status)
        switch status {
        case noErr:
            break
        default:
            throw BiometricsError.SecItemAddError
        }
    }
}
