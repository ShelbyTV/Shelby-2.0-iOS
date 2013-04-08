//
//  SPVideoScrubber.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 2/7/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import "SPVideoScrubber.h"
#import "SPModel.h"
#import "SPVideoReel.h"

@interface SPVideoScrubber ()

@property (weak, nonatomic) SPModel *model;

- (NSString *)convertElapsedTimeToString:(CGFloat)elapsedTime;
- (NSString *)convertDurationToString:(CGFloat)duration;

- (void)updateWatchedRoll;

@end

@implementation SPVideoScrubber

#pragma mark - Singleton Methods
+ (SPVideoScrubber *)sharedInstance
{
    static SPVideoScrubber *sharedInstance = nil;
    static dispatch_once_t scrubberToken = 0;
    dispatch_once(&scrubberToken, ^{
        sharedInstance = [[super allocWithZone:NULL] init];
    });
    
    return sharedInstance;
}


#pragma mark - Persistance Methods
- (void)setupScrubber
{
    [self stopObserving];
    
    CGFloat interval = .1f;
    
	if ( CMTIME_IS_INVALID([self duration]) ) {
        [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(setupScrubber) userInfo:nil repeats:NO];
        return;
	}
	
    CGFloat duration = CMTimeGetSeconds([self duration]);
	if ( isfinite(duration) ) {
        if ( self.model.overlayView.elapsedProgressView ) {
            CGFloat width = CGRectGetWidth([self.model.overlayView.elapsedProgressView bounds]);
            interval = 0.5f * duration / width;
        } else {
            interval = 0.5f;
        }
	}
    
    self.scrubberTimeObserver = [self.model.currentVideoPlayer.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(interval, NSEC_PER_MSEC)
                                                                                                   queue:NULL /* If you pass NULL, the main queue is used. */
                                                                                              usingBlock:^(CMTime time) {
                                                                                                        
                                                                                                        [self syncScrubber];
                                                                                                  
                                                                                                    }];
}

- (void)syncScrubber
{
    CGFloat duration = CMTimeGetSeconds([self duration]);
    
	if ( CMTIME_IS_INVALID([self duration]) ) {
        [self.model.overlayView.elapsedProgressView setProgress:0.0f];
		return;
	}
    
	if ( isfinite(duration) && self.model.currentVideoPlayer.player ) {
        
        CGFloat elapsedTime = CMTimeGetSeconds([self.model.currentVideoPlayer.player currentTime]);
        CGFloat progressValue = elapsedTime/duration;

        self.model.overlayView.elapsedTimeLabel.text = [self convertElapsedTimeToString:elapsedTime];
        self.model.overlayView.totalDurationLabel.text = [self convertElapsedTimeToString:duration];
        
        if ( progressValue > [self.model.overlayView.elapsedProgressView progress] ) {
            
            [self.model.overlayView.elapsedProgressView setProgress:progressValue animated:YES];
            
        }
        
        // Update watched later roll
        [self updateWatchedRoll];
        
    }
}

- (void)stopObserving
{
    [self.model.currentVideoPlayer.player removeTimeObserver:_scrubberTimeObserver];
    [self setScrubberTimeObserver:nil];
}

#pragma mark - Scrubbing Methods
- (void)seekToTimeWithPercentage:(CGFloat)percentage
{
    CMTime durationTime = [self duration];
    
    if (CMTIME_IS_INVALID(durationTime)) {
        return;
    }

    CGFloat duration = CMTimeGetSeconds(durationTime);
    
    if (isfinite(duration)) {
        CGFloat time = percentage * duration;
        [self.model.currentVideoPlayer.player seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC)];
        [self.model.overlayView.elapsedProgressView setProgress:percentage];
    }
}

- (void)beginScrubbing
{
//	[self setScrubberTimeObserver:nil];
//    [self.model.currentVideoPlayer setPlaybackStartTime:kCMTimeZero];
}

- (void)scrub
{
//    
//    [self.model.currentVideoPlayer setPlaybackStartTime:kCMTimeZero];
//    
//    CMTime playerDuration = [self duration];
//    
//    if (CMTIME_IS_INVALID(playerDuration)) {
//        return;
//    }
//    
//    CGFloat duration = CMTimeGetSeconds(playerDuration);
//    if ( isfinite(duration) ) {
//        
//        CGFloat minValue = [self.model.overlayView.scrubber minimumValue];
//        CGFloat maxValue = [self.model.overlayView.scrubber maximumValue];
//        CGFloat value = [self.model.overlayView.scrubber value];
//        CGFloat time = duration * (value - minValue) / (maxValue - minValue);
//        [self.model.currentVideoPlayer.player seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC)];
//        
//    }
}

- (void)endScrubbing
{
//    
//    CMTime playerDuration = [self duration];
//    if (CMTIME_IS_INVALID(playerDuration)) {
//        return;
//    }
//    
//    CGFloat duration = CMTimeGetSeconds(playerDuration);
//    
//    if ( isfinite(duration) ) {
//        CGFloat width = CGRectGetWidth([self.model.overlayView.scrubber bounds]);
//        CGFloat interval = 0.5f * duration / width;
//        self.scrubberTimeObserver = [self.model.currentVideoPlayer.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(interval, NSEC_PER_SEC)
//                                                                                                       queue:NULL
//                                                                                                  usingBlock:^(CMTime time) {
//
//                                                                                                [self syncScrubber];
//                                                                                                
//                                                                                            }];
//        
//        
//        // If video was playing before scrubbing began, make sure it continues to play, otherwise, pause the video
//        ( self.model.currentVideoPlayer.isPlaying ) ? [self.model.currentVideoPlayer play] : [self.model.currentVideoPlayer pause];
//     
//        // Reset playbackStartTime
//        [self.model.currentVideoPlayer setPlaybackStartTime:[self.model.currentVideoPlayer elapsedTime]];
//        DLog(@"Current Time: %lld", (self.model.currentVideoPlayer.playbackStartTime.value / self.model.currentVideoPlayer.playbackStartTime.timescale));
//        
//    }
//    
//    // Send event to Google Analytics
//    id defaultTracker = [GAI sharedInstance].defaultTracker;
//    [defaultTracker sendEventWithCategory:kGAICategoryVideoPlayer
//                               withAction:@"User did scrub video"
//                                withLabel:[[SPModel sharedInstance].videoReel groupTitle]
//                                withValue:nil];
//
}

#pragma mark - Playback Methods (Public)
- (CMTime)duration
{
    return [self.model.currentVideoPlayer duration];
}

#pragma mark - Playback Methods (Private)
- (NSString *)convertElapsedTimeToString:(CGFloat)elapsedTime
{
    NSString *convertedTime = nil;
    NSInteger elapsedTimeSeconds = 0;
    NSInteger elapsedTimeHours = 0;
    NSInteger elapsedTimeMinutes = 0;
    
    elapsedTimeSeconds = ((NSInteger)elapsedTime % 60);
    elapsedTimeMinutes = (((NSInteger)elapsedTime / 60) % 60);
    elapsedTimeHours = ((NSInteger)elapsedTime / 3600);
    
    if ( elapsedTimeHours > 0 ) {
        
        convertedTime = [NSString stringWithFormat:@"%.2d:%.2d:%.2d", elapsedTimeHours, elapsedTimeMinutes, elapsedTimeSeconds];
        
    } else if ( elapsedTimeMinutes > 0 ) {
        
        convertedTime = [NSString stringWithFormat:@"%.2d:%.2d", elapsedTimeMinutes, elapsedTimeSeconds];
        
    } else {
        
        convertedTime = [NSString stringWithFormat:@"0:%.2d", elapsedTimeSeconds];
    }
    
    
    return convertedTime;
}

- (NSString *)convertDurationToString:(CGFloat)duration
{
    NSString *convertedTime = nil;
    NSInteger durationSeconds = 0;
    NSInteger durationMinutes = 0;
    NSInteger durationHours = 0;

    durationSeconds = ((NSInteger)duration % 60);
    durationMinutes = (((NSInteger)duration / 60) % 60);
    durationHours = ((NSInteger)duration / 3600);
    
    if ( durationHours > 0 ) {
        
        convertedTime = [NSString stringWithFormat:@"%.2d:%.2d:%.2d", durationHours, durationMinutes, durationSeconds];
        
    } else if ( durationMinutes > 0 ) {
        
        convertedTime = [NSString stringWithFormat:@"%.2d:%.2d", durationMinutes, durationSeconds];
        
    } else {
        
        convertedTime = [NSString stringWithFormat:@"0:%.2d", durationSeconds];
    }
    
    return convertedTime;
}

- (void)updateWatchedRoll
{
    
    // Only update watched roll if user exists (watched roll doesn't exist for logged-out users)
    if ( [[NSUserDefaults standardUserDefaults] boolForKey:kShelbyDefaultUserAuthorized] ) {
    
        CMTime elapsedTime = [self.model.currentVideoPlayer elapsedTime];
        CGFloat elapsedSeconds = elapsedTime.value / elapsedTime.timescale;
        CGFloat startSeconds = self.model.currentVideoPlayer.playbackStartTime.value / self.model.currentVideoPlayer.playbackStartTime.timescale;
        
        BOOL elapsedCondition = elapsedSeconds > 0.0f;
        BOOL differenceCondition = (NSUInteger)fabs(elapsedSeconds - startSeconds) % 5 == 0;
        BOOL equalityCondition = !(elapsedSeconds == startSeconds);
        
        if ( elapsedCondition && differenceCondition && equalityCondition ) {
            
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            NSManagedObjectContext *context = [appDelegate context];
            NSManagedObjectID *objectID = [self.model.currentVideoPlayer.videoFrame objectID];
            Frame *frame = (Frame *)[context existingObjectWithID:objectID error:nil];
            [ShelbyAPIClient postFrameToWatchedRoll:frame.frameID];
            
            // Reset startSeconds
            [self.model.currentVideoPlayer setPlaybackStartTime:[self.model.currentVideoPlayer elapsedTime]];
            
            DLog(@"Posting videoFrame %@ to watched roll", frame.frameID);
            
        }
    }
}

#pragma mark - Accessor Methods
- (SPModel *)model
{
    return [SPModel sharedInstance];
}

@end
