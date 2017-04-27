//
//  Extensions.swift
//  PasswordVault
//

import UIKit

extension Array {
    
    func randomItem() -> Iterator.Element? {
        return isEmpty ? nil : self[Int(arc4random_uniform(UInt32(endIndex)))]
    }
}

extension CGFloat {

    static func random() -> CGFloat {
        return CGFloat(arc4random()) / CGFloat(UInt32.max)
    }
}

extension UIColor {

    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")

        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }

    convenience init(hex: Int) {
        self.init(red: (hex >> 16) & 0xFF, green: (hex >> 8) & 0xFF, blue: hex & 0xFF)
    }

    static func random() -> UIColor {
        return UIColor(red: .random(),
                green: .random(),
                blue: .random(),
                alpha: 1.0)
    }
}

extension UIImage {
    func tint(image: UIImage, color: UIColor) -> UIImage {
        let ciImage = CIImage(image: image)
        let filter = CIFilter(name: "CIMultiplyCompositing")!
        let colorFilter = CIFilter(name: "CIConstantColorGenerator")!

        let ciColor = CIColor(color: color)
        colorFilter.setValue(ciColor, forKey: kCIInputColorKey)
        let colorImage = colorFilter.outputImage

        filter.setValue(colorImage, forKey: kCIInputImageKey)
        filter.setValue(ciImage, forKey: kCIInputBackgroundImageKey)

        return UIImage(ciImage: filter.outputImage!)
    }
}
