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
    let tableView = UITableView()
    let searchFabButton = FABButton(image: Icon.search, tintColor: .white)
    let addFabButton = FABButton(image: Icon.add, tintColor: .white)

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(group: KdbxXml.Group) {
        self.group = group

        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        view.backgroundColor = Theme.Base.viewBackgroundColor

        navigationItem.titleLabel.text = group.name
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

        // Search floating action button

        searchFabButton.backgroundColor = Theme.Group.searchFloatingActionButtonBackgroundColor
        searchFabButton.addTarget(self, action: #selector(didTouchUpInside(sender:)), for: .touchUpInside)
        searchFabButton.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(searchFabButton)
        NSLayoutConstraint(item: searchFabButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 50.0).isActive = true
        NSLayoutConstraint(item: searchFabButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 50.0).isActive = true
        NSLayoutConstraint(item: searchFabButton, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: -20.0).isActive = true
        NSLayoutConstraint(item: searchFabButton, attribute: .centerY, relatedBy: .equal, toItem: syncView, attribute: .bottom, multiplier: 1.0, constant: 0.0).isActive = true

        // Add floating action button

        addFabButton.backgroundColor = Theme.Group.addFloatingActionButtonBackgroundColor
        addFabButton.addTarget(self, action: #selector(didTouchUpInside(sender:)), for: .touchUpInside)
        addFabButton.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(addFabButton)
        NSLayoutConstraint(item: addFabButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 65.0).isActive = true
        NSLayoutConstraint(item: addFabButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 65.0).isActive = true
        NSLayoutConstraint(item: addFabButton, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: -20.0).isActive = true
        NSLayoutConstraint(item: addFabButton, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: -20.0).isActive = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        delegate?.reloadData()
    }

    @objc func didLongPress(longPressGestureRecognizer: UILongPressGestureRecognizer) {
        guard let view = longPressGestureRecognizer.view else {
            return
        }

        switch view {
        case tableView:
            let point = longPressGestureRecognizer.location(in: tableView)

            if let indexPath = tableView.indexPathForRow(at: point) {

                guard let cell = tableView.cellForRow(at: indexPath) else {
                    return
                }

                if indexPath.row < group.groups.count {
                    if longPressGestureRecognizer.state == .began {
                        let sortedGroups = group.groups.sorted(by: { (groupa, groupb) -> Bool in
                            return groupa.name < groupb.name
                        })

                        let selectedGroup = sortedGroups[indexPath.row]

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
                            let deleteAlertController = UIAlertController(title: "Warning", message: "Are you sure you want to delete this group?", preferredStyle: .alert)

                            deleteAlertController.addAction(UIAlertAction(title: "Delete", style: .default, handler: { _ in
                                if let kdbx = Vault.kdbx {
                                    kdbx.delete(groupUUID: selectedGroup.uuid)

                                    self.reloadData()
                                    Vault.save()
                                }
                            }))

                            deleteAlertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                                deleteAlertController.dismiss(animated: true, completion: nil)
                            }))

                            self.present(deleteAlertController, animated: true, completion: nil)
                        }))

                        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                            alertController.dismiss(animated: true, completion: nil)
                        }))

                        alertController.popoverPresentationController?.sourceView = cell
                        alertController.popoverPresentationController?.sourceRect = cell.bounds

                        present(alertController, animated: true, completion: nil)
                    }
                } else {
                    if longPressGestureRecognizer.state == .began {
                        let sortedEntries = group.entries.sorted(by: { (entrya, entryb) -> Bool in
                            let titlea = entrya.getStr(key: "Title")?.value ?? ""
                            let titleb = entryb.getStr(key: "Title")?.value ?? ""
                            return titlea < titleb
                        })

                        let selectedEntry = sortedEntries[indexPath.row - group.groups.count]

                        let alertController = UIAlertController(
                            title: "Entry",
                            message: selectedEntry.getStr(key: "Title")?.value,
                            preferredStyle: .actionSheet
                        )

                        alertController.addAction(UIAlertAction(title: "Edit", style: .default, handler: { _ in
                            let editEntryViewController = EditEntryViewController(entry: selectedEntry)
                            editEntryViewController.groupDelegate = self
                            self.navigationController?.pushViewController(editEntryViewController, animated: true)
                        }))

                        alertController.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                            let deleteAlertController = UIAlertController(title: "Warning", message: "Are you sure you want to delete this group?", preferredStyle: .alert)

                            deleteAlertController.addAction(UIAlertAction(title: "Delete", style: .default, handler: { _ in
                                if let kdbx = Vault.kdbx {
                                    kdbx.delete(entryUUID: selectedEntry.uuid)

                                    self.reloadData()
                                    Vault.save()
                                }
                            }))

                            deleteAlertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                                deleteAlertController.dismiss(animated: true, completion: nil)
                            }))

                            self.present(deleteAlertController, animated: true, completion: nil)
                        }))

                        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                            alertController.dismiss(animated: true, completion: nil)
                        }))

                        alertController.popoverPresentationController?.sourceView = cell
                        alertController.popoverPresentationController?.sourceRect = cell.bounds

                        present(alertController, animated: true, completion: nil)
                    }
                }
            }
        default:
            break
        }
    }

    @objc func didTouchUpInside(sender: UIView) {
        switch sender {
        case addFabButton:
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

            alertController.popoverPresentationController?.sourceView = addFabButton
            alertController.popoverPresentationController?.sourceRect = addFabButton.bounds

            present(alertController, animated: true, completion: nil)
        case moreButton:
            let alertController = UIAlertController(title: "Menu", message: nil, preferredStyle: .actionSheet)

            alertController.addAction(UIAlertAction(title: "Database settings", style: .default, handler: { _ in
                let databaseSettingsViewController = DatabaseSettingsViewController()
                self.navigationController?.pushViewController(databaseSettingsViewController, animated: true)
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
        case searchFabButton:
            let searchViewController = SearchViewController()
            navigationController?.pushViewController(searchViewController, animated: true)
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
            let sortedGroups = group.groups.sorted(by: { (groupa, groupb) -> Bool in
                return groupa.name < groupb.name
            })

            let cellGroup = sortedGroups[indexPath.row]

            guard let cell = tableView.dequeueReusableCell(withIdentifier: "group", for: indexPath) as? GroupTableViewCell else {
                return UITableViewCell()
            }

            cell.titleLabel.text = cellGroup.name
            cell.descriptionLabel.text = String(format: "%d items", cellGroup.itemCount)

            let iconName = String(format: "%02d", cellGroup.iconId)
            cell.setIcon(iconName: iconName, tintColor: UIColor(hex: 0xFFCC80))

            return cell
        } else {
            let sortedEntries = group.entries.sorted(by: { (entrya, entryb) -> Bool in
                let titlea = entrya.getStr(key: "Title")?.value ?? ""
                let titleb = entryb.getStr(key: "Title")?.value ?? ""
                return titlea < titleb
            })

            let entry = sortedEntries[indexPath.row - group.groups.count]

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
            let sortedGroups = group.groups.sorted(by: { (groupa, groupb) -> Bool in
                return groupa.name < groupb.name
            })

            let newGroup = sortedGroups[indexPath.row]
            let groupViewController = GroupViewController(group: newGroup)
            groupViewController.delegate = self
            navigationController?.pushViewController(groupViewController, animated: true)
        } else {
            let sortedEntries = group.entries.sorted(by: { (entrya, entryb) -> Bool in
                let titlea = entrya.getStr(key: "Title")?.value ?? ""
                let titleb = entryb.getStr(key: "Title")?.value ?? ""
                return titlea < titleb
            })

            let entry = sortedEntries[indexPath.row - group.groups.count]
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
