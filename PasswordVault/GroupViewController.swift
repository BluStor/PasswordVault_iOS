//
//  GroupViewController.swift
//  PasswordVault
//

import Material

protocol GroupViewControllerDelegate: NSObjectProtocol {
    func reloadData()
}

class GroupViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, GroupViewControllerDelegate {

    weak var delegate: GroupViewControllerDelegate?

    var group: KdbxXml.Group
    let moreButton = IconButton(image: Icon.moreVertical, tintColor: UIColor.white)
    let syncView = SyncView()
    let searchView = SearchView()
    let tableView = UITableView()
    let fabButton = FABButton(image: Icon.add, tintColor: .white)

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(group: KdbxXml.Group) {
        self.group = group

        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        view.backgroundColor = Theme.Base.viewBackgroundColor

        navigationItem.title = group.name
        navigationItem.backButton.tintColor = .white
        navigationItem.titleLabel.textColor = .white
        navigationItem.detailLabel.textColor = .white
        navigationItem.rightViews = [moreButton]

        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(didLongPress(longPressGestureRecognizer:)))

        // More button

        moreButton.pulseColor = UIColor(hex: 0xa0e0ff)
        moreButton.addTarget(self, action: #selector(didTouchUpInside(sender:)), for: .touchUpInside)

        // Sync view

        syncView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(syncView)
        NSLayoutConstraint(item: syncView, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: syncView, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: syncView, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: 0.0).isActive = true

        // Search view

        searchView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(searchView)
        NSLayoutConstraint(item: searchView, attribute: .top, relatedBy: .equal, toItem: syncView, attribute: .bottom, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: searchView, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: searchView, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: 0.0).isActive = true

        // Table view

        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 65.0
        tableView.separatorStyle = .none
        tableView.contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
        tableView.register(GroupTableViewCell.self, forCellReuseIdentifier: "group")
        tableView.register(EntryTableViewCell.self, forCellReuseIdentifier: "entry")
        tableView.addGestureRecognizer(longPressGestureRecognizer)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(tableView)
        NSLayoutConstraint(item: tableView, attribute: .top, relatedBy: .equal, toItem: syncView, attribute: .bottom, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: tableView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: tableView, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: tableView, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: 0.0).isActive = true

        // Floating action button

        fabButton.backgroundColor = Theme.Group.floatingActionButtonBackgroundColor
        fabButton.addTarget(self, action: #selector(didTouchUpInside(sender:)), for: .touchUpInside)
        fabButton.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(fabButton)
        NSLayoutConstraint(item: fabButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 70.0).isActive = true
        NSLayoutConstraint(item: fabButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 70.0).isActive = true
        NSLayoutConstraint(item: fabButton, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: -20.0).isActive = true
        NSLayoutConstraint(item: fabButton, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: -20.0).isActive = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        delegate?.reloadData()
    }

    func didLongPress(longPressGestureRecognizer: UILongPressGestureRecognizer) {
        guard let view = longPressGestureRecognizer.view else {
            return
        }

        switch view {
        case tableView:
            let point = longPressGestureRecognizer.location(in: tableView)

            if let indexPath = tableView.indexPathForRow(at: point) {
                if indexPath.row < group.groups.count {
                    if longPressGestureRecognizer.state == .began {
                        let selectedGroup = group.groups[indexPath.row]

                        let alertController = UIAlertController(
                            title: "Group",
                            message: selectedGroup.name,
                            preferredStyle: .actionSheet
                        )

                        alertController.addAction(UIAlertAction(title: "Edit", style: .default, handler: { _ in
                            let editGroupViewController = EditGroupViewController(group: selectedGroup)
                            editGroupViewController.groupDelegate = self
                            self.navigationController?.pushViewController(editGroupViewController, animated: true)
                        }))

                        alertController.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                            if let kdbx = Vault.kdbx {
                                kdbx.delete(groupUUID: selectedGroup.uuid)
                                self.reloadData()
                            }
                        }))

                        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                            alertController.dismiss(animated: true, completion: nil)
                        }))

                        present(alertController, animated: true, completion: nil)
                    }
                } else {
                    if longPressGestureRecognizer.state == .began {
                        let selectedEntry = group.entries[indexPath.row - group.groups.count]

                        let alertController = UIAlertController(
                            title: "Group",
                            message: selectedEntry.getStr(key: "Title")?.value,
                            preferredStyle: .actionSheet
                        )

                        alertController.addAction(UIAlertAction(title: "Edit", style: .default, handler: { _ in
                            let editEntryViewController = EditEntryViewController(entry: selectedEntry)
                            editEntryViewController.groupDelegate = self
                            self.navigationController?.pushViewController(editEntryViewController, animated: true)
                        }))

                        alertController.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                            if let kdbx = Vault.kdbx {
                                kdbx.delete(entryUUID: selectedEntry.uuid)
                                self.reloadData()
                            }
                        }))

                        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                            alertController.dismiss(animated: true, completion: nil)
                        }))

                        present(alertController, animated: true, completion: nil)
                    }
                }
            }
        default:
            break
        }
    }

    func didTouchUpInside(sender: UIView) {
        switch sender {
        case fabButton:
            let alertController = UIAlertController(title: "Add", message: nil, preferredStyle: .actionSheet)

            alertController.addAction(UIAlertAction(title: "Group", style: .default, handler: { _ in
                let addGroupViewController = AddGroupViewController(groupUUID: self.group.uuid)
                addGroupViewController.groupDelegate = self
                self.navigationController?.pushViewController(addGroupViewController, animated: true)
            }))

            alertController.addAction(UIAlertAction(title: "Entry", style: .default, handler: { _ in
                let addEntryViewController = AddEntryViewController(groupUUID: self.group.uuid)
                addEntryViewController.groupDelegate = self
                self.navigationController?.pushViewController(addEntryViewController, animated: true)
            }))

            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                alertController.dismiss(animated: true, completion: nil)
            }))

            present(alertController, animated: true, completion: nil)
        case moreButton:
            let alertController = UIAlertController(title: "Menu", message: nil, preferredStyle: .actionSheet)

            alertController.addAction(UIAlertAction(title: "Database settings", style: .default, handler: { _ in
                let databaseSettingsViewController = DatabaseSettingsViewController()
                self.navigationController?.pushViewController(databaseSettingsViewController, animated: true)
            }))

            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                alertController.dismiss(animated: true, completion: nil)
            }))

            present(alertController, animated: true, completion: nil)
        default:
            break
        }
    }

    func reloadData() {
        if let refreshedGroup = Vault.kdbx?.get(groupUUID: group.uuid) {
            group = refreshedGroup
            tableView.reloadData()
            print("reloadData()")
        } else {
            print("reloadData() failure")
        }
    }

    // MARK: UITableViewDataSource

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row < group.groups.count {
            let cellGroup = group.groups[indexPath.row]

            guard let cell = tableView.dequeueReusableCell(withIdentifier: "group", for: indexPath) as? GroupTableViewCell else {
                return UITableViewCell()
            }

            cell.titleLabel.text = cellGroup.name
            cell.descriptionLabel.text = String(format: "%d items", cellGroup.itemCount)

            let iconName = String(format: "%02d", cellGroup.iconId)
            cell.setIcon(iconName: iconName, tintColor: UIColor(hex: 0xFFCC80))

            return cell
        } else {
            let entry = group.entries[indexPath.row - group.groups.count]

            guard let cell = tableView.dequeueReusableCell(withIdentifier: "entry", for: indexPath) as? EntryTableViewCell else {
                return UITableViewCell()
            }

            cell.titleLabel.text = entry.getStr(key: "Title")?.value

            let iconName = String(format: "%02d", entry.iconId)
            cell.setIcon(iconName: iconName, tintColor: UIColor(hex: 0xDADADA))

            return cell
        }
    }

    // MARK: UITableViewDelegate

    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row < group.groups.count {
            let newGroup = group.groups[indexPath.row]
            let groupViewController = GroupViewController(group: newGroup)
            groupViewController.delegate = self
            navigationController?.pushViewController(groupViewController, animated: true)
        } else {
            let entry = group.entries[indexPath.row - group.groups.count]
            let editEntryViewController = EditEntryViewController(entry: entry)
            editEntryViewController.groupDelegate = self
            navigationController?.pushViewController(editEntryViewController, animated: true)
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return group.groups.count + group.entries.count
    }
}
