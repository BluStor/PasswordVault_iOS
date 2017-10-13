//
//  SplashViewController.swift
//  GateKeeper
//

import UIKit

class SplashViewController: UIViewController {

    let cardsImageView = UIImageView()
    let gateKeeperLabel = UILabel()
    let activityIndicatorView = UIActivityIndicatorView()

    override func viewDidLoad() {
        view.backgroundColor = Theme.Base.viewBackgroundColor

        navigationItem.titleLabel.text = "Identity GateKeeper"
        navigationItem.backButton.tintColor = .white
        navigationItem.titleLabel.textColor = .white
        navigationItem.detailLabel.textColor = .white

        // Cards image view

        cardsImageView.contentMode = .scaleAspectFit
        cardsImageView.image = UIImage(named: "card")
        cardsImageView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(cardsImageView)
        NSLayoutConstraint(item: cardsImageView, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: cardsImageView, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 10.0).isActive = true
        NSLayoutConstraint(item: cardsImageView, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: -10.0).isActive = true

        // GateKeeper label

        gateKeeperLabel.text = "Welcome to\nGateKeeper"
        gateKeeperLabel.numberOfLines = 0
        gateKeeperLabel.textAlignment = .center
        gateKeeperLabel.font = UIFont.boldSystemFont(ofSize: 24.0)
        gateKeeperLabel.textColor = UIColor(hex: 0x03A9F4)
        gateKeeperLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(gateKeeperLabel)
        NSLayoutConstraint(item: gateKeeperLabel, attribute: .bottom, relatedBy: .equal, toItem: cardsImageView, attribute: .top, multiplier: 1.0, constant: -10.0).isActive = true
        NSLayoutConstraint(item: gateKeeperLabel, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 10.0).isActive = true
        NSLayoutConstraint(item: gateKeeperLabel, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: -10.0).isActive = true

        // Activity indicator view

        activityIndicatorView.color = UIColor(hex: 0x666666)
        activityIndicatorView.startAnimating()
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(activityIndicatorView)
        NSLayoutConstraint(item: activityIndicatorView, attribute: .top, relatedBy: .equal, toItem: cardsImageView, attribute: .bottom, multiplier: 1.0, constant: 10.0).isActive = true
        NSLayoutConstraint(item: activityIndicatorView, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 10.0).isActive = true
        NSLayoutConstraint(item: activityIndicatorView, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: -10.0).isActive = true

        // Load

        load()
    }

    func load() {
        guard let cardUUID = Vault.cardUUID else {
            loadChooseCard()
            return
        }

        guard let card = GKCard(uuid: cardUUID) else {
            loadChooseCard()
            return
        }

        GKCard.checkBluetoothState()
        .then {
            card.connect(timeout: 5.0)
        }
        .then {
            card.exists(path: Vault.dbPath)
        }
        .then { pathExists in
            if pathExists {
                self.loadUnlock()
            } else {
                self.loadCreate()
            }
        }
        .catch { error in
            print(error)
            self.loadUnlock()
        }
    }

    func loadChooseCard() {
        let chooseCardViewController = ChooseCardViewController()
        navigationController?.setViewControllers([chooseCardViewController], animated: true)
    }
    
    func loadCreate() {
        let createViewController = CreateViewController()
        navigationController?.setViewControllers([createViewController], animated: true)
    }

    func loadUnlock() {
        let unlockViewController = UnlockViewController()
        navigationController?.setViewControllers([unlockViewController], animated: true)
    }
}
