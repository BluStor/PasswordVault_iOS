//
//  ScannedPeripheralTableViewCell.swift
//  PasswordVault
//

import UIKit

class ScannedPeripheralTableViewCell: UITableViewCell {

    let nameLabel = UILabel()
    let descriptionLabel = UILabel()

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        // Title label

        nameLabel.numberOfLines = 0
        nameLabel.font = UIFont.systemFont(ofSize: 22.0)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(nameLabel)
        NSLayoutConstraint(item: nameLabel, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 10.0).isActive = true
        NSLayoutConstraint(item: nameLabel, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: 10.0).isActive = true
        NSLayoutConstraint(item: nameLabel, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: -10.0).isActive = true

        // Description label

        descriptionLabel.numberOfLines = 0
        descriptionLabel.textColor = UIColor(hex: 0xacacac)
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(descriptionLabel)
        NSLayoutConstraint(item: descriptionLabel, attribute: .top, relatedBy: .equal, toItem: nameLabel, attribute: .bottom, multiplier: 1.0, constant: 10.0).isActive = true
        NSLayoutConstraint(item: descriptionLabel, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: -10.0).isActive = true
        NSLayoutConstraint(item: descriptionLabel, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: 10.0).isActive = true
        NSLayoutConstraint(item: descriptionLabel, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: -10.0).isActive = true
    }
}
