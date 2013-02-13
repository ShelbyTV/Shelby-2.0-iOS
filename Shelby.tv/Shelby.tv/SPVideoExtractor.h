//
//  SPVideoExtractor.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/2/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

@class Video;

@interface SPVideoExtractor : NSObject

/// Singleton Methods
+ (SPVideoExtractor *)sharedInstance;

/// Video Processing Methods
- (void)queueVideo:(Video *)video;
- (void)emptyQueue;
- (void)cancelRemainingExtractions;

@end
