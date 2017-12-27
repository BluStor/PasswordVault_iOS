//
//  RRBPalmSDK.h
//  PalmSDK-iOS
//
//  Copyright © 2017 RedRock Biometrics. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


/*!
 * @typedef RRBPalmSDKAuthMethod
 * Constants used to configure supported authentication methods in PalmID SDK using method -setAuthMethod:
 *
 * @constant RRBPalmSDKAuthMethodDefault Indicates that authentification should be perfomed using user's palms only.
 * @constant RRBPalmSDKAuthMethodPasscode Indicates that authentification should be perfomed using user's palms and passcode.
 */

typedef NS_OPTIONS(NSUInteger, RRBPalmSDKAuthMethod) {
    RRBPalmSDKAuthMethodDefault       = 0, // palms
    RRBPalmSDKAuthMethodPasscode      = 1 << 0,
};

/*!
 * @typedef RRBPalmSDKErrorHandler
 * Signature of callback block used by PalmID SDK to report background low level not commonly expected errors like e.g DiskFailure.
 */

typedef void (^RRBPalmSDKErrorHandler)(NSError *error);

/*!
 * @class RRBPalmSDK
 *
 * @discussion
 * PalmID SDK top level entry methods.
 */

@interface RRBPalmSDK : NSObject

/*!
 * @method -setLicenseID:
 * The method through which clients should pass their license ID provided by RedRock Biometrics
 */
+ (void)setLicenseID:(NSString *)licenseID;

/*!
 * @method -setServerURL:
 * The method through which clients can pass their RedRock Biometrics server URL to connect
 */
+ (void)setServerURL:(NSURL *)serverURL;

/*!
 * @method -setAuthMethod:
 * The method for configuration of supported authentication methods (palms, passcode)
 */
+ (void)setAuthMethod:(RRBPalmSDKAuthMethod)authMethod;

/*!
 * @method -removeAllData
 * The method for removal of all persistent data produced by PalmID SDK
 */
+ (void)removeAllData;

/*!
 * @method -setErrorHandler
 * The method to provide PalmID SDK handler that will be called in case low level internal error occurs during background PalmID SDK operation (e.g DiskFailure)
 */
+ (void)setErrorHandler:(RRBPalmSDKErrorHandler)handler;

@end


NS_ASSUME_NONNULL_END




