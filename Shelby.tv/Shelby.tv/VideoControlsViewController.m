//
//  VideoControlsViewController.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 7/1/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "VideoControlsViewController.h"
#import "DashboardEntry+Helper.h"
#import "VideoControlsView.h"

@interface VideoControlsViewController ()

@property (nonatomic, weak) VideoControlsView *controlsView;

@end

@implementation VideoControlsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _videoIsPlaying = NO;
        _displayMode = VideoControlsDisplayDefault;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _controlsView = (VideoControlsView *)self.view;
    _airPlayView = _controlsView.airPlayView;
    [self updateViewForCurrentDisplayMode];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setDisplayMode:(VideoControlsDisplayMode)displayMode
{
    if (_displayMode != displayMode) {
        _displayMode = displayMode;
        [self updateViewForCurrentDisplayMode];
    }
}

- (void)setCurrentEntity:(id<ShelbyVideoContainer>)currentEntity
{
    if (_currentEntity != currentEntity) {
        _currentEntity = currentEntity;
        [self updateViewForCurrentEntity];
    }
}
#pragma mark - XIB actions

- (IBAction)largePlayButtonTapped:(id)sender {
    if (self.videoIsPlaying) {
        [self.delegate videoControlsPauseCurrentVideo:self];
    } else {
        [self.delegate videoControlsPlayVideoWithCurrentFocus:self];
    }
}

- (IBAction)scrubTrackTapped:(id)sender {
    UITapGestureRecognizer *gesture = (UITapGestureRecognizer *)sender;
    CGPoint position = [gesture locationInView:self.controlsView.bufferProgressView];
    CGFloat percentage = position.x / self.controlsView.bufferProgressView.frame.size.width;
    [self.delegate videoControls:self scrubCurrentVideoTo:percentage];
}

- (IBAction)likeTapped:(id)sender {
    [self.delegate videoControlsLikeCurrentVideo:self];
    [self updateViewForCurrentEntity];
}

- (IBAction)unlikeTapped:(id)sender {
    [self.delegate videoControlsUnlikeCurrentVideo:self];
    [self updateViewForCurrentEntity];
}

- (IBAction)shareTapped:(id)sender {
    [self.delegate videoControlsShareCurrentVideo:self];
}

#pragma mark - VideoPlaybackDelegate

- (void)setVideoIsPlaying:(BOOL)videoIsPlaying
{
    if (_videoIsPlaying != videoIsPlaying) {
        _videoIsPlaying = videoIsPlaying;
        if (_videoIsPlaying) {
            [self.controlsView.largePlayButton setTitle:@"pause" forState:UIControlStateNormal];
        } else {
            [self.controlsView.largePlayButton setTitle:@"play" forState:UIControlStateNormal];
        }
    }
}

- (void)setBufferedRange:(CMTimeRange)bufferedRange
{
    if (!CMTimeRangeEqual(_bufferedRange, bufferedRange)) {
        _bufferedRange = bufferedRange;
        self.controlsView.bufferProgressView.progress = (CMTimeGetSeconds(bufferedRange.start) + CMTimeGetSeconds(bufferedRange.duration)) / CMTimeGetSeconds(self.duration);
    }
}

- (void)setCurrentTime:(CMTime)time
{
    if (CMTimeCompare(_currentTime, time) != 0) {
        _currentTime = time;
        self.controlsView.currentTimeLabel.text = [self prettyStringForTime:time];
        //TODO: update the position of the scrub head
        //pct = CMTimeGetSeconds(time)/CMTimeGetSeconds(self.duration);
    }
}

- (void)setDuration:(CMTime)duration
{
    if (CMTimeCompare(_duration, duration) !=0) {
        _duration = duration;
        self.controlsView.durationLabel.text = [self prettyStringForTime:duration];
    }
}

#pragma mark - Visual Helpers

- (void)updateViewForCurrentEntity
{
    if (self.currentEntity){
        BOOL isLiked = [[Frame frameForEntity:self.currentEntity] videoIsLiked];
        self.controlsView.likeButton.hidden = isLiked;
        self.controlsView.unlikeButton.hidden = !isLiked;
    }
}

- (void)updateViewForCurrentDisplayMode
{
    //NB: self.view is part of our plublic API, so bear in mind that anybody from
    //    the outside world may use self.view to adjust our alpha wholistically
    switch (_displayMode) {
        case VideoControlsDisplayDefault:
            [self setActionViewsAlpha:0.0];
            [self setPlaybackControlViewsAlpha:0.0];
            break;
        case VideoControlsDisplayActionsOnly:
            [self setActionViewsAlpha:1.0];
            [self setPlaybackControlViewsAlpha:0.0];
            break;
        case VideoControlsDisplayActionsAndPlaybackControls:
            [self setActionViewsAlpha:1.0];
            [self setPlaybackControlViewsAlpha:1.0];
    }
}

- (void)setPlaybackControlViewsAlpha:(CGFloat)a
{
    self.controlsView.airPlayView.alpha = a;
    self.controlsView.largePlayButton.alpha = a;
    self.controlsView.currentTimeLabel.alpha = a;
    self.controlsView.durationLabel.alpha = a;
    self.controlsView.bufferProgressView.alpha = a;
}

- (void)setActionViewsAlpha:(CGFloat)a
{
    self.controlsView.likeButton.alpha = a;
    self.controlsView.unlikeButton.alpha = a;
    self.controlsView.shareButton.alpha = a;
}

#pragma mark - Text Helpers

- (NSString *)prettyStringForTime:(CMTime)t
{
    NSInteger time = (NSInteger)CMTimeGetSeconds(t);

    NSString *convertedTime = nil;
    NSInteger elapsedTimeSeconds = 0;
    NSInteger elapsedTimeHours = 0;
    NSInteger elapsedTimeMinutes = 0;

    elapsedTimeSeconds = ((NSInteger)time % 60);
    elapsedTimeMinutes = (((NSInteger)time / 60) % 60);
    elapsedTimeHours = ((NSInteger)time / 3600);

    if (elapsedTimeHours > 0) {
        convertedTime = [NSString stringWithFormat:@"%.2d:%.2d:%.2d", elapsedTimeHours, elapsedTimeMinutes, elapsedTimeSeconds];
    } else if (elapsedTimeMinutes > 0) {
        convertedTime = [NSString stringWithFormat:@"%.2d:%.2d", elapsedTimeMinutes, elapsedTimeSeconds];
    } else {
        convertedTime = [NSString stringWithFormat:@"0:%.2d", elapsedTimeSeconds];
    }

    return convertedTime;
}

@end
