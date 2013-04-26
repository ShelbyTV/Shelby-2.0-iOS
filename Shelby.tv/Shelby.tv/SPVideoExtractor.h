//
//  SPVideoExtractor.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/2/12.
//  Copyright (c) 2012 Shelby TV. All rights reserved.
//

@class Video;

@interface SPVideoExtractor : NSObject

/// Singleton Methods
+ (SPVideoExtractor *)sharedInstance;

/// Video Processing Methods
- (void)queueVideo:(Video *)video;
- (void)cancelRemainingExtractions;

@end
