//
//  PasswordGeneratorViewController.swift
//  PasswordVault
//

import Material

protocol PasswordGeneratorViewControllerDelegate: NSObjectProtocol {
    func setPassword(_ password: String)
}

class PasswordGeneratorViewController: UITableViewController {

    enum CharacterClass: Int {
        case upperCase = 2
        case lowerCase = 3
        case digits = 4
        case dash = 5
        case underscore = 6
        case space = 7
        case special = 8
        case brackets = 9
    }

    var password = ""
    var checkedCharacterClasses = Set<CharacterClass>()

    weak var delegate: PasswordGeneratorViewControllerDelegate?

    let setButton = IconButton(title: "Set", titleColor: .white)
    let passwordLabel = UILabel()
    let slider = UISlider()

    override func viewDidLoad() {
        view.backgroundColor = Theme.Base.viewBackgroundColor

        navigationItem.title = "Generate password"
        navigationItem.backButton.tintColor = .white
        navigationItem.titleLabel.textColor = .white
        navigationItem.detailLabel.textColor = .white
        navigationItem.rightViews = [setButton]

        // Set button

        setButton.addTarget(self, action: #selector(didTouchUpInside(sender:)), for: .touchUpInside)

        // Password label

        passwordLabel.numberOfLines = 0
        passwordLabel.textAlignment = .center
        passwordLabel.lineBreakMode = .byCharWrapping
        passwordLabel.font = UIFont(name: "Courier", size: 16.0)
        passwordLabel.translatesAutoresizingMaskIntoConstraints = false

        // Slider

        slider.minimumValue = 10.0
        slider.maximumValue = 200.0
        slider.value = 32.0
        slider.addTarget(self, action: #selector(didChangeSliderValue(sender:)), for: .valueChanged)
        slider.translatesAutoresizingMaskIntoConstraints = false

        // Table view

        tableView.bounces = false
        tableView.separatorColor = UIColor(hex: 0xDEDEDE)
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 75.0
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

        // Data

        checkedCharacterClasses.insert(.upperCase)
        checkedCharacterClasses.insert(.lowerCase)
        checkedCharacterClasses.insert(.digits)

        generatePassword()
        reloadData()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()

        cell.preservesSuperviewLayoutMargins = false
        cell.separatorInset = .zero
        cell.layoutMargins = .zero

        switch indexPath.row {
        case 0:
            cell.contentView.addSubview(passwordLabel)
            NSLayoutConstraint(item: passwordLabel, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 10.0).isActive = true
            NSLayoutConstraint(item: passwordLabel, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: -10.0).isActive = true
            NSLayoutConstraint(item: passwordLabel, attribute: .left, relatedBy: .equal, toItem: cell.contentView, attribute: .left, multiplier: 1.0, constant: 10.0).isActive = true
            NSLayoutConstraint(item: passwordLabel, attribute: .right, relatedBy: .equal, toItem: cell.contentView, attribute: .right, multiplier: 1.0, constant: -10.0).isActive = true
        case 1:
            cell.contentView.addSubview(slider)
            NSLayoutConstraint(item: slider, attribute: .top, relatedBy: .equal, toItem: cell.contentView, attribute: .top, multiplier: 1.0, constant: 10.0).isActive = true
            NSLayoutConstraint(item: slider, attribute: .bottom, relatedBy: .equal, toItem: cell.contentView, attribute: .bottom, multiplier: 1.0, constant: -10.0).isActive = true
            NSLayoutConstraint(item: slider, attribute: .left, relatedBy: .equal, toItem: cell.contentView, attribute: .left, multiplier: 1.0, constant: 10.0).isActive = true
            NSLayoutConstraint(item: slider, attribute: .right, relatedBy: .equal, toItem: cell.contentView, attribute: .right, multiplier: 1.0, constant: -10.0).isActive = true
        case 2:
            cell.textLabel?.text = "Upper-case (A, B, C, ...)"
            cell.accessoryType = checkedCharacterClasses.contains(CharacterClass.upperCase) ? .checkmark : .none
        case 3:
            cell.textLabel?.text = "Lower-case (a, b, c, ...)"
            cell.accessoryType = checkedCharacterClasses.contains(CharacterClass.lowerCase) ? .checkmark : .none
        case 4:
            cell.textLabel?.text = "Digits (0, 1, 2, ...)"
            cell.accessoryType = checkedCharacterClasses.contains(CharacterClass.digits) ? .checkmark : .none
        case 5:
            cell.textLabel?.text = "Dash"
            cell.accessoryType = checkedCharacterClasses.contains(CharacterClass.dash) ? .checkmark : .none
        case 6:
            cell.textLabel?.text = "Underscore"
            cell.accessoryType = checkedCharacterClasses.contains(CharacterClass.underscore) ? .checkmark : .none
        case 7:
            cell.textLabel?.text = "Space"
            cell.accessoryType = checkedCharacterClasses.contains(CharacterClass.space) ? .checkmark : .none
        case 8:
            cell.textLabel?.text = "Special"
            cell.accessoryType = checkedCharacterClasses.contains(CharacterClass.special) ? .checkmark : .none
        case 9:
            cell.textLabel?.text = "Brackets"
            cell.accessoryType = checkedCharacterClasses.contains(CharacterClass.brackets) ? .checkmark : .none
        default:
            break
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            generatePassword()
        case 2..<10:
            guard let characterClass = CharacterClass(rawValue: indexPath.row) else {
                return
            }

            if checkedCharacterClasses.contains(characterClass) {
                checkedCharacterClasses.remove(characterClass)
            } else {
                checkedCharacterClasses.insert(characterClass)
            }

            generatePassword()
            reloadData()
        default:
            break
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }

    func didChangeSliderValue(sender: UIView) {
        switch sender {
        case slider:
            generatePassword()
        default:
            break
        }
    }

    func didTouchUpInside(sender: UIView) {
        switch sender {
        case setButton:
            delegate?.setPassword(passwordLabel.text ?? "")
            navigationController?.popViewController(animated: true)
        default:
            break
        }
    }

    func reloadData() {
        for i in 2..<10 {
            let indexPath = IndexPath(row: i, section: 0)

            let cell = tableView.cellForRow(at: indexPath)
            let characterClass = CharacterClass(rawValue: i)!
            if checkedCharacterClasses.contains(characterClass) {
                cell?.accessoryType = .checkmark
            } else {
                cell?.accessoryType = .none
            }
        }
    }

    func generatePassword() {
        var characters = [Character]()
        for characterClass in checkedCharacterClasses {
            switch characterClass {
            case .upperCase:
                characters.append(contentsOf: ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"])
            case .lowerCase:
                characters.append(contentsOf: ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"])
            case .digits:
                characters.append(contentsOf: ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"])
            case .dash:
                characters.append("-")
            case .underscore:
                characters.append("_")
            case .space:
                characters.append(" ")
            case .special:
                characters.append(contentsOf: ["`", "~", "!", "@", "#", "$", "%", "^", "&", "*", "+", "="])
            case .brackets:
                characters.append(contentsOf: ["(", ")", "[", "]", "{", "}"])
            }
        }

        let size = Int(roundf(slider.value))

        var password = ""
        for _ in 0..<size {
            if let char = characters.randomItem() {
                password.append(char)
            }
        }

        passwordLabel.text = password

        tableView.beginUpdates()
        tableView.endUpdates()
    }
}
