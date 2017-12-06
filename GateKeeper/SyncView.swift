//
//  SyncView.swift
//  GateKeeper
//

import Material

class SyncView: UIView {
    let statusLabel = UILabel()
    let retryButton = RaisedButton()
    let bottomBorderView = UIView()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init() {
        super.init(frame: CGRect.zero)

        // Status label

        statusLabel.textAlignment = .center
        statusLabel.font = UIFont.boldSystemFont(ofSize: 16.0)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        // Retry button

        retryButton.setTitle("Retry", for: .normal)
        retryButton.backgroundColor = UIColor(hex: 0xEAEAEA)
        retryButton.setTitleColor(UIColor(hex: 0x999999), for: .normal)
        retryButton.addTarget(self, action: #selector(didTouchUpInside(sender:)), for: .touchUpInside)
        retryButton.translatesAutoresizingMaskIntoConstraints = false

        // Stack view

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false

        self.addSubview(stackView)
        NSLayoutConstraint(item: stackView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 10.0).isActive = true
        NSLayoutConstraint(item: stackView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: -10.0).isActive = true
        NSLayoutConstraint(item: stackView, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: 10.0).isActive = true
        NSLayoutConstraint(item: stackView, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: -10.0).isActive = true

        stackView.addArrangedSubview(statusLabel)

        // Bottom border

        bottomBorderView.backgroundColor = UIColor(hex: 0xEEEEEE)
        bottomBorderView.translatesAutoresizingMaskIntoConstraints = false

        self.addSubview(bottomBorderView)
        NSLayoutConstraint(item: bottomBorderView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 1.0).isActive = true
        NSLayoutConstraint(item: bottomBorderView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: bottomBorderView, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: bottomBorderView, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: 0.0).isActive = true

        // Signals

        Vault.syncStatus.subscribePast(with: self) { status in
            DispatchQueue.main.async {
                switch status {
                case .complete:
                    self.statusLabel.text = "Synced"
                    self.statusLabel.textColor = UIColor(hex: 0x80CBC4)
                    self.retryButton.removeFromSuperview()
                case .connecting:
                    self.statusLabel.text = "Connecting ..."
                    self.statusLabel.textColor = UIColor(hex: 0xFFCC80)
                    self.retryButton.removeFromSuperview()
                case .encrypting:
                    self.statusLabel.text = "Encrypting ..."
                    self.statusLabel.textColor = UIColor(hex: 0xFFCC80)
                    self.retryButton.removeFromSuperview()
                case .failed:
                    self.statusLabel.text = "Failed"
                    self.statusLabel.textColor = UIColor(hex: 0xD50000)
                    stackView.addArrangedSubview(self.retryButton)
                case .transferring:
                    self.statusLabel.text = "Transferring ..."
                    self.statusLabel.textColor = UIColor(hex: 0xFFCC80)
                    self.retryButton.removeFromSuperview()
                }
            }
        }
    }

    @objc func didTouchUpInside(sender: UIView) {
        switch sender {
        case retryButton:
            self.retryButton.removeFromSuperview()
            Vault.save()
        default:
            break
        }
    }
}
