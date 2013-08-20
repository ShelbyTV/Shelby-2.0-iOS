//
//  VideoControlsViewController.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 7/1/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "VideoControlsViewController.h"
#import "DashboardEntry+Helper.h"
#import <MediaPlayer/MediaPlayer.h>
#import "VideoControlsView.h"

#define SCRUB_PCT_REQUIRED_BEFORE_SEEKING .02f
#define HEIGHT_IN_PORTRAIT 88
#define HEIGHT_IN_LANDSCAPE 44

@interface VideoControlsViewController ()

@property (nonatomic, weak) VideoControlsView *controlsView;
@property (nonatomic, assign) BOOL currentlyScrubbing;
@property (nonatomic, strong) NSArray *playbackControlViews;
@property (nonatomic) UIButton *airPlayButton;
@property (nonatomic, strong) NSArray *actionsViews;
@property (nonatomic, weak) IBOutlet UIView *separator;
@property (strong, nonatomic) UIActivityIndicatorView *shareActivityIndicator;
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
                                  self.controlsView.playPauseButton,
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
    [self setupAirPlay];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self adjustVideoControlsForLandscape:UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    [self updateScrubheadForCurrentTime];
    [self updateBufferProgressForCurrentBufferedRange];
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

- (void)adjustVideoControlsForLandscape:(BOOL)landscapeOrientation
{
    if (landscapeOrientation) {
        NSInteger width = kShelbyFullscreenHeight;
        NSInteger height = kShelbyFullscreenWidth;
        self.controlsView.frame = CGRectMake(0, height - self.controlsView.frame.size.height, width, self.controlsView.frame.size.height);
        self.controlsView.overlay.frame = CGRectMake(0, self.controlsView.frame.size.height - HEIGHT_IN_LANDSCAPE, self.controlsView.frame.size.width, HEIGHT_IN_LANDSCAPE);
        self.controlsView.separatorView.frame = CGRectMake(0, self.controlsView.overlay.frame.origin.y, width, 1);

        // Like, Unlike & Share Buttons
        self.controlsView.unlikeButton.frame = CGRectMake(15, 46, self.controlsView.unlikeButton.frame.size.width, self.controlsView.unlikeButton.frame.size.height);
        self.controlsView.likeButton.frame = self.controlsView.unlikeButton.frame;
        self.controlsView.shareButton.frame = CGRectMake(width - 15 - self.controlsView.shareButton.frame.size.width, self.controlsView.unlikeButton.frame.origin.y, self.controlsView.shareButton.frame.size.width, self.controlsView.shareButton.frame.size.height);
        
        // Play/Pause
        self.controlsView.playPauseButton.frame = CGRectMake(self.controlsView.unlikeButton.frame.origin.x + self.controlsView.unlikeButton.frame.size.width + 7, 51, self.controlsView.playPauseButton.frame.size.width, self.controlsView.playPauseButton.frame.size.height);
        
        // Current Time Label
        self.controlsView.currentTimeLabel.frame = CGRectMake(self.controlsView.playPauseButton.frame.origin.x + self.controlsView.playPauseButton.frame.size.width + 2, 55, self.controlsView.currentTimeLabel.frame.size.width, self.controlsView.currentTimeLabel.frame.size.height);

        // Airplay
        self.controlsView.airPlayView.frame = CGRectMake(self.controlsView.shareButton.frame.origin.x - self.controlsView.airPlayView.frame.size.width - 20, 55, self.controlsView.airPlayView.frame.size.width, self.controlsView.airPlayView.frame.size.height);
        
        // Duration Time Label depends on whether airplay button is visible or not
        [self changeLayoutDepandentUponVisibleAirplayWithOrientationLandscape:YES];

    } else {
        NSInteger width = kShelbyFullscreenWidth;
        self.controlsView.frame = CGRectMake(0, kShelbyFullscreenHeight - HEIGHT_IN_PORTRAIT, width, HEIGHT_IN_PORTRAIT);
        self.controlsView.overlay.frame = CGRectMake(0, 0, self.controlsView.frame.size.width, self.controlsView.frame.size.height);
        self.controlsView.separatorView.frame = CGRectMake(0, 0, self.controlsView.frame.size.width, 1);

        // Like, Unlike & Share Buttons
        self.controlsView.unlikeButton.frame = CGRectMake(15, 47, self.controlsView.unlikeButton.frame.size.width, self.controlsView.unlikeButton.frame.size.height);
        self.controlsView.likeButton.frame = self.controlsView.unlikeButton.frame;
        self.controlsView.shareButton.frame = CGRectMake(width - 15 - self.controlsView.shareButton.frame.size.width, 47, self.controlsView.shareButton.frame.size.width, self.controlsView.shareButton.frame.size.height);
        
        // Play/Pause & Airplay Buttons
        self.controlsView.playPauseButton.frame = CGRectMake(15, 11, self.controlsView.playPauseButton.frame.size.width, self.controlsView.playPauseButton.frame.size.height);
        self.controlsView.airPlayView.frame = CGRectMake(width - self.controlsView.airPlayView.frame.size.width - 15, 14, self.controlsView.airPlayView.frame.size.width, self.controlsView.airPlayView.frame.size.height);
        
        // Time Labels
        self.controlsView.currentTimeLabel.frame = CGRectMake(45, 14, self.controlsView.currentTimeLabel.frame.size.width, self.controlsView.currentTimeLabel.frame.size.height);
        
        // Duration Time Label depends on whether airplay button is visible or not
        [self changeLayoutDepandentUponVisibleAirplayWithOrientationLandscape:NO];
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    BOOL goingToLandscape = UIInterfaceOrientationIsLandscape(toInterfaceOrientation);
    if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]) && goingToLandscape) {
        return;
    }

    [self adjustVideoControlsForLandscape:goingToLandscape];
}

- (void)changeLayoutDepandentUponVisibleAirplayWithOrientationLandscape:(BOOL)landscapeOrientation
{
    BOOL airplayVisible = NO;
    if (self.airPlayButton.alpha == 1) {
        airplayVisible = YES;
    }
    
    if (landscapeOrientation) {
        // Duration Time Label
        NSInteger xOriginForDurationLabel = 0;
        if (airplayVisible) {
            xOriginForDurationLabel = self.controlsView.airPlayView.frame.origin.x - self.controlsView.durationLabel.frame.size.width - 8;
        } else {
            xOriginForDurationLabel = self.controlsView.shareButton.frame.origin.x - self.controlsView.durationLabel.frame.size.width - 8;
        }

        // Duration Label
        self.controlsView.durationLabel.frame = CGRectMake(xOriginForDurationLabel, 55, self.controlsView.durationLabel.frame.size.width, self.controlsView.durationLabel.frame.size.height);

        // Scrubber
        self.controlsView.bufferProgressView.frame = CGRectMake(self.controlsView.currentTimeLabel.frame.origin.x + self.controlsView.currentTimeLabel.frame.size.width + 5 + self.controlsView.scrubheadButton.frame.size.width/4, 63, self.controlsView.durationLabel.frame.origin.x - self.controlsView.currentTimeLabel.frame.size.width - self.controlsView.currentTimeLabel.frame.origin.x - 15 - self.controlsView.scrubheadButton.frame.size.width/4, self.controlsView.bufferProgressView.frame.size.height);
    } else {
        NSInteger width = kShelbyFullscreenWidth;
        NSInteger xOriginForDurationLabel = 0;
        if (airplayVisible) {
            xOriginForDurationLabel = width - self.controlsView.durationLabel.frame.size.width - self.controlsView.airPlayView.frame.size.width - 30;
        } else {
            xOriginForDurationLabel = width - self.controlsView.durationLabel.frame.size.width - 15;
        }
        
        // Duration Label
        self.controlsView.durationLabel.frame = CGRectMake(xOriginForDurationLabel, 14, self.controlsView.durationLabel.frame.size.width, self.controlsView.durationLabel.frame.size.height);

        // Scrubber
        self.controlsView.bufferProgressView.frame = CGRectMake(self.controlsView.currentTimeLabel.frame.origin.x + self.controlsView.currentTimeLabel.frame.size.width + 5 + self.controlsView.scrubheadButton.frame.size.width/4, 22, self.controlsView.durationLabel.frame.origin.x - self.controlsView.currentTimeLabel.frame.size.width - self.controlsView.currentTimeLabel.frame.origin.x - 15 - self.controlsView.scrubheadButton.frame.size.width/4, self.controlsView.bufferProgressView.frame.size.height);
    }
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
        [self resetVideoControlsToInitialConditions];
        [self updateViewForCurrentEntity];
    }
}

#pragma mark - Airplay Setup
- (void)setupAirPlay
{
    [VideoControlsViewController sendEventWithCategory:kAnalyticsCategoryPrimaryUX
                                            withAction:kAnalyticsUXTapAirplay
                                   withNicknameAsLabel:YES];

    // Instantiate AirPlay button for MPVolumeView
    MPVolumeView *volumeView = [[MPVolumeView alloc] initWithFrame:self.airPlayView.bounds];
    [volumeView setShowsVolumeSlider:NO];
    [volumeView setShowsRouteButton:YES];
    [self.airPlayView addSubview:volumeView];
    
    for (UIView *view in volumeView.subviews) {
        if ( [view isKindOfClass:[UIButton class]] ) {
            self.airPlayButton = (UIButton *)view;
            [self.airPlayButton addObserver:self forKeyPath:@"alpha" options:NSKeyValueObservingOptionNew context:nil];
            [self adjustForAirplay];
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self.airPlayButton) {
        [self adjustForAirplay];
    }
}

- (void)adjustForAirplay
{
    if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
        // Duration Time Label
        [self changeLayoutDepandentUponVisibleAirplayWithOrientationLandscape:YES];
    } else {
        [self changeLayoutDepandentUponVisibleAirplayWithOrientationLandscape:NO];
    }
}


#pragma mark - XIB actions

- (IBAction)playPauseButtonTapped:(id)sender
{
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

- (IBAction)scrubberButtonTouchDown:(id)sender {
    self.currentlyScrubbing = YES;
    [self.delegate videoControls:self isScrubbing:YES];
}

- (IBAction)scrubberDrag:(UIButton *)scrubHead forEvent:(UIEvent *)event {
    UITouch *scrubTouch = [[event touchesForView:self.controlsView.scrubheadButton] anyObject];
    //keep scrubber under finger
    [self.controlsView positionScrubheadForTouch:scrubTouch];

    //determine new desired playback percent/time
    CGFloat scrubPct = [self.controlsView playbackTargetPercentForTouch:scrubTouch];
    CMTime scrubTime = CMTimeMultiplyByFloat64(self.duration, scrubPct);

    //updates cur time and countdown time
    self.currentTime = scrubTime;
    [self.delegate videoControls:self scrubCurrentVideoTo:scrubPct];
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
    _shareActivityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.shareActivityIndicator.frame = self.controlsView.shareButton.frame;
    [self.shareActivityIndicator startAnimating];
    [self.controlsView addSubview:self.shareActivityIndicator];
    self.controlsView.shareButton.hidden = YES;
    [self.delegate videoControlsShareCurrentVideo:self];
}

- (void)resetShareButton
{
    [self.shareActivityIndicator removeFromSuperview];
    self.shareActivityIndicator = nil;
    self.controlsView.shareButton.hidden = NO;
}

#pragma mark - VideoPlaybackDelegate

- (void)setVideoIsPlaying:(BOOL)videoIsPlaying
{
    if (_videoIsPlaying != videoIsPlaying) {
        _videoIsPlaying = videoIsPlaying;
        if (_videoIsPlaying) {
            [self.controlsView.playPauseButton setImage:[UIImage imageNamed:@"pause.png"] forState:UIControlStateNormal];
        } else {
            [self.controlsView.playPauseButton setImage:[UIImage imageNamed:@"play-standard.png"] forState:UIControlStateNormal];
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
        self.controlsView.currentTimeLabel.text = [self prettyStringForTime:time];
        self.controlsView.durationLabel.text = [NSString stringWithFormat:@"-%@", [self prettyStringForTime:(CMTimeSubtract(self.duration, self.currentTime))]];
        [self updateScrubheadForCurrentTime];
    }
}

- (void)setDuration:(CMTime)duration
{
    if (CMTimeCompare(_duration, duration) != 0) {
        _duration = duration;
        self.controlsView.durationLabel.text = [NSString stringWithFormat:@"-%@", [self prettyStringForTime:duration]];
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

- (void)resetVideoControlsToInitialConditions
{
    self.currentTime = CMTimeMake(0, NSEC_PER_MSEC);
    self.bufferedRange = CMTimeRangeMake(CMTimeMake(0, NSEC_PER_MSEC), CMTimeMake(0, NSEC_PER_MSEC));
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
            self.separator.hidden = YES;
            break;
        case VideoControlsDisplayActionsOnly:
            [self setActionViewsAlpha:1.0 userInteractionEnabled:YES];
            [self setPlaybackControlViewsAlpha:0.0 userInteractionEnabled:NO];
            self.controlsView.overlay.hidden = YES;
            self.separator.hidden = YES;
            break;
        case VideoControlsDisplayActionsAndPlaybackControls:
            [self setActionViewsAlpha:1.0 userInteractionEnabled:YES];
            [self setPlaybackControlViewsAlpha:1.0 userInteractionEnabled:YES];
            self.controlsView.overlay.hidden = NO;
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
