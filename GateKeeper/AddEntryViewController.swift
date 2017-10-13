//
//  AddEntryViewController.swift
//  GateKeeper
//

import Material
import PKHUD

class AddEntryViewController: UITableViewController, IconPickerViewControllerDelegate, PasswordGeneratorViewControllerDelegate, UITextViewDelegate {

    weak var groupDelegate: GroupViewControllerDelegate?

    var entry: KdbxXml.Entry

    let groupUUID: UUID
    let saveButton = IconButton(title: "Save", titleColor: .white)
    let iconImageView = UIImageView()
    let titleTextField = ErrorTextField()
    let usernameTextField = ErrorTextField()
    let passwordTextField = ErrorTextField()
    let copyButton = RaisedButton()
    let generateButton = RaisedButton()
    let urlTextField = ErrorTextField()
    let notesTextView = TextView()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(groupUUID: UUID) {
        self.groupUUID = groupUUID

        let now = Date()
        let times = KdbxXml.Times(lastModificationTime: now, creationTime: now, lastAccessTime: now, expiryTime: nil, expires: false, usageCount: 0, locationChanged: nil)
        let association = KdbxXml.Association(window: "Target Window", keystrokeSequence: "{USERNAME}{TAB}{PASSWORD}{TAB}{ENTER}")
        let autoType = KdbxXml.AutoType(enabled: false, dataTransferObfuscation: 0, association: association)

        let title = KdbxXml.Str(key: "Title", value: "", isProtected: false)
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
        view.backgroundColor = Theme.Base.viewBackgroundColor

        title = "Add entry"
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

        // Icon image view

        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false

        // Title text view

        titleTextField.placeholder = "Title"
        titleTextField.autocapitalizationType = .sentences
        titleTextField.autocorrectionType = .no
        titleTextField.addTarget(self, action: #selector(editingChanged(sender:)), for: .editingChanged)
        titleTextField.isPlaceholderAnimated = false
        titleTextField.translatesAutoresizingMaskIntoConstraints = false

        // Username text view

        usernameTextField.placeholder = "Username"
        usernameTextField.autocapitalizationType = .none
        usernameTextField.autocorrectionType = .no
        usernameTextField.addTarget(self, action: #selector(editingChanged(sender:)), for: .editingChanged)
        usernameTextField.isPlaceholderAnimated = false
        usernameTextField.translatesAutoresizingMaskIntoConstraints = false

        // Password text view

        passwordTextField.placeholder = "Password"
        passwordTextField.isSecureTextEntry = true
        passwordTextField.autocapitalizationType = .none
        passwordTextField.autocorrectionType = .no
        passwordTextField.addTarget(self, action: #selector(editingChanged(sender:)), for: .editingChanged)
        passwordTextField.isVisibilityIconButtonEnabled = true
        passwordTextField.isPlaceholderAnimated = false
        passwordTextField.translatesAutoresizingMaskIntoConstraints = false

        // Copy button

        copyButton.setTitle("Copy", for: .normal)
        copyButton.pulseColor = UIColor.white
        copyButton.backgroundColor = Theme.Buttons.normalBackgroundColor
        copyButton.addTarget(self, action: #selector(didTouchUpInside(sender:)), for: .touchUpInside)
        copyButton.translatesAutoresizingMaskIntoConstraints = false

        // Generate button

        generateButton.setTitle("Generate", for: .normal)
        generateButton.pulseColor = UIColor.white
        generateButton.backgroundColor = Theme.Buttons.mutedBackgroundColor
        generateButton.setTitleColor(Theme.Buttons.mutedTitleColor, for: .normal)
        generateButton.addTarget(self, action: #selector(didTouchUpInside(sender:)), for: .touchUpInside)
        generateButton.translatesAutoresizingMaskIntoConstraints = false

        // URL text view

        urlTextField.placeholder = "URL"
        urlTextField.autocapitalizationType = .none
        urlTextField.autocorrectionType = .no
        urlTextField.addTarget(self, action: #selector(editingChanged(sender:)), for: .editingChanged)
        urlTextField.isPlaceholderAnimated = false
        urlTextField.translatesAutoresizingMaskIntoConstraints = false

        // Notes text view

        notesTextView.delegate = self
        notesTextView.placeholder = "Notes"
        notesTextView.autocapitalizationType = .sentences
        notesTextView.textContainerInsets = UIEdgeInsets(top: 5.0, left: 5.0, bottom: 5.0, right: 5.0)
        notesTextView.layer.borderWidth = 1.0
        notesTextView.layer.borderColor = UIColor(hex: 0xEAEAEA).cgColor
        notesTextView.layer.cornerRadius = 10.0
        notesTextView.translatesAutoresizingMaskIntoConstraints = false

        // Load

        reloadData()
    }

    @objc func didTouchUpInside(sender: UIView) {
        switch sender {
        case copyButton:
            UIPasteboard.general.string = passwordTextField.text
            
            HUD.show(.labeledSuccess(title: "Password copied", subtitle: nil))
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

    @objc func editingChanged(sender: UIView) {
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
        notesTextView.text = entry.getStr(key: "Notes")?.value
    }

    func save() {
        if validate() {
            guard let kdbx = Vault.kdbx else {
                return
            }

            kdbx.add(groupUUID: groupUUID, entry: entry)
            Vault.save()

            groupDelegate?.reloadData()
            navigationController?.popViewController(animated: true)
        }
    }

    func scrollToFirstError() {
        if titleTextField.isErrorRevealed {
            tableView.scrollToRow(at: IndexPath(row: 1, section: 0), at: .top, animated: true)
        }
    }

    func validate() -> Bool {
        let title = entry.getStr(key: "Title")?.value ?? ""

        let hasTitle = title.characters.count > 0

        if hasTitle {
            titleTextField.isErrorRevealed = false
        } else {
            titleTextField.detail = "This field is required."
            titleTextField.isErrorRevealed = true
        }

        scrollToFirstError()

        return hasTitle
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
            NSLayoutConstraint(item: titleTextField, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: -25.0).isActive = true
            NSLayoutConstraint(item: titleTextField, attribute: .left, relatedBy: .equal, toItem: cell.contentView, attribute: .left, multiplier: 1.0, constant: 10.0).isActive = true
            NSLayoutConstraint(item: titleTextField, attribute: .right, relatedBy: .equal, toItem: cell.contentView, attribute: .right, multiplier: 1.0, constant: -10.0).isActive = true
        case 2:
            cell.contentView.addSubview(usernameTextField)
            NSLayoutConstraint(item: usernameTextField, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 25.0).isActive = true
            NSLayoutConstraint(item: usernameTextField, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: -25.0).isActive = true
            NSLayoutConstraint(item: usernameTextField, attribute: .left, relatedBy: .equal, toItem: cell.contentView, attribute: .left, multiplier: 1.0, constant: 10.0).isActive = true
            NSLayoutConstraint(item: usernameTextField, attribute: .right, relatedBy: .equal, toItem: cell.contentView, attribute: .right, multiplier: 1.0, constant: -10.0).isActive = true
        case 3:
            cell.contentView.addSubview(passwordTextField)
            NSLayoutConstraint(item: passwordTextField, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 25.0).isActive = true
            NSLayoutConstraint(item: passwordTextField, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: -25.0).isActive = true
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
            NSLayoutConstraint(item: urlTextField, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 25.0).isActive = true
            NSLayoutConstraint(item: urlTextField, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: -25.0).isActive = true
            NSLayoutConstraint(item: urlTextField, attribute: .left, relatedBy: .equal, toItem: cell.contentView, attribute: .left, multiplier: 1.0, constant: 10.0).isActive = true
            NSLayoutConstraint(item: urlTextField, attribute: .right, relatedBy: .equal, toItem: cell.contentView, attribute: .right, multiplier: 1.0, constant: -10.0).isActive = true
        case 7:
            cell.contentView.addSubview(notesTextView)
            NSLayoutConstraint(item: notesTextView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 80.0).isActive = true
            NSLayoutConstraint(item: notesTextView, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 10.0).isActive = true
            NSLayoutConstraint(item: notesTextView, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: -10.0).isActive = true
            NSLayoutConstraint(item: notesTextView, attribute: .left, relatedBy: .equal, toItem: cell.contentView, attribute: .left, multiplier: 1.0, constant: 10.0).isActive = true
            NSLayoutConstraint(item: notesTextView, attribute: .right, relatedBy: .equal, toItem: cell.contentView, attribute: .right, multiplier: 1.0, constant: -10.0).isActive = true
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
        default:
            break
        }
    }

    // MARK: UITextViewDelegate

    func textViewDidChange(_ textView: UITextView) {
        switch textView {
        case notesTextView:
            entry.setStr(key: "Notes", value: notesTextView.text ?? "", isProtected: false)
        default:
            break
        }
    }
}
