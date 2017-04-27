//
//  AppDelegate.swift
//  PasswordVault
//

import Material
import SVProgressHUD
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        // Appearances

        UINavigationBar.appearance().titleTextAttributes = [
            NSForegroundColorAttributeName: UIColor.white
        ]

        SVProgressHUD.setBackgroundLayerColor(UIColor(white: 0.0, alpha: 0.3))
        SVProgressHUD.setDefaultAnimationType(.flat)
        SVProgressHUD.setDefaultMaskType(.custom)
        SVProgressHUD.setFadeInAnimationDuration(0.0)
        SVProgressHUD.setMaximumDismissTimeInterval(2.0)
        SVProgressHUD.setOffsetFromCenter(UIOffset(horizontal: 0.0, vertical: 120.0))

        // Window

        window = UIWindow(frame: UIScreen.main.bounds)

        let unlockViewController = UnlockViewController()

        let navigationController = NavigationController(rootViewController: unlockViewController)
        navigationController.navigationBar.tintColor = Theme.Base.navigationBarTintColor
        navigationController.navigationBar.barTintColor = Theme.Base.navigationBarBarTintColor

        navigationController.view.removeGestureRecognizer(navigationController.interactivePopGestureRecognizer!)

        window!.rootViewController = navigationController
        window!.makeKeyAndVisible()

        return true
    }
}
