//
//  DatabaseSettingsViewController.swift
//  PasswordVault
//

import Material

class DatabaseSettingsViewController: UITableViewController {

    let saveButton = IconButton(title: "Save", titleColor: .white)
    let passwordTextField = ErrorTextField()
    let transformationRoundsTextField = ErrorTextField()

    override func viewDidLoad() {
        navigationItem.title = "Database Settings"
        navigationItem.backButton.tintColor = .white
        navigationItem.titleLabel.textColor = .white
        navigationItem.detailLabel.textColor = .white
        navigationItem.rightViews = [saveButton]

        // Save button

        saveButton.addTarget(self, action: #selector(didTouchUpInside(sender:)), for: .touchUpInside)

        // Table view

        tableView.bounces = false
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 200.0

        // Password text field

        passwordTextField.placeholder = "Password"
        passwordTextField.isSecureTextEntry = true
        passwordTextField.autocapitalizationType = .none
        passwordTextField.autocorrectionType = .no
        passwordTextField.isVisibilityIconButtonEnabled = true
        passwordTextField.translatesAutoresizingMaskIntoConstraints = false

        // Transformation rounds text field

        transformationRoundsTextField.placeholder = "Transformation rounds"
        transformationRoundsTextField.translatesAutoresizingMaskIntoConstraints = false

        // Load

        load()
    }

    func didTouchUpInside(sender: UIView) {
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
            guard let kdbx = Vault.kdbx else {
                return
            }

            let password = passwordTextField.text ?? ""

            let transformationRoundsStr = transformationRoundsTextField.text ?? "8000"
            let transformationRounds = Int(transformationRoundsStr) ?? 8000

            kdbx.transformationRounds = transformationRounds

            if password.characters.count > 0 {
                kdbx.setPassword(password)
            }

            Vault.save()
            navigationController?.popViewController(animated: true)
        }
    }

    func validate() -> Bool {
        let transformationRoundsStr = transformationRoundsTextField.text ?? "-1"
        let transformationRounds = Int(transformationRoundsStr) ?? -1

        var hasError = false

        if transformationRounds < 8000 {
            transformationRoundsTextField.detail = "Must be at least 8000."
            transformationRoundsTextField.isErrorRevealed = true
            hasError = true
        } else {
            transformationRoundsTextField.isErrorRevealed = false
        }

        return !hasError
    }

    // MARK: UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
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
