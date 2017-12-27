//
//  RRBPalmSDKError.h
//  PalmSDK-iOS
//
//  Copyright © 2017 RedRock Biometrics. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <RRBPalmSDK/RRBPalmSDKDefines.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 * @const RRBPalmSDKErrorDomain
 * Domain for errors provided by the PalmID SDK framework.
 */

RRBPALM_EXTERN NSErrorDomain const RRBPalmSDKErrorDomain;

/*!
 * @typedef RRBPalmSDKErrorCode
 * Constants used to provide error codes for RRBPalmSDKErrorDomain
 *
 * @constant RRBPalmSDKErrorUnknown unknown error occured.
 * @constant RRBPalmSDKErrorCancelled operation was cancelled.
 * @constant RRBPalmSDKErrorInvalidLicense invalid license provided.
 * @constant RRBPalmSDKErrorCouldNotConnectToServer connect to server failed.
 * @constant RRBPalmSDKErrorMissingDataForPalmMatch no palms registered for user for which authentifcation requested.
 * @constant RRBPalmSDKErrorIncorrectInputData used input biometrics data for user are invalid and should be recreated.
 * @constant RRBPalmSDKErrorCoreSDKCallFailed internal error that shoudl be provided to support and has proper localized description.
 * @constant RRBPalmSDKErrorCameraNotAuthorized user have not granted rights to use camera.
 * @constant RRBPalmSDKErrorCameraConfigFailed error during camera configuration.
 * @constant RRBPalmSDKErrorCameraSessionFailed error during camera usage.
 * @constant RRBPalmSDKErrorCameraTorchModeUnavailable [not impl] error during torch usage.
 * @constant RRBPalmSDKErrorCryptoSecureAPIError error happened during data encryption/decryption.
 * @constant RRBPalmSDKErrorCryptoKeychainError error happened during keychain access.
 * @constant RRBPalmSDKErrorCryptoInvalidInput invalid data passed for encryption.
 * @constant RRBPalmSDKErrorUserAlreadyExists attempt to create user with the same uniqueID.
 * @constant RRBPalmSDKErrorDiskOperationFailed low level background SDK operation failed to write data on disk and save user data.
 */


typedef NS_ENUM(NSInteger, RRBPalmSDKErrorCode) {

    RRBPalmSDKErrorUnknown =        -1,
    RRBPalmSDKErrorCancelled =      -999,
    RRBPalmSDKErrorInvalidLicense = -1000,
    RRBPalmSDKErrorCouldNotConnectToServer = -1001,

    RRBPalmSDKErrorMissingDataForPalmMatch = -2000,
    RRBPalmSDKErrorIncorrectInputData = -2001,

    RRBPalmSDKErrorCoreSDKCallFailed = -3000,

    RRBPalmSDKErrorCameraNotAuthorized = -4000,
    RRBPalmSDKErrorCameraConfigFailed = -4001,
    RRBPalmSDKErrorCameraSessionFailed = -4003,
    RRBPalmSDKErrorCameraTorchModeUnavailable = -4004,

    RRBPalmSDKErrorCryptoSecureAPIError = -5000,
    RRBPalmSDKErrorCryptoKeychainError = -5001,
    RRBPalmSDKErrorCryptoInvalidInput = -5002,


    RRBPalmSDKErrorUserAlreadyExists = -6000,

    RRBPalmSDKErrorDiskOperationFailed = -7000,

};


NS_ASSUME_NONNULL_END



