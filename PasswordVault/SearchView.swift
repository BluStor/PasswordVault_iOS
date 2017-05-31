//
//  SearchView.swift
//  PasswordVault
//

import Material

class SearchView: UIView {
    let searchTextField = TextField()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init() {
        super.init(frame: CGRect.zero)

        // Search text field

        searchTextField.translatesAutoresizingMaskIntoConstraints = false

        self.addSubview(searchTextField)
        NSLayoutConstraint(item: searchTextField, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 10.0).isActive = true
        NSLayoutConstraint(item: searchTextField, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: -10.0).isActive = true
        NSLayoutConstraint(item: searchTextField, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: 10.0).isActive = true
        NSLayoutConstraint(item: searchTextField, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: -10.0).isActive = true

        // Bottom border

        let bottomBorder = UIView()
        bottomBorder.backgroundColor = UIColor(hex: 0xEEEEEE)
        bottomBorder.translatesAutoresizingMaskIntoConstraints = false

        self.addSubview(bottomBorder)
        NSLayoutConstraint(item: bottomBorder, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 1.0).isActive = true
        NSLayoutConstraint(item: bottomBorder, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: bottomBorder, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: bottomBorder, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: 0.0).isActive = true
    }
}
