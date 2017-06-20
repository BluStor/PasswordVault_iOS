//
//  SearchViewController.swift
//  PasswordVault
//

import Material

class SearchViewController: UIViewController, SearchBarDelegate, UITableViewDataSource, UITableViewDelegate {

    let searchBar = SearchBar()
    let separatorView = UIView()
    let tableView = UITableView()

    var titleEntries: [KdbxXml.Entry] = Array()
    var usernameEntries: [KdbxXml.Entry] = Array()
    var urlEntries: [KdbxXml.Entry] = Array()
    var notesEntries: [KdbxXml.Entry] = Array()

    override func viewDidLoad() {
        view.backgroundColor = Theme.Base.viewBackgroundColor

        navigationItem.title = "Entry search"
        navigationItem.backButton.tintColor = .white
        navigationItem.titleLabel.textColor = .white
        navigationItem.detailLabel.textColor = .white

        // Search bar

        searchBar.delegate = self
        searchBar.placeholder = "Enter a query"
        searchBar.textField.autocapitalizationType = .none
        searchBar.textField.autocorrectionType = .no
        searchBar.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(searchBar)
        NSLayoutConstraint(item: searchBar, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: searchBar, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: searchBar, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: 0.0).isActive = true

        // Separator view

        separatorView.backgroundColor = UIColor(hex: 0xEEEEEE)
        separatorView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(separatorView)
        NSLayoutConstraint(item: separatorView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 1.0).isActive = true
        NSLayoutConstraint(item: separatorView, attribute: .top, relatedBy: .equal, toItem: searchBar, attribute: .bottom, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: separatorView, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: separatorView, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: 0.0).isActive = true

        // Table view

        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
        tableView.register(EntryTableViewCell.self, forCellReuseIdentifier: "entryCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(tableView)
        NSLayoutConstraint(item: tableView, attribute: .top, relatedBy: .equal, toItem: separatorView, attribute: .bottom, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: tableView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: tableView, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: tableView, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: 0.0).isActive = true
    }

    override func viewDidAppear(_ animated: Bool) {
        searchBar.textField.becomeFirstResponder()
    }

    func getEntry(indexPath: IndexPath) -> KdbxXml.Entry? {
        switch indexPath.section {
        case 0:
            return titleEntries[indexPath.row]
        case 1:
            return usernameEntries[indexPath.row]
        case 2:
            return urlEntries[indexPath.row]
        case 3:
            return notesEntries[indexPath.row]
        default:
            return nil
        }
    }

    // MARK: SearchBarDelegate

    func searchBar(searchBar: SearchBar, didClear textField: UITextField, with text: String?) {
        titleEntries.removeAll()
        usernameEntries.removeAll()
        urlEntries.removeAll()
        notesEntries.removeAll()

        tableView.reloadData()
    }

    func searchBar(searchBar: SearchBar, didChange textField: UITextField, with text: String?) {
        guard let query = text, let kdbx = Vault.kdbx else {
            return
        }

        titleEntries.removeAll()
        usernameEntries.removeAll()
        urlEntries.removeAll()
        notesEntries.removeAll()

        let results = kdbx.search(query: query, attributes: [.title, .username, .url, .notes])

        titleEntries.append(contentsOf: results[.title] ?? [])
        usernameEntries.append(contentsOf: results[.username] ?? [])
        urlEntries.append(contentsOf: results[.url] ?? [])
        notesEntries.append(contentsOf: results[.notes] ?? [])

        print("title results: \(titleEntries.count)")
        print("username results: \(usernameEntries.count)")
        print("url results: \(urlEntries.count)")
        print("notes results: \(notesEntries.count)")

        tableView.reloadData()
    }

    // MARK: UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return titleEntries.count
        case 1:
            return usernameEntries.count
        case 2:
            return urlEntries.count
        case 3:
            return notesEntries.count
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let entry = getEntry(indexPath: indexPath) else {
            return UITableViewCell()
        }

        guard  let cell = tableView.dequeueReusableCell(withIdentifier: "entryCell") as? EntryTableViewCell else {
            return UITableViewCell()
        }

        let iconName = String(format: "%02d", entry.iconId)

        let title = entry.getStr(key: "Title")?.value ?? ""

        cell.setIcon(iconName: iconName, tintColor: UIColor(hex: 0xDADADA))
        cell.titleLabel.text = title

        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            if !titleEntries.isEmpty {
                return "Title matches"
            }
        case 1:
            if !usernameEntries.isEmpty {
                return "Username matches"
            }
        case 2:
            if !urlEntries.isEmpty {
                return "URL matches"
            }
        case 3:
            if !notesEntries.isEmpty {
                return "Notes matches"
            }
        default:
            return nil
        }

        return nil
    }

    // MARK: UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let entry = getEntry(indexPath: indexPath) else {
            return
        }

        guard let navigationController = navigationController else {
            return
        }

        let editEntryViewController = EditEntryViewController(entry: entry)

        let viewControllers = navigationController.viewControllers.dropLast()
        navigationController.setViewControllers(Array(viewControllers), animated: true)
        navigationController.pushViewController(editEntryViewController, animated: true)
    }
}
