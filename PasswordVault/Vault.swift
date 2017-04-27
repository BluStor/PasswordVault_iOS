//
//  Vault.swift
//  PasswordVault
//

import Foundation

class Vault {
    static var kdbx: Kdbx?

    static func open(data: Data, password: String) throws -> Kdbx {
        kdbx = try Kdbx(data: data, password: password)
        return kdbx!
    }

    static func open(data: Data, compositeKey: [UInt8]) throws -> Kdbx {
        kdbx = try Kdbx(data: data, compositeKey: compositeKey)
        return kdbx!
    }
}
