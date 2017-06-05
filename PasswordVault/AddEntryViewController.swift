//
//  AddEntryViewController.swift
//  PasswordVault
//

import Material

class AddEntryViewController: UITableViewController, IconPickerViewControllerDelegate, PasswordGeneratorViewControllerDelegate {

    weak var groupDelegate: GroupViewControllerDelegate?

    var entry: KdbxXml.Entry

    let groupUUID: UUID
    let saveButton = IconButton(title: "Save", titleColor: .white)
    let iconImageView = UIImageView()
    let titleTextField = TextField()
    let usernameTextField = TextField()
    let passwordTextField = TextField()
    let unmaskSwitch = Switch()
    let generateButton = RaisedButton()
    let urlTextField = TextField()
    let notesTextField = TextField()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(groupUUID: UUID) {
        self.groupUUID = groupUUID

        let now = Date()
        let times = KdbxXml.Times(lastModificationTime: now, creationTime: now, lastAccessTime: now, expiryTime: nil, expires: false, usageCount: 0, locationChanged: nil)
        let association = KdbxXml.Association(window: "Target Window", keystrokeSequence: "{USERNAME}{TAB}{PASSWORD}{TAB}{ENTER}")
        let autoType = KdbxXml.AutoType(enabled: false, dataTransferObfuscation: 0, association: association)

        let title = KdbxXml.Str(key: "Title", value: "Untitled", isProtected: false)
        let username = KdbxXml.Str(key: "UserName", value: "", isProtected: false)
        let password = KdbxXml.Str(key: "Password", value: "", isProtected: false)
        let url = KdbxXml.Str(key: "Url", value: "", isProtected: false)
        let notes = KdbxXml.Str(key: "Notes", value: "", isProtected: false)

        entry = KdbxXml.Entry(
            uuid: UUID(),
            iconId: 0,
            foregroundColor: "",
            backgroundColor: "",
            overrideURL: "",
            tags: "",
            times: times,
            autoType: autoType,
            strings: [title, username, password, url, notes],
            histories: []
        )

        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = Theme.Base.viewBackgroundColor

        navigationItem.title = "Add entry"
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

        // Data

        reloadData()
    }

    func didChangeEditing(sender: UIView) {
        switch sender {
        case titleTextField:
            entry.setStr(key: "Title", value: titleTextField.text ?? "", isProtected: false)
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

    func didChangeValue(sender: UIView) {
        switch sender {
        case unmaskSwitch:
            passwordTextField.isSecureTextEntry = !unmaskSwitch.isOn
        default:
            break
        }
    }

    func didTouchUpInside(sender: UIView) {
        switch sender {
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
        if let kdbx = Vault.kdbx {
            kdbx.add(groupUUID: groupUUID, entry: entry)
            Vault.save()
        }

        groupDelegate?.reloadData()
        navigationController?.popViewController(animated: true)
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
            // Icon image view

            iconImageView.contentMode = .scaleAspectFit
            iconImageView.translatesAutoresizingMaskIntoConstraints = false

            cell.contentView.addSubview(iconImageView)
            NSLayoutConstraint(item: iconImageView, attribute: .width, relatedBy: .lessThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 100.0).isActive = true
            NSLayoutConstraint(item: iconImageView, attribute: .width, relatedBy: .equal, toItem: iconImageView, attribute: .height, multiplier: 1.0, constant: 0.0).isActive = true
            NSLayoutConstraint(item: iconImageView, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 10.0).isActive = true
            NSLayoutConstraint(item: iconImageView, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: -10.0).isActive = true
            NSLayoutConstraint(item: iconImageView, attribute: .centerX, relatedBy: .equal, toItem: cell.contentView, attribute: .centerX, multiplier: 1.0, constant: 0.0).isActive = true
        case 1:
            // Title text view

            titleTextField.placeholder = "Title"
            titleTextField.autocapitalizationType = .sentences
            titleTextField.autocorrectionType = .no
            titleTextField.addTarget(self, action: #selector(didChangeEditing(sender:)), for: .editingChanged)
            titleTextField.translatesAutoresizingMaskIntoConstraints = false

            cell.contentView.addSubview(titleTextField)
            NSLayoutConstraint(item: titleTextField, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 25.0).isActive = true
            NSLayoutConstraint(item: titleTextField, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: -10.0).isActive = true
            NSLayoutConstraint(item: titleTextField, attribute: .left, relatedBy: .equal, toItem: cell.contentView, attribute: .left, multiplier: 1.0, constant: 10.0).isActive = true
            NSLayoutConstraint(item: titleTextField, attribute: .right, relatedBy: .equal, toItem: cell.contentView, attribute: .right, multiplier: 1.0, constant: -10.0).isActive = true
        case 2:
            // Title text view

            usernameTextField.placeholder = "Username"
            usernameTextField.autocapitalizationType = .none
            usernameTextField.autocorrectionType = .no
            usernameTextField.addTarget(self, action: #selector(didChangeEditing(sender:)), for: .editingChanged)
            usernameTextField.translatesAutoresizingMaskIntoConstraints = false

            cell.contentView.addSubview(usernameTextField)
            NSLayoutConstraint(item: usernameTextField, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 20.0).isActive = true
            NSLayoutConstraint(item: usernameTextField, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: -10.0).isActive = true
            NSLayoutConstraint(item: usernameTextField, attribute: .left, relatedBy: .equal, toItem: cell.contentView, attribute: .left, multiplier: 1.0, constant: 10.0).isActive = true
            NSLayoutConstraint(item: usernameTextField, attribute: .right, relatedBy: .equal, toItem: cell.contentView, attribute: .right, multiplier: 1.0, constant: -10.0).isActive = true
        case 3:
            // Password text view

            passwordTextField.detailLabel.layer.borderWidth = 1.0
            passwordTextField.detailLabel.layer.borderColor = UIColor.random().cgColor
            passwordTextField.placeholder = "Password"
            passwordTextField.isSecureTextEntry = true
            passwordTextField.autocapitalizationType = .none
            passwordTextField.autocorrectionType = .no
            passwordTextField.addTarget(self, action: #selector(didChangeEditing(sender:)), for: .editingChanged)
            passwordTextField.translatesAutoresizingMaskIntoConstraints = false

            cell.contentView.addSubview(passwordTextField)
            NSLayoutConstraint(item: passwordTextField, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 20.0).isActive = true
            NSLayoutConstraint(item: passwordTextField, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: -10.0).isActive = true
            NSLayoutConstraint(item: passwordTextField, attribute: .left, relatedBy: .equal, toItem: cell.contentView, attribute: .left, multiplier: 1.0, constant: 10.0).isActive = true
            NSLayoutConstraint(item: passwordTextField, attribute: .right, relatedBy: .equal, toItem: cell.contentView, attribute: .right, multiplier: 1.0, constant: -10.0).isActive = true
        case 4:
            // Unmask switch

            unmaskSwitch.setContentHuggingPriority(UILayoutPriorityRequired, for: .horizontal)
            unmaskSwitch.addTarget(self, action: #selector(didChangeValue(sender:)), for: .valueChanged)
            unmaskSwitch.translatesAutoresizingMaskIntoConstraints = false

            cell.contentView.addSubview(unmaskSwitch)
            NSLayoutConstraint(item: unmaskSwitch, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 10.0).isActive = true
            NSLayoutConstraint(item: unmaskSwitch, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: -10.0).isActive = true
            NSLayoutConstraint(item: unmaskSwitch, attribute: .left, relatedBy: .equal, toItem: cell.contentView, attribute: .left, multiplier: 1.0, constant: 10.0).isActive = true

            let unmaskLabel = UILabel()
            unmaskLabel.text = "Unmask password"
            unmaskLabel.textColor = UIColor(hex: 0x666666)
            unmaskLabel.font = UIFont.systemFont(ofSize: 14.0)
            unmaskLabel.translatesAutoresizingMaskIntoConstraints = false

            cell.contentView.addSubview(unmaskLabel)
            NSLayoutConstraint(item: unmaskLabel, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 10.0).isActive = true
            NSLayoutConstraint(item: unmaskLabel, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: -10.0).isActive = true
            NSLayoutConstraint(item: unmaskLabel, attribute: .left, relatedBy: .equal, toItem: unmaskSwitch, attribute: .right, multiplier: 1.0, constant: 15.0).isActive = true
            NSLayoutConstraint(item: unmaskLabel, attribute: .right, relatedBy: .equal, toItem: cell.contentView, attribute: .right, multiplier: 1.0, constant: -10.0).isActive = true
        case 5:
            // Generate button

            generateButton.setTitle("Generate", for: .normal)
            generateButton.pulseColor = UIColor.white
            generateButton.backgroundColor = UIColor(hex: 0xEAEAEA)
            generateButton.setTitleColor(UIColor(hex: 0x999999), for: .normal)
            generateButton.addTarget(self, action: #selector(didTouchUpInside(sender:)), for: .touchUpInside)
            generateButton.translatesAutoresizingMaskIntoConstraints = false

            cell.contentView.addSubview(generateButton)
            NSLayoutConstraint(item: generateButton, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 10.0).isActive = true
            NSLayoutConstraint(item: generateButton, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: -10.0).isActive = true
            NSLayoutConstraint(item: generateButton, attribute: .left, relatedBy: .equal, toItem: cell.contentView, attribute: .left, multiplier: 1.0, constant: 10.0).isActive = true
            NSLayoutConstraint(item: generateButton, attribute: .right, relatedBy: .equal, toItem: cell.contentView, attribute: .right, multiplier: 1.0, constant: -10.0).isActive = true
        case 6:
            // URL text view

            urlTextField.placeholder = "URL"
            urlTextField.autocapitalizationType = .none
            urlTextField.autocorrectionType = .no
            urlTextField.addTarget(self, action: #selector(didChangeEditing(sender:)), for: .editingChanged)
            urlTextField.translatesAutoresizingMaskIntoConstraints = false

            cell.contentView.addSubview(urlTextField)
            NSLayoutConstraint(item: urlTextField, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 20.0).isActive = true
            NSLayoutConstraint(item: urlTextField, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: -10.0).isActive = true
            NSLayoutConstraint(item: urlTextField, attribute: .left, relatedBy: .equal, toItem: cell.contentView, attribute: .left, multiplier: 1.0, constant: 10.0).isActive = true
            NSLayoutConstraint(item: urlTextField, attribute: .right, relatedBy: .equal, toItem: cell.contentView, attribute: .right, multiplier: 1.0, constant: -10.0).isActive = true
        case 7:
            // Notes text view

            notesTextField.placeholder = "Notes"
            notesTextField.autocapitalizationType = .sentences
            notesTextField.autocorrectionType = .no
            notesTextField.addTarget(self, action: #selector(didChangeEditing(sender:)), for: .editingChanged)
            notesTextField.translatesAutoresizingMaskIntoConstraints = false

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
        return 8
    }

    // MARK: UITableViewControllerDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            let iconPickerViewController = IconPickerViewController(tintColor: UIColor(hex: 0xDADADA))
            iconPickerViewController.delegate = self

            navigationController?.pushViewController(iconPickerViewController, animated: true)
        case 4:
            unmaskSwitch.toggle()
            passwordTextField.isSecureTextEntry = !unmaskSwitch.isOn
        default:
            break
        }
    }
}
