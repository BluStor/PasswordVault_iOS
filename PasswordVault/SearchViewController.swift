//
//  SearchViewController.swift
//  PasswordVault
//

import Material

class SearchViewController: UIViewController, SearchBarDelegate, UITableViewDataSource, UITableViewDelegate {

    let searchBar = SearchBar()
    let separatorView = UIView()
    let tableView = UITableView()

    var entries: [KdbxXml.Entry] = Array()

    override func viewDidLoad() {
        view.backgroundColor = Theme.Base.viewBackgroundColor

        navigationItem.title = "Search"
        navigationItem.backButton.tintColor = .white
        navigationItem.titleLabel.textColor = .white
        navigationItem.detailLabel.textColor = .white

        // Search bar

        searchBar.delegate = self
        searchBar.placeholder = "Enter a title"
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

    // MARK: SearchBarDelegate

    func searchBar(searchBar: SearchBar, didClear textField: UITextField, with text: String?) {
        entries.removeAll()
        tableView.reloadData()
    }

    func searchBar(searchBar: SearchBar, didChange textField: UITextField, with text: String?) {
        guard let query = text, let kdbx = Vault.kdbx else {
            entries.removeAll()
            tableView.reloadData()
            return
        }

        entries.removeAll()
        entries.append(contentsOf: kdbx.findEntries(title: query))
        tableView.reloadData()
    }

    // MARK: UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return entries.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let entry = entries[indexPath.row]

        guard  let cell = tableView.dequeueReusableCell(withIdentifier: "entryCell") as? EntryTableViewCell else {
            return UITableViewCell()
        }

        let iconName = String(format: "%02d", entry.iconId)

        let title = entry.getStr(key: "Title")?.value ?? ""

        cell.setIcon(iconName: iconName, tintColor: UIColor(hex: 0xDADADA))
        cell.titleLabel.text = title

        return cell
    }

    // MARK: UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let entry = entries[indexPath.row]

        guard let navigationController = navigationController else {
            return
        }

        let editEntryViewController = EditEntryViewController(entry: entry)

        let viewControllers = navigationController.viewControllers.dropLast()
        navigationController.setViewControllers(Array(viewControllers), animated: true)
        navigationController.pushViewController(editEntryViewController, animated: true)
    }
}
