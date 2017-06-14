//
//  AppDelegate.swift
//  PasswordVault
//

import IQKeyboardManagerSwift
import Material
import SVProgressHUD

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

        // Keyboard manager

        let keyboardManager = IQKeyboardManager.sharedManager()
        keyboardManager.enable = true
        keyboardManager.toolbarDoneBarButtonItemText = "Hide"

        // Window

        window = UIWindow(frame: UIScreen.main.bounds)

        let navigationController: NavigationController
        if Vault.cardUUID == nil {
            let chooseCardViewController = ChooseCardViewController()
            navigationController = NavigationController(rootViewController: chooseCardViewController)
        } else {
            let unlockViewController = UnlockViewController()
            navigationController = NavigationController(rootViewController: unlockViewController)
        }

        navigationController.navigationBar.tintColor = Theme.Base.navigationBarTintColor
        navigationController.navigationBar.barTintColor = Theme.Base.navigationBarBarTintColor

        window!.rootViewController = navigationController
        window!.makeKeyAndVisible()

        return true
    }
}
