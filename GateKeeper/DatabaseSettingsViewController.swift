//
//  DatabaseSettingsViewController.swift
//  GateKeeper
//

import Material

class DatabaseSettingsViewController: UITableViewController {

    let saveButton = IconButton(title: "Save", titleColor: .white)
    let passwordTextField = ErrorTextField()
    let passwordRepeatTextField = ErrorTextField()
    let transformationRoundsTextField = ErrorTextField()

    override func viewDidLoad() {
        navigationItem.titleLabel.text = "Database Settings"
        navigationItem.backButton.tintColor = .white
        navigationItem.titleLabel.textColor = .white
        navigationItem.detailLabel.textColor = .white
        navigationItem.rightViews = [saveButton]

        // Save button

        saveButton.pulseColor = UIColor(hex: 0xa0e0ff)
        saveButton.addTarget(self, action: #selector(didTouchUpInside(sender:)), for: .touchUpInside)

        // Table view

        tableView.bounces = false
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 200.0

        // Password text field

        passwordTextField.placeholder = "New password"
        passwordTextField.isSecureTextEntry = true
        passwordTextField.autocapitalizationType = .none
        passwordTextField.autocorrectionType = .no
        passwordTextField.isVisibilityIconButtonEnabled = true
        passwordTextField.translatesAutoresizingMaskIntoConstraints = false

        // Password repeat text field

        passwordRepeatTextField.placeholder = "New password (repeat)"
        passwordRepeatTextField.isSecureTextEntry = true
        passwordRepeatTextField.autocapitalizationType = .none
        passwordRepeatTextField.autocorrectionType = .no
        passwordRepeatTextField.isVisibilityIconButtonEnabled = true
        passwordRepeatTextField.translatesAutoresizingMaskIntoConstraints = false

        // Transformation rounds text field

        transformationRoundsTextField.placeholder = "Transformation rounds"
        transformationRoundsTextField.translatesAutoresizingMaskIntoConstraints = false

        // Load

        load()
    }

    @objc func didTouchUpInside(sender: UIView) {
        switch sender {
        case saveButton:
            save()
        default:
            break
        }
    }

    func load() {
        if let kdbx = Vault.kdbx {
            transformationRoundsTextField.text = String(kdbx.transformationRounds)
        }
    }

    func save() {
        if validate() {
            if hasChanged() {
                guard let kdbx = Vault.kdbx else {
                    return
                }

                let password = passwordTextField.text ?? ""

                let transformationRoundsStr = transformationRoundsTextField.text ?? "80000"
                let transformationRounds = Int(transformationRoundsStr) ?? 80000

                kdbx.transformationRounds = transformationRounds

                if password.count > 0 {
                    kdbx.setPassword(password)
                }

                Vault.save()
            }

            navigationController?.popViewController(animated: true)
        }
    }

    func validate() -> Bool {
        let password = passwordTextField.text ?? ""
        let passwordRepeat = passwordRepeatTextField.text ?? ""
        let transformationRoundsStr = transformationRoundsTextField.text ?? "80000"
        let transformationRounds = Int(transformationRoundsStr) ?? 80000

        var hasError = false

        if transformationRounds < 80000 {
            transformationRoundsTextField.detail = "Must be at least 80000."
            transformationRoundsTextField.isErrorRevealed = true
            hasError = true
        } else {
            transformationRoundsTextField.isErrorRevealed = false
        }

        if password != passwordRepeat {
            passwordRepeatTextField.detail = "Passwords must be equal."
            passwordRepeatTextField.isErrorRevealed = true
            hasError = true
        } else {
            passwordRepeatTextField.isErrorRevealed = false
        }

        return !hasError
    }

    func hasChanged() -> Bool {
        let password = passwordTextField.text ?? ""

        if password.count > 0 {
            return true
        }

        guard let kdbx = Vault.kdbx else {
            return false
        }

        let transformationRoundsStr = transformationRoundsTextField.text ?? "80000"
        let transformationRounds = Int(transformationRoundsStr) ?? 80000

        return password.count > 0
            || transformationRounds != kdbx.transformationRounds
    }

    // MARK: UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.selectionStyle = .none

        switch indexPath.row {
        case 0:
            cell.contentView.addSubview(passwordTextField)
            NSLayoutConstraint(item: passwordTextField, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 30.0).isActive = true
            NSLayoutConstraint(item: passwordTextField, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: -10.0).isActive = true
            NSLayoutConstraint(item: passwordTextField, attribute: .left, relatedBy: .equal, toItem: cell.contentView, attribute: .left, multiplier: 1.0, constant: 10.0).isActive = true
            NSLayoutConstraint(item: passwordTextField, attribute: .right, relatedBy: .equal, toItem: cell.contentView, attribute: .right, multiplier: 1.0, constant: -10.0).isActive = true
        case 1:
            cell.contentView.addSubview(passwordRepeatTextField)
            NSLayoutConstraint(item: passwordRepeatTextField, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 30.0).isActive = true
            NSLayoutConstraint(item: passwordRepeatTextField, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: -10.0).isActive = true
            NSLayoutConstraint(item: passwordRepeatTextField, attribute: .left, relatedBy: .equal, toItem: cell.contentView, attribute: .left, multiplier: 1.0, constant: 10.0).isActive = true
            NSLayoutConstraint(item: passwordRepeatTextField, attribute: .right, relatedBy: .equal, toItem: cell.contentView, attribute: .right, multiplier: 1.0, constant: -10.0).isActive = true
        case 2:
            cell.contentView.addSubview(transformationRoundsTextField)
            NSLayoutConstraint(item: transformationRoundsTextField, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 30.0).isActive = true
            NSLayoutConstraint(item: transformationRoundsTextField, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: -10.0).isActive = true
            NSLayoutConstraint(item: transformationRoundsTextField, attribute: .left, relatedBy: .equal, toItem: cell.contentView, attribute: .left, multiplier: 1.0, constant: 10.0).isActive = true
            NSLayoutConstraint(item: transformationRoundsTextField, attribute: .right, relatedBy: .equal, toItem: cell.contentView, attribute: .right, multiplier: 1.0, constant: -10.0).isActive = true
        default:
            break
        }

        return cell
    }
}
