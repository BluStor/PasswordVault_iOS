//
//  RRBPalmSDKSettingsViewController.h
//  PalmSDK-iOS
//
//  Copyright © 2017 RedRock Biometrics. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 * @typedef RRBPalmSDKSettingsViewControllerCompletionHandler
 * Signature of callback block used by PalmID SDK to notify that user wants dismiss settings UI.
 */

typedef void (^RRBPalmSDKSettingsViewControllerCompletionHandler)(NSError * __nullable error);

@class RRBPalmSDKUser;

/*!
 * @class RRBPalmSDKSettingsViewController
 *
 * @discussion
 * UIViewController class for user authentification configuration and management.
 */

@interface RRBPalmSDKSettingsViewController : UIViewController

/*!
 * @method -initWithUser:
 * Initializer of authentification UI for user .
 *
 * @param user
 * Instance of user (nil for default user) for which authentification should be performed.
 *
*/
- (instancetype)initWithUser:(RRBPalmSDKUser * __nullable)user;

/*!
 * @property completionHandler
 * Callback block called by PalmID SDK to notify that user wants dismiss settings UI.
 *
*/
@property(nullable, nonatomic, copy) RRBPalmSDKSettingsViewControllerCompletionHandler completionHandler;

@end

NS_ASSUME_NONNULL_END
