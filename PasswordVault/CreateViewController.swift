//
//  CreateViewController.swift
//  PasswordVault
//

import Material
import SVProgressHUD

class CreateViewController: UITableViewController, UITextFieldDelegate {

    enum CreateError: Error {
        case scanFoundNothing
    }

    let moreButton = IconButton(image: Icon.moreVertical, tintColor: UIColor.white)
    let passwordTextField = TextField()
    let warningLabel = UILabel()
    let createButton = RaisedButton()
    let openDatabaseButton = RaisedButton()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = Theme.Base.viewBackgroundColor

        navigationItem.title = "Create Vault"
        navigationItem.backButton.tintColor = .white
        navigationItem.titleLabel.textColor = .white
        navigationItem.detailLabel.textColor = .white
        navigationItem.rightViews = [moreButton]

        // More button

        moreButton.pulseColor = UIColor(hex: 0xa0e0ff)
        moreButton.addTarget(self, action: #selector(didTouchUpInside(sender:)), for: .touchUpInside)

        // Table view

        tableView.bounces = false
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 200.0
    }

    override func viewDidAppear(_ animated: Bool) {
        Vault.close()
    }

    func didTouchUpInside(sender: UIView) {
        switch sender {
        case createButton:
            create()
        case moreButton:
            let alertController = UIAlertController(title: "Menu", message: nil, preferredStyle: .actionSheet)

            alertController.addAction(UIAlertAction(title: "Choose card", style: .default, handler: { action in
                let chooseCardViewController = ChooseCardViewController()
                self.navigationController?.pushViewController(chooseCardViewController, animated: true)
            }))

            alertController.addAction(UIAlertAction(title: "About", style: .default, handler: { _ in
                let aboutViewController = AboutViewController()
                self.navigationController?.pushViewController(aboutViewController, animated: true)
            }))

            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                alertController.dismiss(animated: true, completion: nil)
            }))

            present(alertController, animated: true, completion: nil)
        case openDatabaseButton:
            let unlockViewController = UnlockViewController()
            navigationController?.setViewControllers([unlockViewController], animated: true)
        default:
            break
        }
    }

    func showError(_ error: Error) {
        let message: String
        switch error {
        case GKCard.CardError.bluetoothNotPoweredOn:
            message = "Bluetooth is not enabled. Enable it in your device's Settings app."
        case GKCard.CardError.cardNotPaired:
            message = "Card is not paired. Pair the card in your device's Bluetooth Settings."
        case GKCard.CardError.fileNotFound:
            message = "No database found on card."
        case CreateError.scanFoundNothing:
            message = "Unable to find card. Make sure it is turned on."
        case KdbxError.decryptionFailed:
            message = "Invalid password."
        case KdbxCrypto.CryptoError.dataError:
            message = "Data error while decrypting."
        default:
            print(error)
            message = "Unknown error."
        }

        DispatchQueue.main.async {
            SVProgressHUD.dismiss()

            let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)

            alertController.addAction(UIAlertAction(title: "Okay", style: .default, handler: { _ in
                alertController.dismiss(animated: true, completion: nil)
            }))

            self.present(alertController, animated: true, completion: nil)
        }
    }

    func create() {
        let password = self.passwordTextField.text ?? ""
        self.passwordTextField.text = ""

        Vault.create(password: password)
        Vault.save()

        if let kdbx = Vault.kdbx {
            let groupViewController = GroupViewController(group: kdbx.database.root.group)

            // TODO: Replace create view controller with unlock view controller
            navigationController?.pushViewController(groupViewController, animated: true)
        }
    }

    // MARK: UITableViewDelegate

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.selectionStyle = .none

        switch indexPath.row {
        case 0:
            // Warning label

            warningLabel.numberOfLines = 0
            warningLabel.text = "Creating a new database will destroy any existing database on your card."

            warningLabel.translatesAutoresizingMaskIntoConstraints = false

            cell.contentView.addSubview(warningLabel)
            NSLayoutConstraint(item: warningLabel, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 10.0).isActive = true
            NSLayoutConstraint(item: warningLabel, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: 0.0).isActive = true
            NSLayoutConstraint(item: warningLabel, attribute: .left, relatedBy: .equal, toItem: cell.contentView, attribute: .left, multiplier: 1.0, constant: 10.0).isActive = true
            NSLayoutConstraint(item: warningLabel, attribute: .right, relatedBy: .equal, toItem: cell.contentView, attribute: .right, multiplier: 1.0, constant: -10.0).isActive = true
        case 1:
            // Password text field

            passwordTextField.delegate = self
            passwordTextField.autocorrectionType = .no
            passwordTextField.autocapitalizationType = .none
            passwordTextField.isSecureTextEntry = true
            passwordTextField.placeholder = "Password"
            passwordTextField.returnKeyType = .next
            passwordTextField.translatesAutoresizingMaskIntoConstraints = false

            cell.contentView.addSubview(passwordTextField)
            NSLayoutConstraint(item: passwordTextField, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 30.0).isActive = true
            NSLayoutConstraint(item: passwordTextField, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: -10.0).isActive = true
            NSLayoutConstraint(item: passwordTextField, attribute: .left, relatedBy: .equal, toItem: cell.contentView, attribute: .left, multiplier: 1.0, constant: 10.0).isActive = true
            NSLayoutConstraint(item: passwordTextField, attribute: .right, relatedBy: .equal, toItem: cell.contentView, attribute: .right, multiplier: 1.0, constant: -10.0).isActive = true
        case 2:
            // Create button

            createButton.setTitle("Create", for: .normal)
            createButton.pulseColor = UIColor.white
            createButton.backgroundColor = UIColor(hex: 0x00BCD4)
            createButton.addTarget(self, action: #selector(didTouchUpInside(sender:)), for: .touchUpInside)
            createButton.translatesAutoresizingMaskIntoConstraints = false

            cell.contentView.addSubview(createButton)
            NSLayoutConstraint(item: createButton, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 10.0).isActive = true
            NSLayoutConstraint(item: createButton, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: -10.0).isActive = true
            NSLayoutConstraint(item: createButton, attribute: .left, relatedBy: .equal, toItem: cell.contentView, attribute: .left, multiplier: 1.0, constant: 10.0).isActive = true
            NSLayoutConstraint(item: createButton, attribute: .right, relatedBy: .equal, toItem: cell.contentView, attribute: .right, multiplier: 1.0, constant: -10.0).isActive = true
        case 3:
            // New database button

            openDatabaseButton.setTitle("Open existing database", for: .normal)
            openDatabaseButton.pulseColor = UIColor.white
            openDatabaseButton.backgroundColor = UIColor(hex: 0xEAEAEA)
            openDatabaseButton.setTitleColor(UIColor(hex: 0x999999), for: .normal)
            openDatabaseButton.addTarget(self, action: #selector(didTouchUpInside(sender:)), for: .touchUpInside)
            openDatabaseButton.translatesAutoresizingMaskIntoConstraints = false

            cell.contentView.addSubview(openDatabaseButton)
            NSLayoutConstraint(item: openDatabaseButton, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 10.0).isActive = true
            NSLayoutConstraint(item: openDatabaseButton, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: -10.0).isActive = true
            NSLayoutConstraint(item: openDatabaseButton, attribute: .left, relatedBy: .equal, toItem: cell.contentView, attribute: .left, multiplier: 1.0, constant: 10.0).isActive = true
            NSLayoutConstraint(item: openDatabaseButton, attribute: .right, relatedBy: .equal, toItem: cell.contentView, attribute: .right, multiplier: 1.0, constant: -10.0).isActive = true
        default:
            break
        }

        return cell
    }

    // MARK: UITextFieldDelegate

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        create()
        return true
    }
}
