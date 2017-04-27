//
//  KdbxExtensions.swift
//  PasswordVault
//

import Foundation

extension Bool {

    var xmlString: String {
        return self ? "True" : "False"
    }
}

extension Collection where Iterator.Element == UInt8 {

    static func random(size: Int) -> [UInt8] {
        var randomBytes = [UInt8](repeating: 0x0, count: size)
        let result = SecRandomCopyBytes(kSecRandomDefault, size, &randomBytes)

        if result != errSecSuccess {
            fatalError("Unable to generate random bytes.")
        }

        return randomBytes
    }

    func sha256() -> [UInt8] {
        let bytes = [UInt8](self)

        let digestLength = Int(CC_SHA256_DIGEST_LENGTH)

        var hash = [UInt8](repeating: 0x0, count: digestLength)
        CC_SHA256(bytes, UInt32(bytes.count), &hash)

        return hash
    }

    var hexString: String {
        return self.map {
            String(format: "%02x", $0)
        }.joined()
    }
}

extension Date {

    var xmlString: String {
        let xmlDateFormatter = KdbxXml.XmlDateFormatter.sharedInstance

        return xmlDateFormatter.to(date: self)
    }
}

extension Int {

    var xmlString: String {
        return String(self)
    }
}

extension String {

    subscript(range: Range<Int>) -> String {
        let range = Range(
                uncheckedBounds: (
                        lower: max(0, min(self.characters.count, range.lowerBound)),
                        upper: min(self.characters.count, max(0, range.upperBound))
                )
        )
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: range.upperBound - range.lowerBound)
        return self[Range(start..<end)]
    }

    func sha256() -> [UInt8] {
        let bytes = [UInt8](self.utf8)

        let digestLength = Int(CC_SHA256_DIGEST_LENGTH)

        var hash = [UInt8](repeating: 0x0, count: digestLength)
        CC_SHA256(bytes, UInt32(bytes.count), &hash)

        return hash
    }

    var xmlBool: Bool {
        return self == "True"
    }

    var xmlDate: Date? {
        let xmlDateFormatter = KdbxXml.XmlDateFormatter.sharedInstance

        return xmlDateFormatter.from(string: self)
    }
}

extension UUID {

    var data: Data {
        return Data(bytes: [uuid.0, uuid.1, uuid.2, uuid.3, uuid.4, uuid.5, uuid.6, uuid.7, uuid.8, uuid.9, uuid.10, uuid.11, uuid.12, uuid.13, uuid.14, uuid.15])
    }
}
