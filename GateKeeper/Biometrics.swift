//
//  Biometrics.swift
//  GateKeeper
//

import LocalAuthentication
import RRBPalmSDK
import Security

class Biometrics {
    
    private static let serviceName = "GateKeeper"
    private static let accountNameFingerprint = "fingerprint"
    private static let accountNamePalm = "palm"
    
    enum PalmError: Error {
        case AuthError
        case DataConversionError
        case PalmFailure
        case PasswordNotFound
        case StringDecodeError
    }
    
    enum FingerprintError: Error {
        case DataConversionError
        case PasswordNotFound
        case StringDecodeError
    }
    
    enum SecError: Error {
        case AccessControlCreateWithFlagsError
        case ItemAddError
        case ItemCopyMatchingError
    }
    
    // MARK: Fingerprint
    
    static func deleteFingerprint() -> Bool {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: Biometrics.serviceName,
            kSecAttrAccount: Biometrics.accountNameFingerprint,
            kSecReturnData: true
            ] as CFDictionary
        
        let status = SecItemDelete(query)
        
        switch status {
        case noErr:
            RRBPalmSDKUser.default().unregister()
            return true
        default:
            return false
        }
    }
    
    static func getFingerprint() throws -> String {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: Biometrics.serviceName,
            kSecAttrAccount: Biometrics.accountNameFingerprint,
            kSecReturnData: true
            ] as CFDictionary
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query, &result)

        switch status {
        case noErr:
            guard let data = result as? Data else {
                throw FingerprintError.DataConversionError
            }
            
            guard let password = String(data: data, encoding: .utf8) else {
                throw FingerprintError.StringDecodeError
            }
            
            return password
        case errSecItemNotFound:
            throw FingerprintError.PasswordNotFound
        default:
            print("error: \(status)")
            throw SecError.ItemCopyMatchingError
        }
    }
    
    static func hasFingerprint() -> Bool {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: Biometrics.serviceName,
            kSecAttrAccount: Biometrics.accountNameFingerprint,
            kSecUseAuthenticationUI: kSecUseAuthenticationUIFail,
            kSecReturnData: false
            ] as CFDictionary
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query, &result)
        
        switch status {
        case errSecItemNotFound:
            return false
        default:
            return true
        }
    }
    
    static func isFingerprintAvailable() -> Bool {
        let context = LAContext()
        
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }
    
    static func setFingerprint(password: String) throws {
        guard let data = password.data(using: .utf8, allowLossyConversion: false) else {
            throw FingerprintError.DataConversionError
        }
        
        _ = deleteFingerprint()
        
        guard let accessControl = SecAccessControlCreateWithFlags(kCFAllocatorDefault, kSecAttrAccessibleWhenUnlockedThisDeviceOnly, .touchIDAny, nil) else {
            throw SecError.AccessControlCreateWithFlagsError
        }
        
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccessControl: accessControl,
            kSecAttrService: Biometrics.serviceName,
            kSecAttrAccount: Biometrics.accountNameFingerprint,
            kSecValueData: data
            ] as CFDictionary
        
        let status = SecItemAdd(query, nil)
        
        switch status {
        case noErr:
            break
        default:
            throw SecError.ItemAddError
        }
    }
    
    // MARK: Palm
    
    static func deletePalm() -> Bool {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: Biometrics.serviceName,
            kSecAttrAccount: Biometrics.accountNamePalm,
            kSecReturnData: true
            ] as CFDictionary
        
        let status = SecItemDelete(query)
        
        switch status {
        case noErr:
            RRBPalmSDKUser.default().unregister()
            return true
        default:
            return false
        }
    }
    
    static func getPalm(viewController: UIViewController, completion: @escaping (String, Error?) -> Void) {
        
        let palmAuthViewController = RRBPalmSDKAuthViewController()
        
        let palmNavigationController = UINavigationController(rootViewController: palmAuthViewController)
        
        weak var weakController = palmAuthViewController
        
        weakController?.completionHandler = { (result, error) -> Void in
            weakController?.dismiss(animated: true, completion: nil)
            
            guard error == nil else {
                completion("", PalmError.AuthError)
                return
            }
            
            guard result == true else {
                completion("", PalmError.PalmFailure)
                return
            }
            
            let query = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: Biometrics.serviceName,
                kSecAttrAccount: Biometrics.accountNamePalm,
                kSecReturnData: true
                ] as CFDictionary
            
            var result: AnyObject?
            let status = SecItemCopyMatching(query, &result)
            
            switch status {
            case noErr:
                guard let data = result as? Data else {
                    completion("", PalmError.DataConversionError)
                    return
                }
                
                guard let password = String(data: data, encoding: .utf8) else {
                    completion("", PalmError.StringDecodeError)
                    return
                }
                
                completion(password, nil)
            case errSecItemNotFound:
                completion("", PalmError.PasswordNotFound)
            default:
                completion("", SecError.ItemCopyMatchingError)
            }
        }
        
        viewController.present(palmNavigationController, animated: true, completion: nil)
    }
    
    static func hasPalm() -> Bool {
        if (hasFingerprint()) {
            return false
        } else {
            let query = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: Biometrics.serviceName,
                kSecAttrAccount: Biometrics.accountNamePalm,
                kSecReturnData: true
                ] as CFDictionary
            
            var result: AnyObject?
            let status = SecItemCopyMatching(query, &result)
            
            switch status {
            case noErr:
                break
            default:
                return false
            }
            
            return RRBPalmSDKUser.default().isRegistered()
        }
    }
    
    static func setPalm(viewController: UIViewController, password: String, completion: @escaping (Error?) -> Void) {
        let palmSettingsViewController = RRBPalmSDKSettingsViewController()
        
        let palmNavigationController = UINavigationController(rootViewController: palmSettingsViewController)
        
        weak var weakController = palmSettingsViewController
        
        weakController?.completionHandler = { error in
            weakController?.dismiss(animated: true, completion: nil)
            
            guard let data = password.data(using: .utf8, allowLossyConversion: false) else {
                completion(PalmError.DataConversionError)
                return
            }
            
            _ = deletePalm()
            
            guard let accessControl = SecAccessControlCreateWithFlags(kCFAllocatorDefault, kSecAttrAccessibleAlways, [], nil) else {
                completion(SecError.AccessControlCreateWithFlagsError)
                return
            }
            
            if error == nil {
                let query = [
                    kSecClass: kSecClassGenericPassword,
                    kSecAttrAccessControl: accessControl,
                    kSecAttrService: Biometrics.serviceName,
                    kSecAttrAccount: Biometrics.accountNamePalm,
                    kSecValueData: data
                    ] as CFDictionary
                                
                let status = SecItemAdd(query, nil)
                switch status {
                case noErr:
                    _ = deleteFingerprint()
                    completion(nil)
                default:
                    print("error: \(status)")
                    completion(SecError.ItemAddError)
                }
            } else {
                completion(error)
            }
        }
        
        viewController.present(palmNavigationController, animated: true, completion: nil)
    }
}
