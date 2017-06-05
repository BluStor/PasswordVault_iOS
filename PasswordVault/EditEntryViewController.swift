//
//  EditEntryViewController.swift
//  PasswordVault
//

import Material
import SVProgressHUD

class EditEntryViewController: UITableViewController, IconPickerViewControllerDelegate, PasswordGeneratorViewControllerDelegate {

    weak var groupDelegate: GroupViewControllerDelegate?

    var entry: KdbxXml.Entry

    let saveButton = IconButton(title: "Save", titleColor: .white)
    let iconImageView = UIImageView()
    let titleTextField = ErrorTextField()
    let usernameTextField = ErrorTextField()
    let passwordTextField = ErrorTextField()
    let copyButton = RaisedButton()
    let generateButton = RaisedButton()
    let urlTextField = ErrorTextField()
    let notesTextField = ErrorTextField()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(entry: KdbxXml.Entry) {
        self.entry = entry

        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = Theme.Base.viewBackgroundColor

        navigationItem.title = "Edit entry"
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

        // Icon image view

        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false

        // Title text view

        titleTextField.placeholder = "Title"
        titleTextField.autocapitalizationType = .sentences
        titleTextField.autocorrectionType = .no
        titleTextField.addTarget(self, action: #selector(editingChanged(sender:)), for: .editingChanged)
        titleTextField.translatesAutoresizingMaskIntoConstraints = false

        // Title text view

        usernameTextField.placeholder = "Username"
        usernameTextField.autocapitalizationType = .none
        usernameTextField.autocorrectionType = .no
        usernameTextField.addTarget(self, action: #selector(editingChanged(sender:)), for: .editingChanged)
        usernameTextField.translatesAutoresizingMaskIntoConstraints = false

        // Password text view

        passwordTextField.placeholder = "Password"
        passwordTextField.isSecureTextEntry = true
        passwordTextField.autocapitalizationType = .none
        passwordTextField.autocorrectionType = .no
        passwordTextField.addTarget(self, action: #selector(editingChanged(sender:)), for: .editingChanged)
        passwordTextField.isVisibilityIconButtonEnabled = true
        passwordTextField.translatesAutoresizingMaskIntoConstraints = false

        // Copy button

        copyButton.setTitle("Copy", for: .normal)
        copyButton.pulseColor = UIColor.white
        copyButton.backgroundColor = UIColor(hex: 0x00BCD4)
        copyButton.addTarget(self, action: #selector(didTouchUpInside(sender:)), for: .touchUpInside)
        copyButton.translatesAutoresizingMaskIntoConstraints = false

        // Generate button

        generateButton.setTitle("Generate", for: .normal)
        generateButton.pulseColor = UIColor.white
        generateButton.backgroundColor = UIColor(hex: 0xEAEAEA)
        generateButton.setTitleColor(UIColor(hex: 0x999999), for: .normal)
        generateButton.addTarget(self, action: #selector(didTouchUpInside(sender:)), for: .touchUpInside)
        generateButton.translatesAutoresizingMaskIntoConstraints = false

        // URL text view

        urlTextField.placeholder = "URL"
        urlTextField.autocapitalizationType = .none
        urlTextField.autocorrectionType = .no
        urlTextField.addTarget(self, action: #selector(editingChanged(sender:)), for: .editingChanged)
        urlTextField.translatesAutoresizingMaskIntoConstraints = false

        // Notes text view

        notesTextField.placeholder = "Notes"
        notesTextField.autocapitalizationType = .sentences
        notesTextField.autocorrectionType = .no
        notesTextField.addTarget(self, action: #selector(editingChanged(sender:)), for: .editingChanged)
        notesTextField.translatesAutoresizingMaskIntoConstraints = false

        // Data

        reloadData()
    }

    override func viewWillDisappear(_ animated: Bool) {
        groupDelegate?.reloadData()
    }

    func didTouchUpInside(sender: UIView) {
        switch sender {
        case copyButton:
            UIPasteboard.general.string = passwordTextField.text
            SVProgressHUD.showSuccess(withStatus: "Password copied")
        case generateButton:
            let passwordGeneratorViewController = PasswordGeneratorViewController()
            passwordGeneratorViewController.delegate = self
            navigationController?.pushViewController(passwordGeneratorViewController, animated: true)
        case saveButton:
            save()
        default:
            break
        }
    }

    func editingChanged(sender: UIView) {
        switch sender {
        case titleTextField:
            entry.setStr(key: "Title", value: titleTextField.text ?? "", isProtected: false)
            titleTextField.isErrorRevealed = false
        case usernameTextField:
            entry.setStr(key: "UserName", value: usernameTextField.text ?? "", isProtected: false)
        case passwordTextField:
            entry.setStr(key: "Password", value: passwordTextField.text ?? "", isProtected: false)
        case urlTextField:
            entry.setStr(key: "Url", value: urlTextField.text ?? "", isProtected: false)
        case notesTextField:
            entry.setStr(key: "Notes", value: notesTextField.text ?? "", isProtected: false)
        default:
            break
        }
    }

    func reloadData() {
        let iconName = String(format: "%02d", entry.iconId)
        let iconImage = UIImage(named: iconName)?.tint(with: UIColor(hex: 0xDADADA))
        iconImageView.image = iconImage

        titleTextField.text = entry.getStr(key: "Title")?.value
        usernameTextField.text = entry.getStr(key: "UserName")?.value
        passwordTextField.text = entry.getStr(key: "Password")?.value
        urlTextField.text = entry.getStr(key: "Url")?.value
        notesTextField.text = entry.getStr(key: "Notes")?.value
    }

    func save() {
        if validate() {
            guard let kdbx = Vault.kdbx else {
                return
            }

            kdbx.update(entry: entry)
            Vault.save()

            navigationController?.popViewController(animated: true)
        }
    }

    func validate() -> Bool {
        let title = titleTextField.text ?? ""

        var hasError = false

        if title.characters.count == 0 {
            titleTextField.detail = "This field is required."
            titleTextField.isErrorRevealed = true
            hasError = true
        } else {
            titleTextField.isErrorRevealed = false
        }

        return !hasError
    }

    // MARK: IconPickerViewControllerDelegate

    func setIconId(_ iconId: Int) {
        entry.iconId = iconId
        reloadData()
    }

    // MARK: PasswordGeneratorViewControllerDelegate

    func setPassword(_ password: String) {
        entry.setStr(key: "Password", value: password, isProtected: false)
        reloadData()
    }

    // MARK: UITableViewDataSource

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.selectionStyle = .none

        switch indexPath.row {
        case 0:
            cell.contentView.addSubview(iconImageView)
            NSLayoutConstraint(item: iconImageView, attribute: .width, relatedBy: .lessThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 100.0).isActive = true
            NSLayoutConstraint(item: iconImageView, attribute: .width, relatedBy: .equal, toItem: iconImageView, attribute: .height, multiplier: 1.0, constant: 0.0).isActive = true
            NSLayoutConstraint(item: iconImageView, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 10.0).isActive = true
            NSLayoutConstraint(item: iconImageView, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: -10.0).isActive = true
            NSLayoutConstraint(item: iconImageView, attribute: .centerX, relatedBy: .equal, toItem: cell.contentView, attribute: .centerX, multiplier: 1.0, constant: 0.0).isActive = true
        case 1:
            cell.contentView.addSubview(titleTextField)
            NSLayoutConstraint(item: titleTextField, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 25.0).isActive = true
            NSLayoutConstraint(item: titleTextField, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: -10.0).isActive = true
            NSLayoutConstraint(item: titleTextField, attribute: .left, relatedBy: .equal, toItem: cell.contentView, attribute: .left, multiplier: 1.0, constant: 10.0).isActive = true
            NSLayoutConstraint(item: titleTextField, attribute: .right, relatedBy: .equal, toItem: cell.contentView, attribute: .right, multiplier: 1.0, constant: -10.0).isActive = true
        case 2:
            cell.contentView.addSubview(usernameTextField)
            NSLayoutConstraint(item: usernameTextField, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 20.0).isActive = true
            NSLayoutConstraint(item: usernameTextField, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: -10.0).isActive = true
            NSLayoutConstraint(item: usernameTextField, attribute: .left, relatedBy: .equal, toItem: cell.contentView, attribute: .left, multiplier: 1.0, constant: 10.0).isActive = true
            NSLayoutConstraint(item: usernameTextField, attribute: .right, relatedBy: .equal, toItem: cell.contentView, attribute: .right, multiplier: 1.0, constant: -10.0).isActive = true
        case 3:
            cell.contentView.addSubview(passwordTextField)
            NSLayoutConstraint(item: passwordTextField, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 20.0).isActive = true
            NSLayoutConstraint(item: passwordTextField, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: -10.0).isActive = true
            NSLayoutConstraint(item: passwordTextField, attribute: .left, relatedBy: .equal, toItem: cell.contentView, attribute: .left, multiplier: 1.0, constant: 10.0).isActive = true
            NSLayoutConstraint(item: passwordTextField, attribute: .right, relatedBy: .equal, toItem: cell.contentView, attribute: .right, multiplier: 1.0, constant: -10.0).isActive = true
        case 4:
            cell.contentView.addSubview(copyButton)
            NSLayoutConstraint(item: copyButton, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 10.0).isActive = true
            NSLayoutConstraint(item: copyButton, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: -10.0).isActive = true
            NSLayoutConstraint(item: copyButton, attribute: .left, relatedBy: .equal, toItem: cell.contentView, attribute: .left, multiplier: 1.0, constant: 10.0).isActive = true
            NSLayoutConstraint(item: copyButton, attribute: .right, relatedBy: .equal, toItem: cell.contentView, attribute: .right, multiplier: 1.0, constant: -10.0).isActive = true
        case 5:
            cell.contentView.addSubview(generateButton)
            NSLayoutConstraint(item: generateButton, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 10.0).isActive = true
            NSLayoutConstraint(item: generateButton, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: -10.0).isActive = true
            NSLayoutConstraint(item: generateButton, attribute: .left, relatedBy: .equal, toItem: cell.contentView, attribute: .left, multiplier: 1.0, constant: 10.0).isActive = true
            NSLayoutConstraint(item: generateButton, attribute: .right, relatedBy: .equal, toItem: cell.contentView, attribute: .right, multiplier: 1.0, constant: -10.0).isActive = true
        case 6:
            cell.contentView.addSubview(urlTextField)
            NSLayoutConstraint(item: urlTextField, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 20.0).isActive = true
            NSLayoutConstraint(item: urlTextField, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: -10.0).isActive = true
            NSLayoutConstraint(item: urlTextField, attribute: .left, relatedBy: .equal, toItem: cell.contentView, attribute: .left, multiplier: 1.0, constant: 10.0).isActive = true
            NSLayoutConstraint(item: urlTextField, attribute: .right, relatedBy: .equal, toItem: cell.contentView, attribute: .right, multiplier: 1.0, constant: -10.0).isActive = true
        case 7:
            cell.contentView.addSubview(notesTextField)
            NSLayoutConstraint(item: notesTextField, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 20.0).isActive = true
            NSLayoutConstraint(item: notesTextField, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: -10.0).isActive = true
            NSLayoutConstraint(item: notesTextField, attribute: .left, relatedBy: .equal, toItem: cell.contentView, attribute: .left, multiplier: 1.0, constant: 10.0).isActive = true
            NSLayoutConstraint(item: notesTextField, attribute: .right, relatedBy: .equal, toItem: cell.contentView, attribute: .right, multiplier: 1.0, constant: -10.0).isActive = true
        default:
            break
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 9
    }

    // MARK: UITableViewControllerDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            let iconPickerViewController = IconPickerViewController(tintColor: UIColor(hex: 0xDADADA))
            iconPickerViewController.delegate = self

            navigationController?.pushViewController(iconPickerViewController, animated: true)
        default:
            break
        }
    }
}
