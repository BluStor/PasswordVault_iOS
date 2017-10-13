//
//  AppDelegate.swift
//  GateKeeper
//

import IQKeyboardManagerSwift
import Material

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        // Appearances

        UINavigationBar.appearance().titleTextAttributes = [
            NSAttributedStringKey.foregroundColor: UIColor.white
        ]
        
        // Keyboard manager

        let keyboardManager = IQKeyboardManager.sharedManager()
        keyboardManager.enable = true
        keyboardManager.toolbarDoneBarButtonItemText = "Hide"

        // Window

        window = UIWindow(frame: UIScreen.main.bounds)

        let splashViewController = SplashViewController()
        let navigationController = NavigationController(rootViewController: splashViewController)

        navigationController.navigationBar.tintColor = Theme.Base.navigationBarTintColor
        navigationController.navigationBar.barTintColor = Theme.Base.navigationBarBarTintColor

        window!.rootViewController = navigationController
        window!.makeKeyAndVisible()

        return true
    }
}
