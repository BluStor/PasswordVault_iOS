//
//  ScanViewController.swift
//  PasswordVault
//

import UIKit
import SwiftyBluetooth

class ChooseCardViewController: UITableViewController {

    struct ScannedPeripheral {
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

    var scannedPeripherals = [ScannedPeripheral]()

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
        tableView.register(ScannedPeripheralTableViewCell.self, forCellReuseIdentifier: "scannedPeripheral")

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
            timeoutAfter: 10.0
        ) { result in
            switch result {
            case .scanStarted:
                print("scan started")
                self.activityIndicatorView.startAnimating()
            case .scanStopped:
                print("scan stopped")
            case .scanResult(let peripheral, let advertisementData, let rssi):
                let scannedPeripheral = ScannedPeripheral(peripheral: peripheral, advertisementData: advertisementData, rssi: rssi)

                self.scannedPeripherals.append(scannedPeripheral)
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
                cell.contentView.addSubview(lockImageView)
                NSLayoutConstraint(item: lockImageView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 150.0).isActive = true
                NSLayoutConstraint(item: lockImageView, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 10.0).isActive = true
                NSLayoutConstraint(item: lockImageView, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: -10.0).isActive = true
                NSLayoutConstraint(item: lockImageView, attribute: .left, relatedBy: .equal, toItem: cell.contentView, attribute: .left, multiplier: 1.0, constant: 10.0).isActive = true
                NSLayoutConstraint(item: lockImageView, attribute: .right, relatedBy: .equal, toItem: cell.contentView, attribute: .right, multiplier: 1.0, constant: -10.0).isActive = true
            case 1:
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
            let scannedPeripheral = scannedPeripherals[indexPath.row]

            guard let cell = tableView.dequeueReusableCell(withIdentifier: "scannedPeripheral") as? ScannedPeripheralTableViewCell else {
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
            return scannedPeripherals.count
        default:
            return 0
        }
    }

    // MARK: UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            return
        case 1:
            let scannedPeripheral = scannedPeripherals[indexPath.row]

            Vault.cardUUID = scannedPeripheral.peripheral.identifier

            let unlockViewController = UnlockViewController()
            navigationController?.setViewControllers([unlockViewController], animated: true)
        default:
            return
        }
    }
}
