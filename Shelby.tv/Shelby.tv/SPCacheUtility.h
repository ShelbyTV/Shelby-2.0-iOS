//
//  SPCacheUtility.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 12/26/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

@class SPOverlayView;

@interface SPCacheUtility : NSObject

- (void)addVideoFrame:(Frame*)videoFrame inOverlay:(SPOverlayView*)overlayView;
- (void)removeVideoFrame:(Frame*)videoFrame inOverlay:(SPOverlayView*)overlayView;

+ (SPCacheUtility*)sharedInstance;

@end