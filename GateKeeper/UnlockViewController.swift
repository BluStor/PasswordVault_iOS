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
        case databaseNotFound
    }

    let moreButton = IconButton(image: Icon.moreVertical, tintColor: UIColor.white)
    let vaultImageView = UIImageView(image: UIImage(named: "vault"))
    let passwordTextField = TextField()
    let fingerprintSwitch = UISwitch()
    let fingerprintLabel = UILabel()
    let palmSwitch = UISwitch()
    let palmLabel = UILabel()
    let openButton = RaisedButton()
    
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
        
        // Fingerprint switch
        
        fingerprintSwitch.addTarget(self, action: #selector(didValueChange(sender:)), for: .valueChanged)
        fingerprintSwitch.translatesAutoresizingMaskIntoConstraints = false
        
        // Fingerprint label
        
        fingerprintLabel.text = "Fingerprint"
        fingerprintLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Palm switch
        
        palmSwitch.addTarget(self, action: #selector(didValueChange(sender:)), for: .valueChanged)
        palmSwitch.translatesAutoresizingMaskIntoConstraints = false
        
        // Palm label
        
        palmLabel.text = "Palm"
        palmLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Open button

        openButton.setTitle("Open", for: .normal)
        openButton.backgroundColor = Theme.Buttons.normalBackgroundColor
        openButton.addTarget(self, action: #selector(didTouchUpInside(sender:)), for: .touchUpInside)
        openButton.translatesAutoresizingMaskIntoConstraints = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        bluetoothCheck()
        reloadUI()
    }

    func bluetoothCheck() {
        GKCard.checkBluetoothState()
        .catch { _ in
            let alertController = UIAlertController.makeSimple(title: "Bluetooth", message: "Bluetooth is not enabled. Enable it in your device's Settings app.")
            
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func clearPassword() {
        passwordTextField.text = ""
    }
    
    func fingerprintEnable(password: String) {
        let alertController = UIAlertController(title: "Enable fingerprint?", message: "The password entered will be stored encrypted on your phone and will be accessible only with your fingerprint.", preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "Enable", style: .default, handler: { action in
            do {
                try Biometrics.setFingerprint(password: password)
                _ = Biometrics.deletePalm()
            } catch {
                self.showError(error)
            }
            
            self.reloadUI()
            self.clearPassword()
        }))
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
            self.reloadUI()
            alertController.dismiss(animated: true, completion: nil)
        }))
        
        present(alertController, animated: true, completion: nil)
    }
    
    func fingerprintDisable() {
        let alertController = UIAlertController(title: "Disable fingerprint?", message: "This will disable fingerprint authentication.", preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "Disable", style: .default, handler: { action in
            _ = Biometrics.deleteFingerprint()
            
            self.reloadUI()
            self.clearPassword()
        }))
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
            alertController.dismiss(animated: true, completion: {
                self.reloadUI()
            })
        }))
        
        present(alertController, animated: true, completion: nil)
    }
    
    func palmEnable(password: String) {
        let alertController = UIAlertController(title: "Enable palm?", message: "The password entered will be stored encrypted on your phone and will be accessible only with your palm.", preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "Enable", style: .default, handler: { action in
            Biometrics.setPalm(viewController: self, password: password, completion: { error in
                self.reloadUI()
                if let error = error {
                    self.showError(error)
                } else {
                    _ = Biometrics.deleteFingerprint()
                    self.clearPassword()
                }
            })
        }))
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
            alertController.dismiss(animated: true, completion: nil)
            self.reloadUI()
        }))
        
        present(alertController, animated: true, completion: nil)
    }
    
    func palmDisable() {
        let alertController = UIAlertController(title: "Disable palm?", message: "This will disable palm authentication.", preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "Disable", style: .default, handler: { action in
            _ = Biometrics.deletePalm()
            
            self.reloadUI()
        }))
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
            self.reloadUI()
            alertController.dismiss(animated: true, completion: nil)
        }))
        
        present(alertController, animated: true, completion: nil)
    }
    
    func reloadUI() {
        fingerprintSwitch.isOn = Biometrics.hasFingerprint()
        palmSwitch.isOn = Biometrics.hasPalm()
        
        tableView.reloadRows(at: [IndexPath(item: 1, section: 0), IndexPath(item: 2, section: 0), IndexPath(item: 3, section: 0)], with: UITableViewRowAnimation.automatic)
    }
    
    @objc func didValueChange(sender: UIView) {
        switch sender {
        case fingerprintSwitch:
            if fingerprintSwitch.isOn {
                fingerprintSwitch.setOn(false, animated: true)
                
                if Biometrics.isFingerprintAvailable() {
                    if Biometrics.hasPalm() {
                        let alertController = UIAlertController.makeSimple(title: "Error", message: "Please disable palm before enabling fingerprint.")
                        
                        present(alertController, animated: true, completion: nil)
                    } else {
                        let password = passwordTextField.text ?? ""
                        
                        if password.count > 0 {
                            fingerprintEnable(password: password)
                        } else {
                            let alertController = UIAlertController.makeSimple(title: "No password", message: "You must enter a password.")
                            
                            present(alertController, animated: true, completion: nil)
                        }
                    }
                } else {
                    let alertController = UIAlertController.makeSimple(title: "Error", message: "Unfortunately your device does not support fingerprint authentication.")
                    
                    present(alertController, animated: true, completion: nil)
                }
                
                reloadUI()
            } else {
                fingerprintSwitch.setOn(true, animated: true)
                
                fingerprintDisable()
                reloadUI()
            }
        case palmSwitch:
            if palmSwitch.isOn {
                palmSwitch.setOn(false, animated: true)
                
                if Biometrics.hasFingerprint() {
                    let alertController = UIAlertController.makeSimple(title: "Error", message: "Please disable fingerprint before enabling palm.")
                    
                    present(alertController, animated: true, completion: nil)
                } else {
                    let password = passwordTextField.text ?? ""
                    if password.count > 0 {
                        palmEnable(password: password)
                    } else {
                        let alertController = UIAlertController.makeSimple(title: "No password", message: "You must enter a password.")
                        
                        present(alertController, animated: true, completion: nil)
                    }
                }
            } else {
                palmSwitch.setOn(true, animated: true)
                
                palmDisable()
                reloadUI()
            }
        default:
            break
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
            if fingerprintSwitch.isOn {
                do {
                    let password = try Biometrics.getFingerprint()
                    open(password: password)
                } catch {
                    showError(error)
                }
            } else if palmSwitch.isOn {
                Biometrics.getPalm(viewController: self, completion: { (password, error) in
                    if let error = error {
                        switch error {
                        case Biometrics.PalmError.PalmFailure:
                            break
                        default:
                            self.showError(error)
                        }
                    } else {
                        self.open(password: password)
                    }
                })
            } else {
                let password = getPassword()
                open(password: password)
            }
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
        case UnlockError.databaseNotFound:
            message = "No database found on card."
            self.loadCreate()
        case UnlockError.scanFoundNothing:
            message = "Unable to find card. Make sure it is turned on."
            loadChooseCard()
        case KdbxError.decryptionFailed:
            message = "Invalid password.  If you're using fingerprint or palm, disable and try again."
        case KdbxCrypto.CryptoError.dataError:
            message = "Data error while decrypting."
        default:
            message = "\(error)"
        }
        
        let alertController = UIAlertController.makeSimple(title: "Error", message: message)
        
        present(alertController, animated: true, completion: nil)
    }

    func open(password: String) {
        guard let cardUUID = Vault.cardUUID else {
            return
        }

        guard let card = GKCard(uuid: cardUUID) else {
            return
        }
        
        async(in: .background, {
            do {
                async(in: .main, {
                    HUD.dimsBackground = false
                    HUD.show(.labeledProgress(title: "Opening", subtitle: "Connecting"))
                })
                try await(in: .background, card.connect().retry(2))
                
                async(in: .main, {
                    HUD.show(.labeledProgress(title: "Opening", subtitle: "Database exists?"))
                })
                
                let databaseExists = try await(card.exists(path: Vault.dbPath))

                if (!databaseExists) {
                    throw UnlockError.databaseNotFound
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
    
    func getPassword() -> String {
        let password = passwordTextField.text ?? ""
        passwordTextField.text = ""
        passwordTextField.resignFirstResponder()
        
        return password
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
            if Biometrics.hasFingerprint() || Biometrics.hasPalm() {
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
            if !Biometrics.hasFingerprint() && !Biometrics.hasPalm() {
                cell.contentView.addSubview(passwordTextField)
                NSLayoutConstraint(item: passwordTextField, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 30.0).isActive = true
                NSLayoutConstraint(item: passwordTextField, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: -10.0).isActive = true
                NSLayoutConstraint(item: passwordTextField, attribute: .left, relatedBy: .equal, toItem: cell.contentView, attribute: .left, multiplier: 1.0, constant: 10.0).isActive = true
                NSLayoutConstraint(item: passwordTextField, attribute: .right, relatedBy: .equal, toItem: cell.contentView, attribute: .right, multiplier: 1.0, constant: -10.0).isActive = true
            }
        case 2:
            cell.contentView.addSubview(fingerprintSwitch)
            NSLayoutConstraint(item: fingerprintSwitch, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 10.0).isActive = true
            NSLayoutConstraint(item: fingerprintSwitch, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: -10.0).isActive = true
            NSLayoutConstraint(item: fingerprintSwitch, attribute: .left, relatedBy: .equal, toItem: cell.contentView, attribute: .left, multiplier: 1.0, constant: 10.0).isActive = true
            
            cell.contentView.addSubview(fingerprintLabel)
            NSLayoutConstraint(item: fingerprintLabel, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 10.0).isActive = true
            NSLayoutConstraint(item: fingerprintLabel, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: -10.0).isActive = true
            NSLayoutConstraint(item: fingerprintLabel, attribute: .left, relatedBy: .equal, toItem: fingerprintSwitch, attribute: .right, multiplier: 1.0, constant: 10.0).isActive = true
            NSLayoutConstraint(item: fingerprintLabel, attribute: .right, relatedBy: .equal, toItem: cell.contentView, attribute: .right, multiplier: 1.0, constant: -10.0).isActive = true
        case 3:
            cell.contentView.addSubview(palmSwitch)
            NSLayoutConstraint(item: palmSwitch, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 10.0).isActive = true
            NSLayoutConstraint(item: palmSwitch, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: -10.0).isActive = true
            NSLayoutConstraint(item: palmSwitch, attribute: .left, relatedBy: .equal, toItem: cell.contentView, attribute: .left, multiplier: 1.0, constant: 10.0).isActive = true
            
            cell.contentView.addSubview(palmLabel)
            NSLayoutConstraint(item: palmLabel, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 10.0).isActive = true
            NSLayoutConstraint(item: palmLabel, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: -10.0).isActive = true
            NSLayoutConstraint(item: palmLabel, attribute: .left, relatedBy: .equal, toItem: palmSwitch, attribute: .right, multiplier: 1.0, constant: 10.0).isActive = true
            NSLayoutConstraint(item: palmLabel, attribute: .right, relatedBy: .equal, toItem: cell.contentView, attribute: .right, multiplier: 1.0, constant: -10.0).isActive = true
        case 4:
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
            passwordTextField.resignFirstResponder()
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
