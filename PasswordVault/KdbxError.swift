//
//  KdbxError.swift
//  PasswordVault
//

import Foundation

enum KdbxError: Error {

    case databaseReadError
    case databaseVersionUnsupportedError
    case databaseWriteError
    case decryptionError
    case encryptionError
}
