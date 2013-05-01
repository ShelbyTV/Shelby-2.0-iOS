//
//  SPVideoExtractor.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/2/12.
//  Copyright (c) 2012 Shelby TV. All rights reserved.
//
// Extracts ONE video at a time.

@class Video;

typedef void (^extraction_complete_block)(NSString *videoURL);

@interface SPVideoExtractor : NSObject

/// Singleton Methods
+ (SPVideoExtractor *)sharedInstance;

/// Video Processing Methods
//djs use URLForVideo:usingBlock:
//- (void)queueVideo:(Video *)video;
- (void)cancelRemainingExtractions;

//uses cached URL unless cache is stale (ie. > 300s)
//calls block with nil if extraction fails
- (void)URLForVideo:(Video *)video usingBlock:(extraction_complete_block)completionBlock;

@end
