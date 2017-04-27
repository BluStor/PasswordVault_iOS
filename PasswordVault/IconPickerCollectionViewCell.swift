//
//  IconPickerCollectionViewCell.swift
//  PasswordVault
//

import UIKit

class IconPickerCollectionViewCell: UICollectionViewCell {
    let iconImageView = UIImageView()

    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                backgroundColor = UIColor(hex: 0xEFEFEF)
            } else {
                backgroundColor = nil
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(iconImageView)
        NSLayoutConstraint(item: iconImageView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 20.0).isActive = true
        NSLayoutConstraint(item: iconImageView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: -20.0).isActive = true
        NSLayoutConstraint(item: iconImageView, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: 20.0).isActive = true
        NSLayoutConstraint(item: iconImageView, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: -20.0).isActive = true
    }

    func setIcon(iconName: String, tintColor: UIColor) {
        iconImageView.image = UIImage(named: iconName)?.tint(with: tintColor)
    }
}
