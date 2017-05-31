//
//  SyncView.swift
//  PasswordVault
//

import UIKit

class SyncView: UIView {
    let statusLabel = UILabel()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init() {
        super.init(frame: CGRect.zero)

        // Status label

        statusLabel.textAlignment = .center
        statusLabel.font = UIFont.boldSystemFont(ofSize: 16.0)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        self.addSubview(statusLabel)
        NSLayoutConstraint(item: statusLabel, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 10.0).isActive = true
        NSLayoutConstraint(item: statusLabel, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: -10.0).isActive = true
        NSLayoutConstraint(item: statusLabel, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: 10.0).isActive = true
        NSLayoutConstraint(item: statusLabel, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: -10.0).isActive = true

        // Bottom border

        let bottomBorder = UIView()
        bottomBorder.backgroundColor = UIColor(hex: 0xEEEEEE)
        bottomBorder.translatesAutoresizingMaskIntoConstraints = false

        self.addSubview(bottomBorder)
        NSLayoutConstraint(item: bottomBorder, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 1.0).isActive = true
        NSLayoutConstraint(item: bottomBorder, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: bottomBorder, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: bottomBorder, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: 0.0).isActive = true

        // Signals

        Vault.syncStatus.subscribePast(on: self) { status in
            DispatchQueue.main.async {
                switch status {
                case .complete:
                    self.statusLabel.text = "Synced"
                    self.statusLabel.textColor = UIColor(hex: 0x80CBC4)
                case .encrypting:
                    self.statusLabel.text = "Encrypting ..."
                    self.statusLabel.textColor = UIColor(hex: 0xFFCC80)
                case .failed:
                    self.statusLabel.text = "Failed"
                    self.statusLabel.textColor = UIColor(hex: 0xD50000)
                case .transferring:
                    self.statusLabel.text = "Transferring ..."
                    self.statusLabel.textColor = UIColor(hex: 0xFFCC80)
                }
            }
        }
    }
}
