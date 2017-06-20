//
//  EditGroupViewController.swift
//  PasswordVault
//

import Material

class EditGroupViewController: UITableViewController, IconPickerViewControllerDelegate {

    weak var groupDelegate: GroupViewControllerDelegate?

    var group: KdbxXml.Group

    let saveButton = IconButton(title: "Save", titleColor: .white)

    let iconImageView = UIImageView()
    let nameTextField = ErrorTextField()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(group: KdbxXml.Group) {
        self.group = group

        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = Theme.Base.viewBackgroundColor

        navigationItem.title = "Edit group"
        navigationItem.backButton.tintColor = .white
        navigationItem.titleLabel.textColor = .white
        navigationItem.detailLabel.textColor = .white
        navigationItem.rightViews = [saveButton]

        // Back button

        navigationItem.backButton.removeTarget(navigationController, action: nil, for: .allEvents)

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

        // Name text view

        nameTextField.placeholder = "Title"
        nameTextField.autocapitalizationType = .sentences
        nameTextField.autocorrectionType = .no
        nameTextField.addTarget(self, action: #selector(editingChanged(sender:)), for: .editingChanged)
        nameTextField.translatesAutoresizingMaskIntoConstraints = false

        // Data

        reloadData()
    }

    func didTouchUpInside(sender: UIView) {
        switch sender {
        case navigationItem.backButton:
            print("touchUpInside")
        case saveButton:
            save()
        default:
            break
        }
    }

    func editingChanged(sender: UIView) {
        switch sender {
        case nameTextField:
            group.name = nameTextField.text ?? ""
        default:
            break
        }
    }

    func reloadData() {
        let iconName = String(format: "%02d", group.iconId)
        let iconImage = UIImage(named: iconName)?.tint(with: UIColor(hex: 0xFFCC80))
        iconImageView.image = iconImage

        nameTextField.text = group.name
    }

    func save() {
        if validate() {
            if hasChanged() {
                guard let kdbx = Vault.kdbx else {
                    return
                }

                kdbx.update(group: group)
                Vault.save()
            }

            groupDelegate?.reloadData()
            navigationController?.popViewController(animated: true)
        }
    }

    func hasChanged() -> Bool {
        guard let oldGroup = Vault.kdbx?.get(groupUUID: group.uuid) else {
            return false
        }

        let name = nameTextField.text ?? ""

        return oldGroup.iconId != group.iconId
            ||  oldGroup.name != name
    }

    func validate() -> Bool {
        let name = nameTextField.text ?? ""

        var hasError = false

        if name.characters.count == 0 {
            nameTextField.detail = "This field is required."
            nameTextField.isErrorRevealed = true
            hasError = true
        } else {
            nameTextField.isErrorRevealed = false
        }

        return !hasError
    }

    // MARK: IconPickerViewControllerDelegate

    func setIconId(_ iconId: Int) {
        group.iconId = iconId
        reloadData()
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
            let iconWidth = UIScreen.main.bounds.width / 2

            cell.contentView.addSubview(iconImageView)
            NSLayoutConstraint(item: iconImageView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: iconWidth).isActive = true
            NSLayoutConstraint(item: iconImageView, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 10.0).isActive = true
            NSLayoutConstraint(item: iconImageView, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: -10.0).isActive = true
            NSLayoutConstraint(item: iconImageView, attribute: .centerX, relatedBy: .equal, toItem: cell.contentView, attribute: .centerX, multiplier: 1.0, constant: 0.0).isActive = true
        case 1:
            cell.contentView.addSubview(nameTextField)
            NSLayoutConstraint(item: nameTextField, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 25.0).isActive = true
            NSLayoutConstraint(item: nameTextField, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: -10.0).isActive = true
            NSLayoutConstraint(item: nameTextField, attribute: .left, relatedBy: .equal, toItem: cell.contentView, attribute: .left, multiplier: 1.0, constant: 10.0).isActive = true
            NSLayoutConstraint(item: nameTextField, attribute: .right, relatedBy: .equal, toItem: cell.contentView, attribute: .right, multiplier: 1.0, constant: -10.0).isActive = true
        default:
            break
        }

        return cell
    }

    // MARK: UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            let iconPickerViewController = IconPickerViewController(tintColor: UIColor(hex: 0xFFCC80))
            iconPickerViewController.delegate = self

            navigationController?.pushViewController(iconPickerViewController, animated: true)
        default:
            break
        }
    }
}
