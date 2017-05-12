//
//  GroupViewController.swift
//  PasswordVault
//

import UIKit

protocol GroupViewControllerDelegate: NSObjectProtocol {
    func reloadData()
}

class GroupViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, GroupViewControllerDelegate {

    weak var delegate: GroupViewControllerDelegate?

    var group: KdbxXml.Group
    let syncView = SyncView()
    let tableView = UITableView()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(group: KdbxXml.Group) {
        self.group = group

        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        view.backgroundColor = .white
        navigationItem.title = group.name
        navigationItem.backButton.tintColor = .white
        navigationItem.titleLabel.textColor = .white
        navigationItem.detailLabel.textColor = .white

        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(didLongPress(longPressGestureRecognizer:)))

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
    }

    override func viewWillDisappear(_ animated: Bool) {
        delegate?.reloadData()
    }

    func didLongPress(longPressGestureRecognizer: UILongPressGestureRecognizer) {
        guard let view = longPressGestureRecognizer.view else {
            return
        }

        if view === tableView {

            let point = longPressGestureRecognizer.location(in: tableView)

            if let indexPath = tableView.indexPathForRow(at: point) {
                if indexPath.row < group.groups.count {
                    let selectedGroup = group.groups[indexPath.row]

                    let alert = UIAlertController(title: "Group", message: selectedGroup.name, preferredStyle: .actionSheet)

                    alert.addAction(UIAlertAction(title: "Edit", style: .default, handler: { _ in
                        let editGroupViewController = EditGroupViewController(group: selectedGroup)
                        editGroupViewController.groupDelegate = self
                        self.navigationController?.pushViewController(editGroupViewController, animated: true)
                    }))

                    alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                        if let kdbx = Vault.kdbx {
                            if kdbx.delete(groupUUID: selectedGroup.uuid) {
                                self.reloadData()
                            }
                        }
                    }))

                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                        alert.dismiss(animated: true, completion: nil)
                    }))

                    present(alert, animated: true)
                } else {
                    let selectedEntry = group.entries[indexPath.row - group.groups.count]

                    let alert = UIAlertController(title: "Group", message: selectedEntry.title, preferredStyle: .actionSheet)

                    alert.addAction(UIAlertAction(title: "Edit", style: .default, handler: { _ in
                        let editEntryViewController = EditEntryViewController(entry: selectedEntry)
                        editEntryViewController.groupDelegate = self
                        self.navigationController?.pushViewController(editEntryViewController, animated: true)
                    }))

                    alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                        if let kdbx = Vault.kdbx {
                            if kdbx.delete(entryUUID: selectedEntry.uuid) {
                                self.reloadData()
                            }
                        }
                    }))

                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                        alert.dismiss(animated: true, completion: nil)
                    }))

                    present(alert, animated: true)
                }
            }
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row < group.groups.count {
            let cellGroup = group.groups[indexPath.row]

            guard let cell = tableView.dequeueReusableCell(withIdentifier: "group", for: indexPath) as? GroupTableViewCell else {
                return UITableViewCell()
            }

            cell.titleLabel.text = cellGroup.name
            cell.descriptionLabel.text = String(format: "%d items", cellGroup.itemCount)

            let iconName = String(format: "%02d", cellGroup.iconId)
            cell.setIcon(iconName: iconName, tintColor: UIColor(hex: 0xDADADA))

            return cell
        } else {
            let entry = group.entries[indexPath.row - group.groups.count]

            guard let cell = tableView.dequeueReusableCell(withIdentifier: "entry", for: indexPath) as? EntryTableViewCell else {
                return UITableViewCell()
            }

            cell.titleLabel.text = entry.title

            let iconName = String(format: "%02d", entry.iconId)
            cell.setIcon(iconName: iconName, tintColor: UIColor(hex: 0xDADADA))

            return cell
        }
    }

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

    func reloadData() {
        if let refreshedGroup = Vault.kdbx?.get(groupUUID: group.uuid) {
            group = refreshedGroup
            tableView.reloadData()
        }
    }
}
