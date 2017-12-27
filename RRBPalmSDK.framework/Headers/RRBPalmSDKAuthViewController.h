//
//  RRBPalmSDKAuthViewController.h
//  PalmSDK-iOS
//
//  Copyright © 2017 RedRock Biometrics. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


/*!
 * @typedef RRBPalmSDKUserListCompletionHandler
 * Signature of callback block used by PalmID SDK to provide result of user authentification.
 *
 * @param result 
 * YES if user authenticated, NO if user doesn't match
 *
 * @param error
 * Not nil in case some error occured. In case user cancelled authentication process it will be error RRBPalmSDKErrorCancelled
 */
typedef void (^RRBPalmSDKAuthViewControllerCompletionHandler)(BOOL result, NSError * __nullable error);


@class RRBPalmSDKUser;

/*!
 * @class RRBPalmSDKAuthViewController
 *
 * @discussion
 * UIViewController class for user authentification.
 */

@interface RRBPalmSDKAuthViewController : UIViewController

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
 * Callback block called by PalmID SDK to provide result of user authentification.
 *
*/
@property(nullable, nonatomic, copy) RRBPalmSDKAuthViewControllerCompletionHandler completionHandler;

/*!
 * @property brandInfoView
 * Optional view with brand info to be placed above camera view.
 *
*/
@property (nonatomic, strong) UIView * _Nullable brandInfoView;

@end

NS_ASSUME_NONNULL_END
