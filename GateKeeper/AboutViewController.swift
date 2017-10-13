//
//  AboutViewController.swift
//  GateKeeper
//

import UIKit

class AboutViewController: UITableViewController {
    struct AboutItem {
        let icon: String
        let title: String
        let url: String
    }

    let items = [
        AboutItem(
            icon: "phone",
            title: "+ 1 312 840 8250",
            url: "telprompt://+13128408250"
        ),
        AboutItem(
            icon: "email",
            title: "info@blustor.co",
            url: "mailto:?to=info@blustor.co"
        ),
        AboutItem(
            icon: "location",
            title: "401 North Michigan Avenue\nChicago, IL 60611",
            url: "http://maps.apple.com/?address=401,North+Michigan+Avenue,Chicago,IL"
        )
    ]

    override func viewDidLoad() {
        view.backgroundColor = Theme.Base.viewBackgroundColor

        navigationItem.titleLabel.text = "About"
        navigationItem.backButton.tintColor = .white
        navigationItem.titleLabel.textColor = .white
        navigationItem.detailLabel.textColor = .white

        // Table view

        tableView.delegate = self
        tableView.dataSource = self
        tableView.bounces = false
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 65.0
        tableView.register(AboutTableViewCell.self, forCellReuseIdentifier: "aboutCell")
    }

    // MARK: UITableViewDataSource

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]

        guard let cell = tableView.dequeueReusableCell(withIdentifier: "aboutCell", for: indexPath) as? AboutTableViewCell else {
            return UITableViewCell()
        }

        cell.iconImageView.image = UIImage(named: item.icon)
        cell.titleLabel.text = item.title
        return cell
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }

    // MARK: UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]

        if let url = URL(string: item.url) {
            UIApplication.shared.openURL(url)
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
}
