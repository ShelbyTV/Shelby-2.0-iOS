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

#define SCRUB_PCT_REQUIRED_BEFORE_SEEKING .02f
#define HEIGHT_IN_PORTRAIT 88
#define HEIGHT_IN_LANDSCAPE 44

@interface VideoControlsViewController ()

@property (nonatomic, weak) VideoControlsView *controlsView;
@property (nonatomic, assign) BOOL currentlyScrubbing;
@property (nonatomic, strong) NSArray *playbackControlViews;
@property (nonatomic, strong) NSArray *actionsViews;
@property (nonatomic, weak) IBOutlet UIView *separator;
@end

@implementation VideoControlsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _videoIsPlaying = NO;
        _displayMode = VideoControlsDisplayDefault;
        _currentlyScrubbing = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _controlsView = (VideoControlsView *)self.view;
    _airPlayView = _controlsView.airPlayView;

    self.playbackControlViews = @[self.controlsView.airPlayView,
                                  self.controlsView.largePlayButton,
                                  self.controlsView.currentTimeLabel,
                                  self.controlsView.durationLabel,
                                  self.controlsView.bufferProgressView,
                                  self.controlsView.scrubheadButton
                                  ];
    self.actionsViews = @[self.controlsView.likeButton,
                          self.controlsView.unlikeButton,
                          self.controlsView.shareButton
                          ];
    [self updateViewForCurrentDisplayMode];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    //update the bits that display relative to their size
    if (CMTIME_IS_VALID(self.currentTime)) {
        [self updateScrubheadForCurrentTime];
    }
    if (CMTIMERANGE_IS_VALID(self.bufferedRange)){
        [self updateBufferProgressForCurrentBufferedRange];
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    BOOL goingToLandscape = UIInterfaceOrientationIsLandscape(toInterfaceOrientation);
    if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]) && goingToLandscape) {
        return;
    } else if (goingToLandscape) {
        NSInteger width = kShelbyFullscreenHeight;
        NSInteger height = kShelbyFullscreenWidth;
        self.controlsView.frame = CGRectMake(0, height - HEIGHT_IN_LANDSCAPE, width, HEIGHT_IN_LANDSCAPE);
        
        // Like, Unlike & Share Buttons
        self.controlsView.unlikeButton.frame = CGRectMake(15, 2, self.controlsView.unlikeButton.frame.size.width, self.controlsView.unlikeButton.frame.size.height);
        self.controlsView.likeButton.frame = self.controlsView.unlikeButton.frame;
        self.controlsView.shareButton.frame = CGRectMake(width - 15 - self.controlsView.shareButton.frame.size.width, 2, self.controlsView.shareButton.frame.size.width, self.controlsView.shareButton.frame.size.height);

        // Airplay
        self.controlsView.airPlayView.frame = CGRectMake(self.controlsView.shareButton.frame.origin.x - self.controlsView.airPlayView.frame.size.width - 8, 9, self.controlsView.airPlayView.frame.size.width, self.controlsView.airPlayView.frame.size.height);
        
        // Duration Time Label
        self.controlsView.durationLabel.frame = CGRectMake(self.controlsView.airPlayView.frame.origin.x - self.controlsView.durationLabel.frame.size.width - 8, 11, self.controlsView.durationLabel.frame.size.width, self.controlsView.durationLabel.frame.size.height);

        // Play/Pause
        self.controlsView.largePlayButton.frame = CGRectMake(self.controlsView.unlikeButton.frame.origin.x + self.controlsView.unlikeButton.frame.size.width + 7, 7, self.controlsView.largePlayButton.frame.size.width, self.controlsView.largePlayButton.frame.size.height);
        
        // Current Time Label
        self.controlsView.currentTimeLabel.frame = CGRectMake(self.controlsView.largePlayButton.frame.origin.x + self.controlsView.largePlayButton.frame.size.width + 2, 11, self.controlsView.currentTimeLabel.frame.size.width, self.controlsView.currentTimeLabel.frame.size.height);

        // Scrubber
        self.controlsView.bufferProgressView.frame = CGRectMake(self.controlsView.currentTimeLabel.frame.origin.x + self.controlsView.currentTimeLabel.frame.size.width + 5 + self.controlsView.scrubheadButton.frame.size.width/4, 17, self.controlsView.durationLabel.frame.origin.x - self.controlsView.currentTimeLabel.frame.size.width - self.controlsView.currentTimeLabel.frame.origin.x - 10 - self.controlsView.scrubheadButton.frame.size.width/4, self.controlsView.bufferProgressView.frame.size.height);

        // Non playback mode view
        self.controlsView.nonPlaybackModeView.frame = CGRectMake(self.controlsView.unlikeButton.frame.size.width + 20, 4, self.controlsView.nonPlaybackModeView.frame.size.width, self.controlsView.shareButton.frame.size.height);
       
    } else {
        NSInteger width = kShelbyFullscreenWidth;
        self.controlsView.frame = CGRectMake(0, kShelbyFullscreenHeight - HEIGHT_IN_PORTRAIT, width, HEIGHT_IN_PORTRAIT);

        // Like, Unlike & Share Buttons
        self.controlsView.unlikeButton.frame = CGRectMake(15, 47, self.controlsView.unlikeButton.frame.size.width, self.controlsView.unlikeButton.frame.size.height);
        self.controlsView.likeButton.frame = self.controlsView.unlikeButton.frame;
        self.controlsView.shareButton.frame = CGRectMake(width - 15 - self.controlsView.shareButton.frame.size.width, 47, self.controlsView.shareButton.frame.size.width, self.controlsView.shareButton.frame.size.height);
      
        // Play/Pause & Airplay Buttons
        self.controlsView.largePlayButton.frame = CGRectMake(8, 11, self.controlsView.largePlayButton.frame.size.width, self.controlsView.largePlayButton.frame.size.height);
        self.controlsView.airPlayView.frame = CGRectMake(width - self.controlsView.airPlayView.frame.size.width, 11, self.controlsView.airPlayView.frame.size.width, self.controlsView.airPlayView.frame.size.height);
        
        // Time Labels
        self.controlsView.currentTimeLabel.frame = CGRectMake(47, 14, self.controlsView.currentTimeLabel.frame.size.width, self.controlsView.currentTimeLabel.frame.size.height);
        self.controlsView.durationLabel.frame = CGRectMake(width - self.controlsView.durationLabel.frame.size.width - self.controlsView.airPlayView.frame.size.width, 14, self.controlsView.durationLabel.frame.size.width, self.controlsView.durationLabel.frame.size.height);   
     
        // Scrubber
        self.controlsView.bufferProgressView.frame = CGRectMake(self.controlsView.currentTimeLabel.frame.origin.x + self.controlsView.currentTimeLabel.frame.size.width + 5 + self.controlsView.scrubheadButton.frame.size.width/4, 20, self.controlsView.durationLabel.frame.origin.x - self.controlsView.currentTimeLabel.frame.size.width - self.controlsView.currentTimeLabel.frame.origin.x - 10 - self.controlsView.scrubheadButton.frame.size.width/4, self.controlsView.bufferProgressView.frame.size.height);
        
        // Non playback mode view
        self.controlsView.nonPlaybackModeView.frame = CGRectMake(8, 4, self.controlsView.nonPlaybackModeView.frame.size.width, self.controlsView.shareButton.frame.size.height);
    }
   
    // Overlay and seperator don't depend on orientation
    self.controlsView.overlay.frame = CGRectMake(0, 0, self.controlsView.frame.size.width, self.controlsView.frame.size.height);
    self.controlsView.separatorView.frame = CGRectMake(0, 0, self.controlsView.frame.size.width, 1);
    
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
        // If user just got into playback mode, hide nonPlaybackModeView
        if (sender == self.controlsView.nonPlaybackModePlayButton) {
            self.controlsView.nonPlaybackModeView.hidden = YES;
            [self.controlsView sendSubviewToBack:self.controlsView.nonPlaybackModeView];
        }
        [self.delegate videoControlsPlayVideoWithCurrentFocus:self];
    }
}

- (IBAction)scrubTrackTapped:(id)sender {
    UITapGestureRecognizer *gesture = (UITapGestureRecognizer *)sender;
    CGPoint position = [gesture locationInView:self.controlsView.bufferProgressView];
    CGFloat percentage = position.x / self.controlsView.bufferProgressView.frame.size.width;
    [self.delegate videoControls:self scrubCurrentVideoTo:percentage];
}

- (IBAction)scrubberButtonTouchDown:(id)sender {
    self.currentlyScrubbing = YES;
    [self.delegate videoControls:self isScrubbing:YES];
}

/* We do scrubbing very specifically to create a nice experience...
 * 0) We do not start or stop playback
 * 1) While scrubbing, the current time label always reflects the current scrub position
 * 2) User has to move scrubhead 2% away from current actual playback time before we request video player seek
 */
- (IBAction)scrubberDrag:(UIButton *)scrubHead forEvent:(UIEvent *)event {
    UITouch *scrubTouch = [[event touchesForView:self.controlsView.scrubheadButton] anyObject];
    //keep scrubber under finger
    [self.controlsView positionScrubheadForTouch:scrubTouch];

    //determine new desired playback percent/time
    CGFloat scrubPct = [self.controlsView playbackTargetPercentForTouch:scrubTouch];
    scrubPct = fmaxf(0.0, fminf(1.0, scrubPct));
    CMTime scrubTime = CMTimeMultiplyByFloat64(self.duration, scrubPct);

    //always update time label
    self.controlsView.currentTimeLabel.text = [self prettyStringForTime:scrubTime];

    //update player, but not too frequently (only when user has scrubbed 2%)
    CMTime diff = CMTimeSubtract(self.currentTime, scrubTime);
    Float64 diffPct = CMTimeGetSeconds(diff) / CMTimeGetSeconds(self.duration);
    if (fabsf(diffPct) > SCRUB_PCT_REQUIRED_BEFORE_SEEKING) {
        [self.delegate videoControls:self scrubCurrentVideoTo:scrubPct];
    }
}

- (IBAction)scrubberButtonTouchUp:(id)sender {
    self.currentlyScrubbing = NO;
    [self.delegate videoControls:self isScrubbing:NO];
}

- (IBAction)scrubberTouchUpOutside:(id)sender {
    self.currentlyScrubbing = NO;
    [self.delegate videoControls:self isScrubbing:NO];
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
            [self.controlsView.largePlayButton setImage:[UIImage imageNamed:@"pause.png"] forState:UIControlStateNormal];
        } else {
            [self.controlsView.largePlayButton setImage:[UIImage imageNamed:@"play-standard.png"] forState:UIControlStateNormal];
        }
    }
}

- (void)setBufferedRange:(CMTimeRange)bufferedRange
{
    if (!CMTimeRangeEqual(_bufferedRange, bufferedRange)) {
        _bufferedRange = bufferedRange;
        [self updateBufferProgressForCurrentBufferedRange];
    }
}

- (void)setCurrentTime:(CMTime)time
{
    if (CMTimeCompare(_currentTime, time) != 0) {
        _currentTime = time;
        //current time label reflects user touch point during scrubbing, even if playback continues
        if (!self.currentlyScrubbing) {
            self.controlsView.currentTimeLabel.text = [self prettyStringForTime:time];
            [self updateScrubheadForCurrentTime];
        }
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

- (void)updateBufferProgressForCurrentBufferedRange
{
    self.controlsView.bufferProgressView.progress = (CMTimeGetSeconds(self.bufferedRange.start) + CMTimeGetSeconds(self.bufferedRange.duration)) / CMTimeGetSeconds(self.duration);
}

- (void)updateScrubheadForCurrentTime
{
    if (!self.currentlyScrubbing) {
        [self.controlsView positionScrubheadForPercent:(CMTimeGetSeconds(self.currentTime)/CMTimeGetSeconds(self.duration))];
    } else {
        //when user is scrubbing, scrubhead is kept under their finger
    }
}

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
            [self setActionViewsAlpha:0.0 userInteractionEnabled:NO];
            [self setPlaybackControlViewsAlpha:0.0 userInteractionEnabled:NO];
            self.controlsView.overlay.hidden = YES;
            self.controlsView.nonPlaybackModeView.hidden = NO;
            self.separator.hidden = YES;
            break;
        case VideoControlsDisplayActionsOnly:
            [self setActionViewsAlpha:1.0 userInteractionEnabled:YES];
            [self setPlaybackControlViewsAlpha:0.0 userInteractionEnabled:NO];
            self.controlsView.overlay.hidden = YES;
            self.controlsView.nonPlaybackModeView.hidden = NO;
            self.separator.hidden = YES;
            break;
        case VideoControlsDisplayActionsAndPlaybackControls:
            [self setActionViewsAlpha:1.0 userInteractionEnabled:YES];
            [self setPlaybackControlViewsAlpha:1.0 userInteractionEnabled:YES];
            self.controlsView.overlay.hidden = NO;
            self.controlsView.nonPlaybackModeView.hidden = YES;
            self.separator.hidden = NO;
    }
}

- (void)setPlaybackControlViewsAlpha:(CGFloat)a userInteractionEnabled:(BOOL)interactionEnabled
{
    for (UIView *v in self.playbackControlViews) {
        v.alpha = a;
        v.userInteractionEnabled = interactionEnabled;
    }
}

- (void)setActionViewsAlpha:(CGFloat)a userInteractionEnabled:(BOOL)interactionEnabled
{
    for (UIView *v in self.actionsViews) {
        v.alpha = a;
        v.userInteractionEnabled = interactionEnabled;
    }
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
