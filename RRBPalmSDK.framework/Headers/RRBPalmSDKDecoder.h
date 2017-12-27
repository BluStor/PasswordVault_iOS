//
//  RRBPalmSDKDecoder.h
//  PalmSDK-iOS
//
//  Created by Serhiy Redko on 4/26/17.
//  Copyright © 2017 RedRock Biometrics. All rights reserved.
//

#include <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class RRBPalmSDKModelID;
@class RRBPalmSDKModelInfo;

@protocol RRBPalmSDKDecoderHandler <NSObject>

@optional

- (void)handleDecoderDidCreated;

- (void)handlePalmDecoderError:(NSError *)error;

#if TARGET_OS_IPHONE
- (void)handleRetrievedImage:(UIImage *)image modelID:(RRBPalmSDKModelID *)modelID;
#else 
- (void)handleRetrievedImage:(NSImage *)image modelID:(RRBPalmSDKModelID *)modelID;
#endif

- (void)handleDidAddPalmInfoForModelID:(RRBPalmSDKModelID *)modelID;

- (void)handleDidRemovePalmInfoForModelID:(RRBPalmSDKModelID *)modelID;

- (void)handleNoPalmDetected;

- (void)handleDetectedPalmAtPoints:(CGPoint)a b:(CGPoint)b  c:(CGPoint)c  d:(CGPoint)d;

- (void)handlePalmMatchingStarted;
- (void)handlePalmMatchingResult:(BOOL)matched;

- (void)handlePalmModelingStarted;
- (void)handlePalmModelingInfo:(RRBPalmSDKModelInfo *)modelInfo;


@end


typedef NS_ENUM(NSInteger, RRBPalmSDKDecoderCameraOrientation) {
    RRBPalmSDKDecoderCameraOrientationHorizontal,
    RRBPalmSDKDecoderCameraOrientationVertical
};


@protocol RRBPalmSDKDecoder <NSObject>

// Decoder internal processing queue
@property (nonatomic, readonly) dispatch_queue_t queue;

@property (nonatomic, readonly) BOOL isDecoderCreated;

- (void)setHandler:(id<RRBPalmSDKDecoderHandler> __nullable)handler;

- (void)setCameraOrientation:(RRBPalmSDKDecoderCameraOrientation)orientation;

- (void)setModelMode;

- (void)setMatchModeForModels:(NSArray<RRBPalmSDKModelInfo *> *)models;

// Loads data from 640x480 BGRA camera buffer
- (NSData *)loadFrameFromBufer:(const uint8_t *)baseAddress width:(size_t)width height:(size_t)height;

// Processes loaded data from camera in library for palm detection.
// context - recepient of result callback
// this method should be called directly on -[palmDecoder queue]
- (void)processFrameData:(NSData *)data width:(size_t)width height:(size_t)height context:(__unsafe_unretained id)context;

// modelInfo can have nil for modelData in case you need extract image from just modeled session
- (void)retrieveImageForModelInfo:(RRBPalmSDKModelInfo *)modelInfo;

- (void)addPalmInfoForModelID:(RRBPalmSDKModelID *)modelID;

- (void)removePalmInfoForModelID:(RRBPalmSDKModelID *)modelID;

@end

@interface RRBPalmSDKDecoderSDK : NSObject<RRBPalmSDKDecoder>

- (instancetype)initWithLicenseID:(NSString *)licenseID serverURL:(NSURL * _Nullable)serverURL handler:(id<RRBPalmSDKDecoderHandler>)handler;

@end

NS_ASSUME_NONNULL_END
