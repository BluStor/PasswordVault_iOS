//
//  EditEntryViewController.swift
//  PasswordVault
//

import Material
import UIKit

class EditEntryViewController: UITableViewController, IconPickerViewControllerDelegate, PasswordGeneratorViewControllerDelegate {

    weak var groupDelegate: GroupViewControllerDelegate?

    var entry: KdbxXml.Entry
    let saveButton = IconButton(title: "Save", titleColor: .white)
    let iconImageView = UIImageView()
    let titleTextField = TextField()
    let usernameTextField = TextField()
    let passwordTextField = TextField()
    let generateButton = RaisedButton()
    let urlTextField = TextField()
    let notesTextField = TextField()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(entry: KdbxXml.Entry) {
        self.entry = entry

        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        navigationItem.title = "Edit entry"
        navigationItem.backButton.tintColor = .white
        navigationItem.titleLabel.textColor = .white
        navigationItem.detailLabel.textColor = .white
        navigationItem.rightViews = [saveButton]

        // Save button

        saveButton.addTarget(self, action: #selector(didTapNavigationBarButton(sender:)), for: .touchUpInside)

        // Table view

        tableView.bounces = false
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 200.0

        // Data

        reloadData()
    }

    override func viewWillDisappear(_ animated: Bool) {
        groupDelegate?.reloadData()
    }

    func didChangeTextField(sender: TextField) {
        switch sender {
        case titleTextField:
            entry.title = titleTextField.text ?? ""
        case usernameTextField:
            entry.username = usernameTextField.text ?? ""
        case passwordTextField:
            entry.password = passwordTextField.text ?? ""
        case urlTextField:
            entry.url = urlTextField.text ?? ""
        case notesTextField:
            entry.notes = notesTextField.text ?? ""
        default:
            break
        }
    }

    func didTapButton(sender: Button) {
        if sender === generateButton {
            let passwordGeneratorViewController = PasswordGeneratorViewController()
            passwordGeneratorViewController.delegate = self
            navigationController?.pushViewController(passwordGeneratorViewController, animated: true)
        }
    }

    func didTapNavigationBarButton(sender: IconButton) {
        if sender == saveButton {
            if validateEntry() {
                if let kdbx = Vault.kdbx {
                    if kdbx.update(entry: entry) {
                        navigationController?.popViewController(animated: true)
                    }
                }
            }
        }
    }

    func reloadData() {
        let iconName = String(format: "%02d", entry.iconId)
        let iconImage = UIImage(named: iconName)?.tint(with: UIColor(hex: 0xDADADA))
        iconImageView.image = iconImage

        titleTextField.text = entry.title
        usernameTextField.text = entry.username
        passwordTextField.text = entry.password
        urlTextField.text = entry.url
        notesTextField.text = entry.notes
    }

    func validateEntry() -> Bool {
        entry.title = titleTextField.text ?? ""
        entry.username = usernameTextField.text ?? ""
        entry.password = passwordTextField.text ?? ""
        entry.url = urlTextField.text ?? ""
        entry.notes = notesTextField.text ?? ""
        return true
    }

    // MARK: IconPickerViewControllerDelegate

    func setIconId(_ iconId: Int) {
        entry.iconId = iconId
        reloadData()
    }

    // MARK: PasswordGeneratorViewControllerDelegate

    func setPassword(_ password: String) {
        entry.password = password
        reloadData()
    }

    // MARK: UITableViewControllerDelegate

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 7
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.selectionStyle = .none

        switch indexPath.row {
        case 0:
            // Icon image view

            let iconWidth = UIScreen.main.bounds.width / 2

            iconImageView.contentMode = .scaleAspectFit
            iconImageView.translatesAutoresizingMaskIntoConstraints = false

            cell.contentView.addSubview(iconImageView)
            NSLayoutConstraint(item: iconImageView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: iconWidth).isActive = true
            NSLayoutConstraint(item: iconImageView, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 10.0).isActive = true
            NSLayoutConstraint(item: iconImageView, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: -10.0).isActive = true
            NSLayoutConstraint(item: iconImageView, attribute: .centerX, relatedBy: .equal, toItem: cell.contentView, attribute: .centerX, multiplier: 1.0, constant: 0.0).isActive = true
        case 1:
            // Title text view

            titleTextField.placeholder = "Title"
            titleTextField.autocapitalizationType = .sentences
            titleTextField.autocorrectionType = .no
            titleTextField.addTarget(self, action: #selector(didChangeTextField(sender:)), for: .editingChanged)
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
            usernameTextField.addTarget(self, action: #selector(didChangeTextField(sender:)), for: .editingChanged)
            usernameTextField.translatesAutoresizingMaskIntoConstraints = false

            cell.contentView.addSubview(usernameTextField)
            NSLayoutConstraint(item: usernameTextField, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 20.0).isActive = true
            NSLayoutConstraint(item: usernameTextField, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: -10.0).isActive = true
            NSLayoutConstraint(item: usernameTextField, attribute: .left, relatedBy: .equal, toItem: cell.contentView, attribute: .left, multiplier: 1.0, constant: 10.0).isActive = true
            NSLayoutConstraint(item: usernameTextField, attribute: .right, relatedBy: .equal, toItem: cell.contentView, attribute: .right, multiplier: 1.0, constant: -10.0).isActive = true
        case 3:
            // Password text view

            passwordTextField.placeholder = "Password"
            passwordTextField.isSecureTextEntry = true
            passwordTextField.autocapitalizationType = .none
            passwordTextField.autocorrectionType = .no
            passwordTextField.addTarget(self, action: #selector(didChangeTextField(sender:)), for: .editingChanged)
            passwordTextField.translatesAutoresizingMaskIntoConstraints = false

            cell.contentView.addSubview(passwordTextField)
            NSLayoutConstraint(item: passwordTextField, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 20.0).isActive = true
            NSLayoutConstraint(item: passwordTextField, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: -10.0).isActive = true
            NSLayoutConstraint(item: passwordTextField, attribute: .left, relatedBy: .equal, toItem: cell.contentView, attribute: .left, multiplier: 1.0, constant: 10.0).isActive = true
            NSLayoutConstraint(item: passwordTextField, attribute: .right, relatedBy: .equal, toItem: cell.contentView, attribute: .right, multiplier: 1.0, constant: -10.0).isActive = true
        case 4:
            // Generate button

            generateButton.setTitle("Generate", for: .normal)
            generateButton.pulseColor = UIColor.white
            generateButton.backgroundColor = UIColor(hex: 0x00BCD4)
            generateButton.addTarget(self, action: #selector(didTapButton(sender:)), for: .touchUpInside)
            generateButton.translatesAutoresizingMaskIntoConstraints = false

            cell.contentView.addSubview(generateButton)
            NSLayoutConstraint(item: generateButton, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 10.0).isActive = true
            NSLayoutConstraint(item: generateButton, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: -10.0).isActive = true
            NSLayoutConstraint(item: generateButton, attribute: .left, relatedBy: .equal, toItem: cell.contentView, attribute: .left, multiplier: 1.0, constant: 10.0).isActive = true
            NSLayoutConstraint(item: generateButton, attribute: .right, relatedBy: .equal, toItem: cell.contentView, attribute: .right, multiplier: 1.0, constant: -10.0).isActive = true
        case 5:
            // URL text view

            urlTextField.placeholder = "URL"
            urlTextField.autocapitalizationType = .none
            urlTextField.autocorrectionType = .no
            urlTextField.addTarget(self, action: #selector(didChangeTextField(sender:)), for: .editingChanged)
            urlTextField.translatesAutoresizingMaskIntoConstraints = false

            cell.contentView.addSubview(urlTextField)
            NSLayoutConstraint(item: urlTextField, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 20.0).isActive = true
            NSLayoutConstraint(item: urlTextField, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: -10.0).isActive = true
            NSLayoutConstraint(item: urlTextField, attribute: .left, relatedBy: .equal, toItem: cell.contentView, attribute: .left, multiplier: 1.0, constant: 10.0).isActive = true
            NSLayoutConstraint(item: urlTextField, attribute: .right, relatedBy: .equal, toItem: cell.contentView, attribute: .right, multiplier: 1.0, constant: -10.0).isActive = true
        case 6:
            // Notes text view

            notesTextField.placeholder = "Notes"
            notesTextField.autocapitalizationType = .sentences
            notesTextField.autocorrectionType = .no
            notesTextField.addTarget(self, action: #selector(didChangeTextField(sender:)), for: .editingChanged)
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

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            let iconPickerViewController = IconPickerViewController()
            iconPickerViewController.delegate = self

            navigationController?.pushViewController(iconPickerViewController, animated: true)
        default:
            break
        }
    }
}
