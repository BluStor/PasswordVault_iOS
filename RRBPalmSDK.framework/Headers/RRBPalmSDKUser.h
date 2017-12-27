//
//  RRBPalmSDKUser.h
//  PalmSDK-iOS
//
//  Copyright © 2017 RedRock Biometrics. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class RRBPalmSDKUser;

/*!
 * @typedef RRBPalmSDKUserAuthenticationDataType
 * Constants used to get registered for user authentication types using method -registeredAuthenticationDataTypesWithHandler:
 *
 * @constant RRBPalmSDKUserAuthenticationDataTypeNone Indicates that user has no registered authentification methods.
 * @constant RRBPalmSDKUserAuthenticationDataTypeLeftPalm Indicates that has left palm registered for authentification.
 * @constant RRBPalmSDKUserAuthenticationDataTypeRightPalm Indicates that has right palm registered for authentification.
 * @constant RRBPalmSDKUserAuthenticationDataTypePasscode Indicates that has passcode registered for authentification.
 */

typedef NS_OPTIONS(NSUInteger, RRBPalmSDKUserAuthenticationDataType) {
    RRBPalmSDKUserAuthenticationDataTypeNone        = 0,
    RRBPalmSDKUserAuthenticationDataTypeLeftPalm    = 1 << 0,
    RRBPalmSDKUserAuthenticationDataTypeRightPalm   = 1 << 1,
    RRBPalmSDKUserAuthenticationDataTypePasscode    = 1 << 2,
};

/*!
 * @class RRBPalmSDKUser
 *
 * @discussion
 * PalmID SDK class that represents an user with different registered authentication types and can be authenticated using one of them by means of public PalmID SDK UI interfaces.
 */

@interface RRBPalmSDKUser : NSObject

/*!
 * @property defaultUser
 * Getter of 'default' user for PalmID SDK 'single user' mode when application has concept of single user.
 */
+ (RRBPalmSDKUser *)defaultUser;

/*!
 * @property isDefault
 * Returns YES user instance is 'default' user for PalmID SDK 'single user' mode.
 */
- (BOOL)isDefault;

/*!
 * @property username
 * User's name as appears for registered user in PalmSDK UI.
 */
@property (nonatomic, strong, readonly) NSString *username;

/*!
 * @property userUniqueID
 * Some optional id string that can be used during user instance creation to enforce its uniqueness (e.g. user email).
 */
@property (nullable, nonatomic, strong, readonly) NSString *userUniqueID;

/*!
 * @property metadata
 * Read/write access to securely stored data associated with user.
 */
@property (nullable, nonatomic, strong) NSDictionary *metadata;

/*!
 * @method registeredAuthenticationDataTypesWithHandler:
 * Async getter of authentification types registered for the user.
 *
 * @param handler A block callback that called with found authentification types constants.
 */
- (void)registeredAuthenticationDataTypesWithHandler:(void (^)(RRBPalmSDKUserAuthenticationDataType authenticationDataType))handler;

/*!
 * @property isRegistered
 * Sync method that return YES if user has any registered for authentication (palm(s), passcode) data.
 */
- (BOOL)isRegistered;

/*!
 * @method unregister
 * Method to remove all persistent data (auth types, metadata) for the user
 */
- (void)unregister;


@end

#pragma mark - 'Multi user' mode support -

/*!
 * @typedef RRBPalmSDKUserListCompletionHandler
 * Signature of callback block used by PalmID SDK to list registered user.
 */
typedef void (^RRBPalmSDKUserListCompletionHandler)(NSArray<RRBPalmSDKUser *> *users);

/*!
 * @typedef RRBPalmSDKAddUserCompletionHandler
 * Signature of callback block used by PalmID SDK to notify about completion of new user registration.
 */
typedef void (^RRBPalmSDKAddUserCompletionHandler)(RRBPalmSDKUser *user, NSError * __nullable error);


/*!
 * @category UserManagement
 *
 * @discussion
 * This category provides methods to manage users for end applications that support 'multi user' mode.
 */

@interface RRBPalmSDKUser (UserManagement)

/*!
 * @method -initWithUsername: userUniqueID:
 * Initializer of new not registered user instance. To register created instance of user method addNewUser: should be used
 *
 * @param username
 * The name of user as will appear in Palm SDK UI.
 *
 * @param userUniqueID
 * Some optional id string that is used to enforce user uniqueness during registration (e.g. user email).
*/
- (instancetype)initWithUsername:(NSString *)username userUniqueID:(NSString * __nullable)userUniqueID;

/*!
 * @method -listUsersWithHandler:
 * Async class method to get list of registered users.
 *
 * @param handler
 * Callback block called by PalmID SDK to provide array of registered users.
 *
*/
+ (void)listUsersWithHandler:(RRBPalmSDKUserListCompletionHandler)handler;

/*!
 * @method -addNewUser: completion:
 * Async class method to register new user.
 *
 * @param user
 * Instance of new user.
 *
 * @param handler
 * Callback block called by PalmID SDK to provide result of user registration.
 *
*/
+ (void)addNewUser:(RRBPalmSDKUser *)user completion:(RRBPalmSDKAddUserCompletionHandler)handler;

/*!
 * @method -removeUser:
 * Class method to remove registered user.
 *
 * @param user
 * Instance of user to remove
 *
*/
+ (void)removeUser:(RRBPalmSDKUser *)user;

@end

NS_ASSUME_NONNULL_END
