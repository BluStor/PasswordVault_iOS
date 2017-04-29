//
//  UnlockViewController.swift
//  PasswordVault
//

import Material
import SVProgressHUD

class UnlockViewController: ScrollViewController, UITextFieldDelegate {

    let fabButton = FABButton(image: Icon.check, tintColor: .white)
    var fabButtonBottomConstraint = NSLayoutConstraint()
    let passwordTextField = ErrorTextField()
    let vaultImageView = UIImageView(image: UIImage(named: "Vault"))

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        navigationItem.title = "Password Vault"
        navigationItem.backButton.tintColor = .white
        navigationItem.titleLabel.textColor = .white
        navigationItem.detailLabel.textColor = .white

        // Vault image view

        vaultImageView.clipsToBounds = true
        vaultImageView.contentMode = .scaleAspectFill
        vaultImageView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(vaultImageView)
        NSLayoutConstraint(item: vaultImageView, attribute: .height, relatedBy: .lessThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 200.0).isActive = true
        NSLayoutConstraint(item: vaultImageView, attribute: .width, relatedBy: .equal, toItem: scrollView, attribute: .width, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: vaultImageView, attribute: .left, relatedBy: .equal, toItem: scrollView, attribute: .left, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: vaultImageView, attribute: .right, relatedBy: .equal, toItem: scrollView, attribute: .right, multiplier: 1.0, constant: 0.0).isActive = true

        // Password text field

        passwordTextField.delegate = self
        passwordTextField.autocorrectionType = .no
        passwordTextField.autocapitalizationType = .none
        passwordTextField.isSecureTextEntry = true
        passwordTextField.placeholder = "Password"
        passwordTextField.returnKeyType = .done
        passwordTextField.addTarget(self, action: #selector(didChangeTextField(sender:)), for: .editingChanged)
        passwordTextField.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(passwordTextField)
        NSLayoutConstraint(item: passwordTextField, attribute: .top, relatedBy: .equal, toItem: vaultImageView, attribute: .bottom, multiplier: 1.0, constant: 35.0).isActive = true
        NSLayoutConstraint(item: passwordTextField, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 20.0).isActive = true
        NSLayoutConstraint(item: passwordTextField, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: -20.0).isActive = true

        // Floating action button

        fabButton.backgroundColor = Theme.UnlockView.flaotingActionButtonTintColor
        fabButton.addTarget(self, action: #selector(didTapFloatingActionButton(sender:)), for: .touchUpInside)
        fabButton.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(fabButton)
        NSLayoutConstraint(item: fabButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 60.0).isActive = true
        NSLayoutConstraint(item: fabButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 60.0).isActive = true
        NSLayoutConstraint(item: fabButton, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: -20.0).isActive = true

        fabButtonBottomConstraint = NSLayoutConstraint(item: fabButton, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: -20.0)
        fabButtonBottomConstraint.isActive = true

        // Notifications

        NotificationCenter.default.addObserver(self, selector: #selector(willShowKeyboard(notification:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willHideKeyboard(notification:)), name: .UIKeyboardWillHide, object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        Vault.close()
    }

    override func willShowKeyboard(notification: Notification) {
        super.willShowKeyboard(notification: notification)

        if let userInfo = notification.userInfo {
            let keyboardSize = userInfo[UIKeyboardFrameBeginUserInfoKey] as! CGRect
            fabButtonBottomConstraint.constant = -keyboardSize.height - 20.0

            if UIDevice.current.orientation.isLandscape {
                scrollView.contentOffset = CGPoint(x: 0.0, y: max(passwordTextField.frame.origin.y - 35.0, 0.0))
            }

            let keyboardAnimationDuration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as! Double
            UIView.animate(withDuration: keyboardAnimationDuration, animations: {
                self.view.layoutIfNeeded()
            })
        }
    }

    override func willHideKeyboard(notification: Notification) {
        super.willHideKeyboard(notification: notification)

        if let userInfo = notification.userInfo {
            fabButtonBottomConstraint.constant = -20.0

            let keyboardAnimationDuration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as! Double
            UIView.animate(withDuration: keyboardAnimationDuration, animations: {
                self.view.layoutIfNeeded()
            })
        }
    }

    func didChangeTextField(sender: UITextField) {
        if sender === passwordTextField {
            passwordTextField.isErrorRevealed = false
        }
    }

    func didTapFloatingActionButton(sender: UIButton) {
        submit()
    }

    func submit() {
        if let url = Bundle.main.url(forResource: "Passwords", withExtension: "kdbx") {
            do {
                let data = try Data(contentsOf: url)
                let password = passwordTextField.text ?? ""

                passwordTextField.text = ""

                SVProgressHUD.show(withStatus: "Opening")
                DispatchQueue.global(qos: .background).async {
                    do {
                        let kdbx = try Vault.open(data: data, password: password)

                        DispatchQueue.main.async {
                            let groupViewController = GroupViewController(group: kdbx.database.root.group)
                            self.navigationController?.pushViewController(groupViewController, animated: true)
                        }
                    } catch {
                        DispatchQueue.main.async {
                            self.passwordTextField.detail = "Incorrect password."
                            self.passwordTextField.isErrorRevealed = true
                        }
                    }

                    SVProgressHUD.dismiss()
                }
            } catch {
                print("\(error)")
            }
        }
    }

    // MARK: UITextFieldDelegate

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        submit()
        return true
    }
}
