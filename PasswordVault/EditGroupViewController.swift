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
    let nameTextField = TextField()

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

    override func viewWillDisappear(_ animated: Bool) {
        groupDelegate?.reloadData()
    }

    func didTouchUpInside(sender: IconButton) {
        switch sender {
        case saveButton:
            save()
        default:
            break
        }
    }

    func reloadData() {
        let iconName = String(format: "%02d", group.iconId)
        let iconImage = UIImage(named: iconName)?.tint(with: UIColor(hex: 0xDADADA))
        iconImageView.image = iconImage

        nameTextField.text = group.name
    }

    func save() {
        if validate() {
            group.name = nameTextField.text ?? ""

            if let kdbx = Vault.kdbx {
                kdbx.update(group: group)
                Vault.save()
                navigationController?.popViewController(animated: true)
            }
        }
    }

    func validate() -> Bool {
        let name = nameTextField.text ?? ""
        return name.characters.count > 0
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
            // Name text view

            nameTextField.placeholder = "Title"
            nameTextField.autocapitalizationType = .sentences
            nameTextField.autocorrectionType = .no
            nameTextField.translatesAutoresizingMaskIntoConstraints = false

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
