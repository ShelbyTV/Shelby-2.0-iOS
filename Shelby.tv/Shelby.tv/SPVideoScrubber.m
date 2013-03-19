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

- (NSString *)convertElapsedTime:(CGFloat)currentTime andDuration:(CGFloat)duration;
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
    
    CGFloat interval = .1f;
	CMTime playerDuration = [self duration];
    
	if ( CMTIME_IS_INVALID(playerDuration) ) {
        
        [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(setupScrubber) userInfo:nil repeats:NO];
        
        return;
	}
	
    CGFloat duration = CMTimeGetSeconds(playerDuration);
	if ( isfinite(duration) ) {
		CGFloat width = CGRectGetWidth([self.model.overlayView.scrubber bounds]);
		interval = 0.5f * duration / width;
	}
    
    if (self.scrubberTimeObserver) {
        [self.model.currentVideoPlayer.player removeTimeObserver:self.scrubberTimeObserver];
        [self setScrubberTimeObserver:nil];
    }
    
    self.scrubberTimeObserver = [self.model.currentVideoPlayer.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(interval, NSEC_PER_MSEC)
                                                                                                   queue:NULL /* If you pass NULL, the main queue is used. */
                                                                                              usingBlock:^(CMTime time) {
                                                                                                        
                                                                                                        [self syncScrubber];
                                                                                                  
                                                                                                    }];
}

- (void)syncScrubber
{
    
	CMTime durationTime = [self duration];
	if ( CMTIME_IS_INVALID(durationTime) ) {
        [self.model.overlayView.scrubber setValue:0.0f];
        [self.model.overlayView.playButton setImage:[UIImage imageNamed:@"playButton"] forState:UIControlStateNormal];
		return;
	}
    
	CGFloat duration = CMTimeGetSeconds(durationTime);
    
	if ( isfinite(duration) && self.model.currentVideoPlayer.player ) {
        
        // Update value of scrubber (slider and label)
		CGFloat minValue = [self.model.overlayView.scrubber minimumValue];
		CGFloat maxValue = [self.model.overlayView.scrubber maximumValue];
        CGFloat currentTime = CMTimeGetSeconds([self.model.currentVideoPlayer.player currentTime]);
        [self.model.overlayView.scrubber setValue:(maxValue - minValue) * currentTime / duration + minValue];
        [self.model.overlayView.scrubberTimeLabel setText:[self convertElapsedTime:currentTime andDuration:duration]];
        
        // Update watched later roll
        [self updateWatchedRoll];
        
        // Update button state
        if ( 0.0 == self.model.currentVideoPlayer.player.rate && self.model.currentVideoPlayer.player && self.model.currentVideoPlayer.isPlayable ) {
            
            [self.model.overlayView.playButton setImage:[UIImage imageNamed:@"playButton"] forState:UIControlStateNormal];
            
        } else {
            
            [self.model.overlayView.playButton setImage:[UIImage imageNamed:@"pauseButton"] forState:UIControlStateNormal];
        }
	}
}

- (void)stopObserving
{
    [self.model.currentVideoPlayer.player removeTimeObserver:_scrubberTimeObserver];
    [self setScrubberTimeObserver:nil];
}

#pragma mark - Scrubbing Methods
- (void)beginScrubbing
{
	[self setScrubberTimeObserver:nil];
    [self.model.currentVideoPlayer setPlaybackStartTime:kCMTimeZero];
}

- (void)scrub
{
    
    [self.model.currentVideoPlayer setPlaybackStartTime:kCMTimeZero];
    
    CMTime playerDuration = [self duration];
    
    if (CMTIME_IS_INVALID(playerDuration)) {
        return;
    }
    
    CGFloat duration = CMTimeGetSeconds(playerDuration);
    if ( isfinite(duration) ) {
        
        CGFloat minValue = [self.model.overlayView.scrubber minimumValue];
        CGFloat maxValue = [self.model.overlayView.scrubber maximumValue];
        CGFloat value = [self.model.overlayView.scrubber value];
        CGFloat time = duration * (value - minValue) / (maxValue - minValue);
        [self.model.currentVideoPlayer.player seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC)];
        
    }
}

- (void)endScrubbing
{
    
    CMTime playerDuration = [self duration];
    if (CMTIME_IS_INVALID(playerDuration)) {
        return;
    }
    
    CGFloat duration = CMTimeGetSeconds(playerDuration);
    
    if ( isfinite(duration) ) {
        CGFloat width = CGRectGetWidth([self.model.overlayView.scrubber bounds]);
        CGFloat interval = 0.5f * duration / width;
        self.scrubberTimeObserver = [self.model.currentVideoPlayer.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(interval, NSEC_PER_SEC)
                                                                                                       queue:NULL
                                                                                                  usingBlock:^(CMTime time) {

                                                                                                [self syncScrubber];
                                                                                                
                                                                                            }];
        
        
        // If video was playing before scrubbing began, make sure it continues to play, otherwise, pause the video
        ( self.model.currentVideoPlayer.isPlaying ) ? [self.model.currentVideoPlayer play] : [self.model.currentVideoPlayer pause];
     
        // Reset playbackStartTime
        [self.model.currentVideoPlayer setPlaybackStartTime:[self.model.currentVideoPlayer elapsedTime]];
        DLog(@"Current Time: %lld", (self.model.currentVideoPlayer.playbackStartTime.value / self.model.currentVideoPlayer.playbackStartTime.timescale));
        
    }
    
    // Send event to Google Analytics
    id defaultTracker = [GAI sharedInstance].defaultTracker;
    [defaultTracker sendEventWithCategory:kGAICategoryVideoPlayer
                               withAction:@"User did scrub video"
                                withLabel:[[SPModel sharedInstance].videoReel groupTitle]
                                withValue:nil];

}

#pragma mark - Playback Methods (Public)
- (CMTime)duration
{
    return [self.model.currentVideoPlayer duration];
}

#pragma mark - Playback Methods (Private)
- (NSString *)convertElapsedTime:(CGFloat)currentTime andDuration:(CGFloat)duration
{
    
    NSString *convertedTime = nil;
    NSInteger currentTimeSeconds = 0;
    NSInteger currentTimeHours = 0;
    NSInteger currentTimeMinutes = 0;
    NSInteger durationSeconds = 0;
    NSInteger durationMinutes = 0;
    NSInteger durationHours = 0;
    
    // Current Time
    currentTimeSeconds = ((NSInteger)currentTime % 60);
    currentTimeMinutes = (((NSInteger)currentTime / 60) % 60);
    currentTimeHours = ((NSInteger)currentTime / 3600);
    
    // Duration
    durationSeconds = ((NSInteger)duration % 60);
    durationMinutes = (((NSInteger)duration / 60) % 60);
    durationHours = ((NSInteger)duration / 3600);
    
    if ( durationHours > 0 ) {
        
        convertedTime = [NSString stringWithFormat:@"%.2d:%.2d:%.2d / %.2d:%.2d:%.2d", currentTimeHours, currentTimeMinutes, currentTimeSeconds, durationHours, durationMinutes, durationSeconds];
        
    } else if ( durationMinutes > 0 ) {
        
        convertedTime = [NSString stringWithFormat:@"%.2d:%.2d / %.2d:%.2d", currentTimeMinutes, currentTimeSeconds, durationMinutes, durationSeconds];
        
    } else {
        
        convertedTime = [NSString stringWithFormat:@"0:%.2d / 0:%.2d", currentTimeSeconds, durationSeconds];
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
