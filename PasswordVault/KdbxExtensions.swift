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

extension Array where Iterator.Element == UInt8 {

    static func random(size: Int) -> [UInt8] {
        var randomBytes = [UInt8](repeating: 0x0, count: size)
        let result = SecRandomCopyBytes(kSecRandomDefault, size, &randomBytes)

        assert(result == errSecSuccess)

        return randomBytes
    }

    var hexString: String {
        return self.map {
            String(format: "%02x", $0)
        }.joined()
    }

    func sha256() -> [UInt8] {
        let bytes = [UInt8](self)

        let digestLength = Int(CC_SHA256_DIGEST_LENGTH)

        var hash = [UInt8](repeating: 0x0, count: digestLength)
        CC_SHA256(bytes, UInt32(bytes.count), &hash)

        return hash
    }

    func uuid() -> UUID? {
        if self.count == 16 {
            return UUID(uuid: (self[0], self[1], self[2], self[3], self[4], self[5], self[6], self[7], self[8], self[9], self[10], self[11], self[12],
                               self[13], self[14], self[15]))
        } else {
            return nil
        }
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

    func base64Decoded() -> [UInt8]? {
        if let data = Data(base64Encoded: self) {
            return [UInt8](data)
        }
        return nil
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
