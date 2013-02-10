//
//  SPVideoScrubber.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 2/7/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import "SPVideoScrubber.h"
#import "SPModel.h"

@interface SPVideoScrubber ()

@property (weak, nonatomic) SPModel *model;

- (NSString *)convertElapsedTime:(CGFloat)currentTime andDuration:(CGFloat)duration;

@end

@implementation SPVideoScrubber

#pragma mark - Singleton Methods
+ (SPVideoScrubber*)sharedInstance
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
	CMTime playerDuration = [self elapsedDuration];
    
	if ( CMTIME_IS_INVALID(playerDuration) ) {
        
        [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(setupScrubber) userInfo:nil repeats:NO];
        
        return;
	}
	
    CGFloat duration = CMTimeGetSeconds(playerDuration);
	if ( isfinite(duration) ) {
		CGFloat width = CGRectGetWidth([self.model.overlayView.scrubber bounds]);
		interval = 0.5f * duration / width;
	}
    
    
    self.scrubberTimeObserver = [self.model.currentVideoPlayer.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(interval, NSEC_PER_MSEC)
                                                                                                         queue:NULL /* If you pass NULL, the main queue is used. */
                                                                                                    usingBlock:^(CMTime time) {
                                                                                                        
                                                                                                        [self syncScrubber];
                                                                                                        
                                                                                                    }];
}

- (void)syncScrubber
{
    
	CMTime playerDuration = [self elapsedDuration];
	if ( CMTIME_IS_INVALID(playerDuration) ) {
        [self.model.overlayView.scrubber setValue:0.0f];
        [self.model.overlayView.playButton setImage:[UIImage imageNamed:@"playButton"] forState:UIControlStateNormal];
		return;
	}
    
	double duration = CMTimeGetSeconds(playerDuration);
    
	if ( isfinite(duration) && self.model.currentVideoPlayer.player ) {
        
        // Update value of scrubber (slider and label)
		CGFloat minValue = [self.model.overlayView.scrubber minimumValue];
		CGFloat maxValue = [self.model.overlayView.scrubber maximumValue];
        
        CGFloat currentTime = CMTimeGetSeconds([self.model.currentVideoPlayer.player currentTime]);
        CGFloat duration = CMTimeGetSeconds([self.model.currentVideoPlayer.player.currentItem duration]);
        
        [self.model.overlayView.scrubber setValue:(maxValue - minValue) * currentTime / duration + minValue];
        [self.model.overlayView.scrubberTimeLabel setText:[self convertElapsedTime:currentTime andDuration:duration]];
        
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
    [self setModel:nil];
    
}

#pragma mark - Scrubbing Methods
- (void)beginScrubbing
{
	self.scrubberTimeObserver = nil;
}

- (void)scrub
{
    
    CMTime playerDuration = [self elapsedDuration];
    
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
    
    CMTime playerDuration = [self elapsedDuration];
    if (CMTIME_IS_INVALID(playerDuration)) {
        return;
    }
    
    CGFloat duration = CMTimeGetSeconds(playerDuration);
    
    if ( isfinite(duration) ) {
        CGFloat width = CGRectGetWidth([self.model.overlayView.scrubber bounds]);
        CGFloat tolerance = 0.5f * duration / width;
        self.scrubberTimeObserver = [self.model.currentVideoPlayer.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(tolerance, NSEC_PER_SEC)
                                                                                                                     queue:NULL
                                                                                                                usingBlock:^(CMTime time) {
                                                                                                                    
                                                                                                // Sync the scrubber to the currentVideoPlayer
                                                                                                [self syncScrubber];
                                                                                                
                                                                                            }];
        
        
        // If video was playing before scrubbing began, make sure it continues to play, otherwise, pause the video
        ( self.model.currentVideoPlayer.isPlaying ) ? [self.model.currentVideoPlayer play] : [self.model.currentVideoPlayer pause];
        
    }

}

#pragma mark - Playback Methods (Public)
- (CMTime)elapsedDuration
{
    
    if ( [self.model.currentVideoPlayer.player currentItem].status == AVPlayerItemStatusReadyToPlay ) {
        
		return [self.model.currentVideoPlayer.player.currentItem duration];
	}
	
	return kCMTimeInvalid;
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

#pragma mark - Accessor Methods
- (SPModel*)model
{
    return [SPModel sharedInstance];
}

@end
