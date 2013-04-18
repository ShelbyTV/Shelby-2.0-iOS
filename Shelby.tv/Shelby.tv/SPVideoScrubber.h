//
//  SPVideoScrubber.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 2/7/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SPVideoScrubber : NSObject

@property (nonatomic) id scrubberTimeObserver;

/// Singleton Methods
+ (SPVideoScrubber *)sharedInstance;

/// Persistance Methods
- (void)setupScrubber;
- (void)syncScrubber;
- (void)stopObserving;

/// Scrubbing Methods
- (void)seekToTimeWithPercentage:(CGFloat)percentage;

/// Player Methods
- (CMTime)duration;

@end
