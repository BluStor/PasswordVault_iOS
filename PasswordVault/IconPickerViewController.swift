//
//  IconPickerViewController.swift
//  PasswordVault
//

import UIKit

protocol IconPickerViewControllerDelegate: NSObjectProtocol {
    func setIconId(_ iconId: Int)
}

class IconPickerViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    weak var delegate: IconPickerViewControllerDelegate?

    let collectionView: UICollectionView
    let flowLayout = UICollectionViewFlowLayout()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init() {
        collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: flowLayout)

        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = Theme.Base.viewBackgroundColor
        navigationItem.title = "Icon"
        navigationItem.backButton.tintColor = .white
        navigationItem.titleLabel.textColor = .white
        navigationItem.detailLabel.textColor = .white

        // Flow layout

        let itemWidth = UIScreen.main.bounds.width / 3

        flowLayout.minimumLineSpacing = 0.0
        flowLayout.minimumInteritemSpacing = 0.0
        flowLayout.itemSize = CGSize(width: itemWidth, height: itemWidth)

        // Collection view

        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = nil
        collectionView.register(IconPickerCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        collectionView.reloadData()

        view.addSubview(collectionView)
        NSLayoutConstraint(item: collectionView, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: collectionView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: collectionView, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: collectionView, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: 0.0).isActive = true
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 69
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? IconPickerCollectionViewCell else {
            return UICollectionViewCell()
        }

        let iconName = String(format: "%02d.svg", indexPath.row)
        cell.setIcon(iconName: iconName, tintColor: UIColor(hex: 0xDADADA))

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.setIconId(indexPath.row)
        navigationController?.popViewController(animated: true)
    }
}
