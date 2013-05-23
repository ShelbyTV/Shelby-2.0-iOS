//
//  SPVideoExtractor.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/2/12.
//  Copyright (c) 2012 Shelby TV. All rights reserved.
//
// Extracts ONE video at a time.

#import "ShelbyVideoContainer.h"

@class Video;

typedef void (^extraction_complete_block)(NSString *videoURL, BOOL wasError);

@interface SPVideoExtractor : NSObject <UIWebViewDelegate>

/// Singleton Methods
+ (SPVideoExtractor *)sharedInstance;

//fails current extraction (if any) and removes all queued extractions.
- (void)cancelAllExtractions;

//uses cached URL unless cache is stale (ie. > 300s)
//calls block with nil if extraction fails
//high priority will jump the high priority queue
- (void)URLForVideo:(Video *)video usingBlock:(extraction_complete_block)completionBlock highPriority:(BOOL)jumpQueue;

//tries to extract URL without a completion block, caching result
//only queues processing if current queue length isn't too long
//queue this extraction LAST on a low priority queue
- (void)warmCacheForVideo:(Video *)video;
- (void)warmCacheForVideoContainer:(id<ShelbyVideoContainer>)videoContainer;

@end
