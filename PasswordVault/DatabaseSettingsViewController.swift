//
//  DatabaseSettingsViewController.swift
//  PasswordVault
//

import Material

class DatabaseSettingsViewController: UITableViewController {

    let saveButton = IconButton(title: "Save", titleColor: .white)
    let passwordTextField = TextField()
    let transformationRoundsTextField = TextField()

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
        if let kdbx = Vault.kdbx {
            if let transformationRoundsStr = transformationRoundsTextField.text {
                if let transformationRounds = Int(transformationRoundsStr) {
                    kdbx.transformationRounds = transformationRounds
                }
            }

            if let password = passwordTextField.text {
                if password.characters.count > 0 {
                    kdbx.setPassword(password)
                }
            }
        }

        Vault.save()
        navigationController?.popViewController(animated: true)
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
