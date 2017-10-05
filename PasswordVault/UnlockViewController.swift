//
//  UnlockViewController.swift
//  PasswordVault
//

import Hydra
import Material
import SVProgressHUD

class UnlockViewController: UITableViewController, UITextFieldDelegate {

    enum UnlockError: Error {
        case scanFoundNothing
    }

    let moreButton = IconButton(image: Icon.moreVertical, tintColor: UIColor.white)
    let vaultImageView = UIImageView(image: UIImage(named: "vault"))
    let passwordTextField = TextField()
    let openButton = RaisedButton()
    let chooseCardButton = RaisedButton()

    override func viewDidLoad() {
        view.backgroundColor = Theme.Base.viewBackgroundColor

        navigationItem.titleLabel.text = "Password Vault \(versionString())"
        navigationItem.backButton.tintColor = .white
        navigationItem.titleLabel.textColor = .white
        navigationItem.detailLabel.textColor = .white
        navigationItem.rightViews = [moreButton]

        // More button

        moreButton.pulseColor = Theme.Base.navigationItemButtonPulseColor
        moreButton.addTarget(self, action: #selector(didTouchUpInside(sender:)), for: .touchUpInside)

        // Table view

        tableView.bounces = false
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 200.0

        // Vault image view

        vaultImageView.clipsToBounds = true
        vaultImageView.contentMode = .scaleAspectFit
        vaultImageView.translatesAutoresizingMaskIntoConstraints = false

        // Password text field

        passwordTextField.delegate = self
        passwordTextField.autocorrectionType = .no
        passwordTextField.autocapitalizationType = .none
        passwordTextField.isSecureTextEntry = true
        passwordTextField.placeholder = "Password"
        passwordTextField.returnKeyType = .done
        passwordTextField.isVisibilityIconButtonEnabled = true
        passwordTextField.translatesAutoresizingMaskIntoConstraints = false

        // Open button

        openButton.setTitle("Open", for: .normal)
        openButton.backgroundColor = Theme.Buttons.normalBackgroundColor
        openButton.addTarget(self, action: #selector(didTouchUpInside(sender:)), for: .touchUpInside)
        openButton.translatesAutoresizingMaskIntoConstraints = false

        // Choose card button

        chooseCardButton.setTitle("Choose card", for: .normal)
        chooseCardButton.pulseColor = UIColor.white
        chooseCardButton.backgroundColor = Theme.Buttons.mutedBackgroundColor
        chooseCardButton.setTitleColor(Theme.Buttons.mutedTitleColor, for: .normal)
        chooseCardButton.addTarget(self, action: #selector(didTouchUpInside(sender:)), for: .touchUpInside)
        chooseCardButton.translatesAutoresizingMaskIntoConstraints = false

        // Bluetooth check

        bluetoothCheck()
    }

    override func viewDidAppear(_ animated: Bool) {
        Vault.close()
    }

    func bluetoothCheck() {
        GKCard.checkBluetoothState()
        .catch { _ in
            let alertController = UIAlertController(title: "Bluetooth", message: "Bluetooth is not enabled. Enable it in your device's Settings app.", preferredStyle: .alert)

            alertController.addAction(UIAlertAction(title: "Okay", style: .default, handler: { _ in
                alertController.dismiss(animated: true, completion: nil)
            }))

            self.present(alertController, animated: true, completion: nil)
        }
    }

    @objc func didTouchUpInside(sender: UIView) {
        switch sender {
        case moreButton:
            let alertController = UIAlertController(title: "Menu", message: nil, preferredStyle: .actionSheet)

            alertController.addAction(UIAlertAction(title: "Choose card", style: .default, handler: { _ in
                let chooseCardViewController = ChooseCardViewController()
                self.navigationController?.pushViewController(chooseCardViewController, animated: true)
            }))

            alertController.addAction(UIAlertAction(title: "New database", style: .default, handler: { _ in
                let createViewController = CreateViewController()
                self.navigationController?.setViewControllers([createViewController], animated: true)
            }))

            alertController.addAction(UIAlertAction(title: "About", style: .default, handler: { _ in
                let aboutViewController = AboutViewController()
                self.navigationController?.pushViewController(aboutViewController, animated: true)
            }))

            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                alertController.dismiss(animated: true, completion: nil)
            }))

            alertController.popoverPresentationController?.sourceView = moreButton
            alertController.popoverPresentationController?.sourceRect = moreButton.bounds

            present(alertController, animated: true, completion: nil)
        case openButton:
            open()
        case chooseCardButton:
            let chooseCardViewController = ChooseCardViewController()
            navigationController?.setViewControllers([chooseCardViewController], animated: true)
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
            message = "Card is not paired. Please put the card in pairing mode and try again."
        case GKCard.CardError.connectionTimedOut:
            message = "Connection timed out. Ensure the card is powered on and nearby."
        case GKCard.CardError.fileNotFound:
            message = "No database found on card."
        case UnlockError.scanFoundNothing:
            message = "Unable to find card. Make sure it is turned on."
        case KdbxError.decryptionFailed:
            message = "Invalid password."
        case KdbxCrypto.CryptoError.dataError:
            message = "Data error while decrypting."
        default:
            message = "\(error)"
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

    func open() {
        let password = passwordTextField.text ?? ""
        passwordTextField.text = ""
        passwordTextField.resignFirstResponder()

        SVProgressHUD.show(withStatus: "Connecting")

        guard let cardUUID = Vault.cardUUID else {
            return
        }

        guard let card = GKCard(uuid: cardUUID) else {
            return
        }

        card.connect().retry(2)
        .then {
            DispatchQueue.main.async {
                SVProgressHUD.setStatus("Transferring")
            }
        }
        .then {
            card.get(path: Vault.dbPath)
        }
        .then { data in
            DispatchQueue.main.async {
                SVProgressHUD.setStatus("Decrypting")
            }

            card.disconnect().then {}

            do {
                let kdbx = try Vault.open(encryptedData: data, password: password)

                DispatchQueue.main.async {
                    SVProgressHUD.dismiss()

                    let groupViewController = GroupViewController(group: kdbx.database.root.group)
                    self.navigationController?.pushViewController(groupViewController, animated: true)
                }
            } catch {
                self.showError(error)
            }
        }
        .catch { error in
            card.disconnect().then {}
            self.showError(error)
        }
    }

    func versionString() -> String {
        let releaseVersionNumber = Bundle.main.releaseVersionNumber
        return releaseVersionNumber ?? "?"
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
            let aspectRatio = (vaultImageView.frame.size.height / vaultImageView.frame.size.width)

            cell.contentView.addSubview(vaultImageView)
            NSLayoutConstraint(item: vaultImageView, attribute: .height, relatedBy: .lessThanOrEqual, toItem: vaultImageView, attribute: .width, multiplier: aspectRatio, constant: 0.0).isActive = true
            NSLayoutConstraint(item: vaultImageView, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 0.0).isActive = true
            NSLayoutConstraint(item: vaultImageView, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: 0.0).isActive = true
            NSLayoutConstraint(item: vaultImageView, attribute: .left, relatedBy: .equal, toItem: cell.contentView, attribute: .left, multiplier: 1.0, constant: 0.0).isActive = true
            NSLayoutConstraint(item: vaultImageView, attribute: .right, relatedBy: .equal, toItem: cell.contentView, attribute: .right, multiplier: 1.0, constant: 0.0).isActive = true
        case 1:
            cell.contentView.addSubview(passwordTextField)
            NSLayoutConstraint(item: passwordTextField, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 30.0).isActive = true
            NSLayoutConstraint(item: passwordTextField, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: -10.0).isActive = true
            NSLayoutConstraint(item: passwordTextField, attribute: .left, relatedBy: .equal, toItem: cell.contentView, attribute: .left, multiplier: 1.0, constant: 10.0).isActive = true
            NSLayoutConstraint(item: passwordTextField, attribute: .right, relatedBy: .equal, toItem: cell.contentView, attribute: .right, multiplier: 1.0, constant: -10.0).isActive = true
        case 2:
            cell.contentView.addSubview(openButton)
            NSLayoutConstraint(item: openButton, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 10.0).isActive = true
            NSLayoutConstraint(item: openButton, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: -10.0).isActive = true
            NSLayoutConstraint(item: openButton, attribute: .left, relatedBy: .equal, toItem: cell.contentView, attribute: .left, multiplier: 1.0, constant: 10.0).isActive = true
            NSLayoutConstraint(item: openButton, attribute: .right, relatedBy: .equal, toItem: cell.contentView, attribute: .right, multiplier: 1.0, constant: -10.0).isActive = true
        default:
            break
        }

        return cell
    }

    // MARK: UITextFieldDelegate

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == passwordTextField {
            open()
        }

        return true
    }
}
