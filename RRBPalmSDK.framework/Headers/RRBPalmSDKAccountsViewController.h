//
//  RRBPalmSDKAccountsViewController.h
//  PalmSDK-iOS
//
//  Copyright © 2017 RedRock Biometrics. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class RRBPalmSDKUser;

/*!
 * @typedef RRBPalmSDKAccountsViewControllerUserLoginAttemptHandler
 * Signature of callback block used by PalmID SDK to provide result of user authentification.
 *
 * @param user
 * user instance used for authentication
 *
 * @param result 
 * YES if user authenticated, NO if user doesn't match
 *
 * @param error
 * Not nil in case some error occured. In case user cancelled authentication process it will be error RRBPalmSDKErrorCancelled
 */
typedef void (^RRBPalmSDKAccountsViewControllerUserLoginAttemptHandler)(RRBPalmSDKUser *user, BOOL result, NSError * __nullable error);

/*!
 * @typedef RRBPalmSDKAccountsViewControllerNewUserHandler
 * Signature of callback block used by PalmID SDK to provide newly created user.
 *
 * @param user
 * Newly created and registered user instance
 */

typedef void (^RRBPalmSDKAccountsViewControllerNewUserHandler)(RRBPalmSDKUser *user);

/*!
 * @class RRBPalmSDKAccountsViewController
 *
 * @discussion
 * UIViewController class for 'multi user' mode authentification configuration and management.
 *
 */
@interface RRBPalmSDKAccountsViewController : UIViewController


/*!
 * @property userLoginAttemptHandler
 * Callback block called by PalmID SDK to provide result of user authentification.
*/
@property (nonatomic, copy) RRBPalmSDKAccountsViewControllerUserLoginAttemptHandler userLoginAttemptHandler;

/*!
 * @property newUserHandler
 * Callback block called by PalmID SDK to provide newly created user.
*/
@property (nonatomic, copy) RRBPalmSDKAccountsViewControllerNewUserHandler newUserHandler;

@end

NS_ASSUME_NONNULL_END

