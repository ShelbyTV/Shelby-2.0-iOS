//
//  SPCacheUtility.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 12/26/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

@class SPVideoReel, SPVideoPlayer;

@interface SPCacheUtility : NSObject

- (void)addVideoFrame:(Frame*)videoFrame fromVideoPlayer:(SPVideoPlayer*)videoPlayer inReel:(SPVideoReel*)videoReel;
- (void)removeVideoFrame:(Frame*)videoFrame fromVideoPlayer:(SPVideoPlayer*)videoPlayer inReel:(SPVideoReel*)videoReel;
- (void)emptyCache;

+ (SPCacheUtility*)sharedInstance;

@end