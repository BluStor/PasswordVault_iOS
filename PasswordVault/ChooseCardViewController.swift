//
//  ScanViewController.swift
//  PasswordVault
//

import UIKit
import SwiftyBluetooth

class ChooseCardViewController: UITableViewController {

    struct ScannedCard {
        let peripheral: Peripheral
        let advertisementData: [String:Any]
        let rssi: Int?

        func percentage() -> Double? {
            if let rssi = rssi {
                return (2.0 * (Double(rssi) + 100.0)) / 100.0
            } else {
                return nil
            }
        }
    }

    var scannedCards = [ScannedCard]()

    let lockImageView = UIImageView(image: UIImage(named: "lock"))
    let activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .gray)

    override func viewDidLoad() {
        view.backgroundColor = Theme.Base.viewBackgroundColor

        navigationItem.title = "Choose your card"
        navigationItem.backButton.tintColor = .white
        navigationItem.titleLabel.textColor = .white
        navigationItem.detailLabel.textColor = .white

        // Table view

        tableView.bounces = false
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 200.0
        tableView.register(ScannedCardTableViewCell.self, forCellReuseIdentifier: "scannedCard")

        // Lock image view

        lockImageView.clipsToBounds = true
        lockImageView.contentMode = .scaleAspectFit
        lockImageView.translatesAutoresizingMaskIntoConstraints = false

        // Activity indicator view

        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false

        // Scan

        scan()
    }

    func scan() {
        SwiftyBluetooth.scanForPeripherals(
            withServiceUUIDs: [GKCard.serviceUUID],
            timeoutAfter: TimeInterval.infinity
        ) { result in
            switch result {
            case .scanStarted:
                print("scan started")
                self.activityIndicatorView.startAnimating()
            case .scanStopped:
                print("scan stopped")
            case .scanResult(let peripheral, let advertisementData, let rssi):
                let scannedPeripheral = ScannedCard(peripheral: peripheral, advertisementData: advertisementData, rssi: rssi)

                self.scannedCards.append(scannedPeripheral)
                self.tableView.reloadData()
            }
        }
    }

    // MARK: UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = UITableViewCell()

            switch indexPath.row {
            case 0:
                cell.selectionStyle = .none
                cell.contentView.addSubview(lockImageView)
                NSLayoutConstraint(item: lockImageView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 150.0).isActive = true
                NSLayoutConstraint(item: lockImageView, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 10.0).isActive = true
                NSLayoutConstraint(item: lockImageView, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: -10.0).isActive = true
                NSLayoutConstraint(item: lockImageView, attribute: .left, relatedBy: .equal, toItem: cell.contentView, attribute: .left, multiplier: 1.0, constant: 10.0).isActive = true
                NSLayoutConstraint(item: lockImageView, attribute: .right, relatedBy: .equal, toItem: cell.contentView, attribute: .right, multiplier: 1.0, constant: -10.0).isActive = true
            case 1:
                cell.selectionStyle = .none
                cell.contentView.addSubview(activityIndicatorView)
                NSLayoutConstraint(item: activityIndicatorView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 50.0).isActive = true
                NSLayoutConstraint(item: activityIndicatorView, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 10.0).isActive = true
                NSLayoutConstraint(item: activityIndicatorView, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: -10.0).isActive = true
                NSLayoutConstraint(item: activityIndicatorView, attribute: .centerX, relatedBy: .equal, toItem: cell.contentView, attribute: .centerX, multiplier: 1.0, constant: 0.0).isActive = true
            default:
                break
            }

            return cell
        case 1:
            let scannedPeripheral = scannedCards[indexPath.row]

            guard let cell = tableView.dequeueReusableCell(withIdentifier: "scannedCard") as? ScannedCardTableViewCell else {
                return UITableViewCell()
            }

            cell.nameLabel.text = scannedPeripheral.peripheral.name
            if let percentage = scannedPeripheral.percentage() {
                print(percentage)
                switch percentage {
                case 0.4...1.0:
                    cell.descriptionLabel.text = "Very good signal"
                default:
                    cell.descriptionLabel.text = "Good signal"
                }
            } else {
                cell.descriptionLabel.text = "Unknown signal"
            }

            return cell
        default:
            return UITableViewCell()
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 2
        case 1:
            return scannedCards.count
        default:
            return 0
        }
    }

    // MARK: UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 1:
            let scannedPeripheral = scannedCards[indexPath.row]

            Vault.cardUUID = scannedPeripheral.peripheral.identifier

            if (navigationController?.viewControllers ?? []).count > 0 {
                navigationController?.popViewController(animated: true)
            } else {
                let unlockViewController = UnlockViewController()
                navigationController?.setViewControllers([unlockViewController], animated: true)
            }
        default:
            return
        }
    }
}
