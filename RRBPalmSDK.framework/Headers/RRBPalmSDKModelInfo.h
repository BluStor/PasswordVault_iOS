//
//  RRBPalmSDKModelInfo.h
//  PalmSDK-iOS
//
//  Created by Serhiy Redko on 6/27/17.
//  Copyright © 2017 RedRock Biometrics. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class RRBPalmSDKModelID;

@interface RRBPalmSDKModelInfo : NSObject <NSCoding>

@property (nonatomic, strong) RRBPalmSDKModelID *modelID;

@property (nonatomic, strong) NSData *modelData;

@end

NS_ASSUME_NONNULL_END
