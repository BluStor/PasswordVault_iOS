//
//  UnlockViewController.swift
//  GateKeeper
//

import Hydra
import Material
import PKHUD

class UnlockViewController: UITableViewController, UITextFieldDelegate {

    enum UnlockError: Error {
        case scanFoundNothing
        case dbNotFound
    }

    let moreButton = IconButton(image: Icon.moreVertical, tintColor: UIColor.white)
    let vaultImageView = UIImageView(image: UIImage(named: "vault"))
    let passwordTextField = TextField()
    let openButton = RaisedButton()
    let savePasswordButton = RaisedButton()
    let deletePasswordButton = RaisedButton()
    
    var isUsingBiometrics = false
    
    var biometricsIsAvailable = false
    var biometricsHasPassword = false

    override func viewDidLoad() {
        view.backgroundColor = Theme.Base.viewBackgroundColor

        navigationItem.titleLabel.text = "GateKeeper \(versionString())"
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
        
        // Save password button
        
        savePasswordButton.setTitle("Use Finger Print", for: .normal)
        savePasswordButton.backgroundColor = Theme.Buttons.normalBackgroundColor
        savePasswordButton.addTarget(self, action: #selector(didTouchUpInside(sender:)), for: .touchUpInside)
        savePasswordButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Delete password button
        
        deletePasswordButton.setTitle("Delete Password", for: .normal)
        deletePasswordButton.titleColor = Theme.Buttons.mutedTitleColor
        deletePasswordButton.backgroundColor = Theme.Buttons.mutedBackgroundColor
        deletePasswordButton.addTarget(self, action: #selector(didTouchUpInside(sender:)), for: .touchUpInside)
        deletePasswordButton.translatesAutoresizingMaskIntoConstraints = false
    }

    override func viewWillAppear(_ animated: Bool) {
        bluetoothCheck()
        reloadBiometrics()
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
    
    func reloadBiometrics() {
        biometricsIsAvailable = Biometrics.isAvailable()
        biometricsHasPassword = Biometrics.hasPassword()
        tableView.reloadData()
    }

    @objc func didTouchUpInside(sender: UIView) {
        switch sender {
        case deletePasswordButton:
            deletePassword()
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
        case savePasswordButton:
            savePassword()
        default:
            break
        }
    }

    func showError(_ error: Error) {
        let message: String
        switch error {
        case GKCard.CardError.bluetoothNotPoweredOn:
            message = "Bluetooth is not enabled. Enable it in your device's Settings app."
            loadChooseCard()
        case GKCard.CardError.cardNotPaired:
            message = "Card is not paired. Please put the card in pairing mode and try again."
            loadChooseCard()
        case GKCard.CardError.connectionTimedOut:
            message = "Connection timed out. Ensure the card is powered on and nearby."
            loadChooseCard()
        case UnlockError.dbNotFound:
            message = "No database found on card."
            self.loadCreate()
        case UnlockError.scanFoundNothing:
            message = "Unable to find card. Make sure it is turned on."
            loadChooseCard()
        case KdbxError.decryptionFailed:
            if isUsingBiometrics {
                message = "Invalid password.  Biometrics NOT enabled. Please check your password and try again"
            } else {
                message = "Invalid password.  Please check your password and try again"
            }
        case KdbxCrypto.CryptoError.dataError:
            message = "Data error while decrypting."
        default:
            message = "\(error)"
        }
        
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)

        alertController.addAction(UIAlertAction(title: "Okay", style: .default, handler: { _ in
            alertController.dismiss(animated: true, completion: nil)
        }))

        self.present(alertController, animated: true, completion: nil)
    }

    func open() {
        guard let cardUUID = Vault.cardUUID else {
            return
        }

        guard let card = GKCard(uuid: cardUUID) else {
            return
        }
        
        var password = ""
        
        if Biometrics.hasPassword() {
            do {
                password = try Biometrics.getPassword()
            } catch {
                print(error)
            }
        }
        
        if password.isEmpty {
            password = getPassword()
        }
        
        async(in: .background, {
            do {
                async(in: .main, {
                    HUD.dimsBackground = false
                    HUD.show(.labeledProgress(title: "Opening", subtitle: "Connecting"))
                })
                try await(in: .background, card.connect().retry(2))
                
                async(in: .main, {
                    HUD.show(.labeledProgress(title: "Opening", subtitle: "Check Db exists"))
                })
                let dbExists = try await(card.exists(path: Vault.dbPath))

                if (!dbExists) {
                    throw UnlockError.dbNotFound
                }
                
                async(in: .main, {
                    HUD.show(.labeledProgress(title: "Opening", subtitle: "Transferring"))
                })
                let data = try await(card.get(path: Vault.dbPath))
                
                async(in: .main, {
                    HUD.show(.labeledProgress(title: "Opening", subtitle: "Decrypting"))
                })
                
                let kdbx = try await(in: .background, { resolve, reject, _ in
                    return resolve(try Vault.open(encryptedData: data, password: password))
                })
                
                // Let's only save the password
                // if the user clicked save biometrics button
                // and it it hasn't already been saved
                if (self.isUsingBiometrics && Biometrics.isAvailable() && !Biometrics.hasPassword()) {
                    do {
                        try Biometrics.setPassword(password: password)
                        self.tableView.reloadData()
                        self.reloadBiometrics()
                    } catch {
                        print(error)
                    }
                }
                
                async(in: .main, {
                    HUD.hide()
                    let groupViewController = GroupViewController(group: kdbx.database.root.group)
                    self.navigationController?.pushViewController(groupViewController, animated: true)
                })
            } catch {
                async(in: .main, {
                    HUD.hide()
                    self.showError(error)
                })
            }
            
            card.disconnect().then {}
        })
    }
    
    func deletePassword() {
        isUsingBiometrics = false
        do {
            try Biometrics.deletePassword()
            tableView.reloadData()
            reloadBiometrics()
        } catch {
            print(error)
        }
    }
    
    func getPassword() -> String {
        let password = passwordTextField.text ?? ""
        passwordTextField.text = ""
        passwordTextField.resignFirstResponder()
        
        return password
    }
    
    func savePassword() {
        isUsingBiometrics = true
        
        open()
    }

    func versionString() -> String {
        let releaseVersionNumber = Bundle.main.releaseVersionNumber
        return releaseVersionNumber ?? "?"
    }

    // MARK: UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case 1:
            if biometricsHasPassword {
                return 0.0
            }
        case 3:
            if !biometricsIsAvailable || biometricsHasPassword {
                return 0.0
            }
        case 4:
            if !biometricsHasPassword {
                return 0.0
            }
        default:
            break
        }
        
        return UITableViewAutomaticDimension
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
            if !biometricsHasPassword {
                cell.contentView.addSubview(passwordTextField)
                NSLayoutConstraint(item: passwordTextField, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 30.0).isActive = true
                NSLayoutConstraint(item: passwordTextField, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: -10.0).isActive = true
                NSLayoutConstraint(item: passwordTextField, attribute: .left, relatedBy: .equal, toItem: cell.contentView, attribute: .left, multiplier: 1.0, constant: 10.0).isActive = true
                NSLayoutConstraint(item: passwordTextField, attribute: .right, relatedBy: .equal, toItem: cell.contentView, attribute: .right, multiplier: 1.0, constant: -10.0).isActive = true
            }
        case 2:
            cell.contentView.addSubview(openButton)
            NSLayoutConstraint(item: openButton, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 10.0).isActive = true
            NSLayoutConstraint(item: openButton, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: -10.0).isActive = true
            NSLayoutConstraint(item: openButton, attribute: .left, relatedBy: .equal, toItem: cell.contentView, attribute: .left, multiplier: 1.0, constant: 10.0).isActive = true
            NSLayoutConstraint(item: openButton, attribute: .right, relatedBy: .equal, toItem: cell.contentView, attribute: .right, multiplier: 1.0, constant: -10.0).isActive = true
        case 3:
            if biometricsIsAvailable && !biometricsHasPassword {
                cell.contentView.addSubview(savePasswordButton)
                NSLayoutConstraint(item: savePasswordButton, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 10.0).isActive = true
                NSLayoutConstraint(item: savePasswordButton, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: -10.0).isActive = true
                NSLayoutConstraint(item: savePasswordButton, attribute: .left, relatedBy: .equal, toItem: cell.contentView, attribute: .left, multiplier: 1.0, constant: 10.0).isActive = true
                NSLayoutConstraint(item: savePasswordButton, attribute: .right, relatedBy: .equal, toItem: cell.contentView, attribute: .right, multiplier: 1.0, constant: -10.0).isActive = true
            }
        case 4:
            if biometricsHasPassword {
                cell.contentView.addSubview(deletePasswordButton)
                NSLayoutConstraint(item: deletePasswordButton, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 10.0).isActive = true
                NSLayoutConstraint(item: deletePasswordButton, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: -10.0).isActive = true
                NSLayoutConstraint(item: deletePasswordButton, attribute: .left, relatedBy: .equal, toItem: cell.contentView, attribute: .left, multiplier: 1.0, constant: 10.0).isActive = true
                NSLayoutConstraint(item: deletePasswordButton, attribute: .right, relatedBy: .equal, toItem: cell.contentView, attribute: .right, multiplier: 1.0, constant: -10.0).isActive = true
            }
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
    
    func loadChooseCard() {
        let chooseCardViewController = ChooseCardViewController()
        navigationController?.setViewControllers([chooseCardViewController], animated: true)
    }
    func loadCreate() {
        let createViewController = CreateViewController()
        navigationController?.setViewControllers([createViewController], animated: true)
    }

}
