//
//  ScrollViewController.swift
//  PasswordVault
//

import UIKit

class ScrollViewController: UIViewController {
    let scrollView = UIScrollView()
    let contentView = UIView()
    var scrollViewBottomConstraint = NSLayoutConstraint()

    override func viewDidLoad() {
        // Content view

        contentView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addSubview(contentView)
        NSLayoutConstraint(item: contentView, attribute: .top, relatedBy: .equal, toItem: scrollView, attribute: .top, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: contentView, attribute: .bottom, relatedBy: .equal, toItem: scrollView, attribute: .bottom, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: contentView, attribute: .left, relatedBy: .equal, toItem: scrollView, attribute: .left, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: contentView, attribute: .right, relatedBy: .equal, toItem: scrollView, attribute: .right, multiplier: 1.0, constant: 0.0).isActive = true

        // Scroll view

        scrollView.bounces = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        NSLayoutConstraint(item: scrollView, attribute: .top, relatedBy: .equal, toItem: topLayoutGuide, attribute: .bottom, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: scrollView, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: scrollView, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: 0.0).isActive = true

        scrollViewBottomConstraint = NSLayoutConstraint(item: scrollView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: 0.0)
        scrollViewBottomConstraint.isActive = true
    }

    func readjustScrollView(additionalHeight: CGFloat = 0.0) {
        var rect = CGRect(x: 0.0, y: 0.0, width: 0.0, height: additionalHeight)

        for view in scrollView.subviews {
            rect = rect.union(view.frame)
        }

        scrollView.contentSize = rect.size
    }

    func scrollViewContentSize(additionalHeight: CGFloat = 0.0) -> CGSize {
        var height = additionalHeight
        for view in scrollView.subviews {
            height += view.frame.height
        }
        return CGSize(width: scrollView.contentSize.width, height: height + additionalHeight)
    }

    func willShowKeyboard(notification: Notification) {
        if let userInfo = notification.userInfo {
            let keyboardSize = userInfo[UIKeyboardFrameBeginUserInfoKey] as! CGRect

            scrollViewBottomConstraint.constant = -keyboardSize.height

            readjustScrollView(additionalHeight: 100.0)
        }
    }

    func willHideKeyboard(notification: Notification) {
        scrollViewBottomConstraint.constant = 0
        scrollView.contentSize = scrollViewContentSize()
    }
}
