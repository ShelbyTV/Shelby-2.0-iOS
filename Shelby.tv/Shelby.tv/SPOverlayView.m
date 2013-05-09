//
//  SPOverlayView.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/28/12.
//  Copyright (c) 2012 Shelby TV. All rights reserved.
//

#import "SPOverlayView.h"
#import "AsynchronousFreeloader.h"
#import "Frame+Helper.h"

#define kShelbySPSlowSpeed 0.5
#define kShelbySPFastSpeed 0.2

@interface SPOverlayView ()

//djs
//@property (weak, nonatomic) SPModel *model;
@property (weak, nonatomic) IBOutlet UIButton *rollButton;
@property (weak, nonatomic) IBOutlet UIButton *likesButton;
@property (weak, nonatomic) IBOutlet UIButton *shareButton;
@property (weak, nonatomic) IBOutlet UIView *videoInfoView;
@property (weak, nonatomic) IBOutlet TopAlignedLabel *primaryTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *userTimestamp;
@property (weak, nonatomic) IBOutlet UIImageView *userImageView;
@property (weak, nonatomic) IBOutlet UILabel *nicknameLabel;

@property (weak, nonatomic) IBOutlet UIButton *restartPlaybackButton;
@property (weak, nonatomic) IBOutlet UIImageView *likeNotificationView;
@property (weak, nonatomic) IBOutlet UIProgressView *bufferProgressView;
@property (weak, nonatomic) IBOutlet UIProgressView *elapsedProgressView;
@property (weak, nonatomic) IBOutlet UILabel *elapsedTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalDurationLabel;
@property (weak, nonatomic) IBOutlet UIView *scrubberContainerView;
@property (weak, nonatomic) IBOutlet UIView *scrubberTouchView;
@property (weak, nonatomic) IBOutlet UIButton *versionButton;


// Scrubber
- (IBAction)scrubberTouched:(id)sender;


@property (assign, nonatomic) CMTime duration;

@end

@implementation SPOverlayView

#pragma mark - Initialization Methods
- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [_nicknameLabel setTextColor:kShelbyColorBlack];
        [_primaryTextLabel setTextColor:kShelbyColorBlack];
        [_userImageView.layer setBorderColor:[kShelbyColorGray CGColor]];
    }
    
    return self;
}

#pragma mark - Customization on Instantiation
- (void)awakeFromNib
{
    [super awakeFromNib];

    //non-Nib customizations
    [self.userImageView.layer setBorderWidth:0.5];
    [self.nicknameLabel setBackgroundColor:[UIColor clearColor]];
}

#pragma mark - UIView Overridden Methods
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    // If one of our subviews wants it, return YES
    for (UIView *subview in self.subviews) {
        
        CGPoint pointInSubview = [subview convertPoint:point fromView:self];
        if ([subview pointInside:pointInSubview withEvent:event]) {
            return YES;
        }
    }
    
    // Return NO (acts like userInteractionEnabled = NO)
    return NO;
}

//djs don't need this if we're only calling super
//- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
//{
//    //djs
////    if ([self.model.overlayTimer isValid]) {
////        [self.model.overlayTimer invalidate];
////    }
//    
//    return [super hitTest:point withEvent:event];
//}

#pragma mark - View Updating Methods

- (void)setFrameOrDashboardEntry:(id)entity
{
    Frame *frame;
    if ([entity isKindOfClass:[DashboardEntry class]]) {
        frame = ((DashboardEntry *)entity).frame;
    } else if ([entity isKindOfClass:[Frame class]]) {
        frame = (Frame *)entity;
    } else {
        NSAssert( false, @"Overlay expects DashboardEntry or Frame");
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.elapsedTimeLabel.text = @"";
        self.elapsedProgressView.progress = 0.0;
        //don't touch total duration
        self.bufferProgressView.progress = 0.0;
        
        self.primaryTextLabel.text = [frame creatorsInitialCommentWithFallback:YES];
        self.userTimestamp.text = frame.createdAt;
        self.nicknameLabel.text = frame.creator.nickname;
        [AsynchronousFreeloader loadImageFromLink:frame.creator.userImage
                                     forImageView:self.userImageView
                                  withPlaceholder:[UIImage imageNamed:@"infoPanelIconPlaceholder"]
                                   andContentMode:UIViewContentModeScaleAspectFit];
    });
}

- (void)setAccentColor:(UIColor *)accentColor
{
    self.videoInfoView.layer.borderWidth = 3.0;
    self.videoInfoView.layer.borderColor = [accentColor colorWithAlphaComponent:0.75].CGColor;
    
    self.scrubberContainerView.layer.borderWidth = 1.0;
    self.scrubberContainerView.layer.borderColor = [accentColor colorWithAlphaComponent:0.25].CGColor;
    self.scrubberContainerView.layer.cornerRadius = 5.0;
    
    self.elapsedProgressView.progressTintColor = accentColor;
}

- (void)updateBufferedRange:(CMTimeRange)bufferedRange
{
    self.bufferProgressView.progress = (CMTimeGetSeconds(bufferedRange.start) + CMTimeGetSeconds(bufferedRange.duration)) / CMTimeGetSeconds(self.duration);
}

- (void)updateCurrentTime:(CMTime)time
{
    self.elapsedTimeLabel.text = [self prettyStringForTime:time];
    self.elapsedProgressView.progress = CMTimeGetSeconds(time)/CMTimeGetSeconds(self.duration);
}

- (void)setDuration:(CMTime)duration
{
    _duration = duration;
    self.totalDurationLabel.text = [self prettyStringForTime:duration];
}


#pragma mark - Overlay Methods
- (void)toggleOverlay
{
    
    // Send event to Google Analytics
    //djs TODO: track this
//    id defaultTracker = [GAI sharedInstance].defaultTracker;
//    [defaultTracker sendEventWithCategory:kGAICategoryVideoPlayer
//                               withAction:kGAIVideoPlayerActionSingleTap
//                                withLabel:[[SPModel sharedInstance].videoReel groupTitle]
//                                withValue:nil];
    
    ( self.alpha < 1.0f ) ? [self showOverlayView] : [self hideOverlayView];
    
}

- (BOOL)isOverlayHidden
{
    return (self.alpha == 0 || self.isHidden);
}

- (void)showOverlayView
{
    //djs
//    if ([self.model groupType] == GroupType_PersonalRoll) {
//        [self.rollButton setHidden:YES];
//        [self.shareButton setHidden:NO];
//        [self.likesButton setEnabled:YES];
//    } else if ([self.model groupType] == GroupType_Likes) {
//        [self.rollButton setHidden:NO];
//        [self.shareButton setHidden:YES];
//        [self.likesButton setEnabled:NO];
//    } else {
//        [self.rollButton setHidden:NO];
//        [self.shareButton setHidden:YES];
//        [self.likesButton setEnabled:YES];
//    }

    [UIView animateWithDuration:0.5f animations:^{
        [self setAlpha:1.0f];
    }];
}

- (void)hideOverlayView
{
    [UIView animateWithDuration:0.5f animations:^{
        [self setAlpha:0.0f];
    } completion:^(BOOL finished) {
        //nothing
    }];
}

#pragma mark - Like Notification Methods
- (void)showLikeNotificationView
{
    [UIView animateWithDuration:0.5f animations:^{
        [self.likeNotificationView setAlpha:1.0f];
    }];
}

- (void)hideLikeNotificationView
{
    [UIView animateWithDuration:0.5f animations:^{
        [self.likeNotificationView setAlpha:0.0f];
    }];
}

#pragma mark - Playlist Methods
- (void)hideVideoInfo
{
    [self.videoInfoView setHidden:YES];
}


- (void)showVideoInfo
{
    [self.videoInfoView setAlpha:0];
    [self.videoInfoView setHidden:NO];

    [UIView animateWithDuration:0.3 animations:^{
        [self.videoInfoView setAlpha:0.5];
    }];
}


#pragma mark - Timer Methods
- (void)rescheduleOverlayTimer
{
    //djs
//    [self.model rescheduleOverlayTimer];
}

#pragma mark - Scrubber Touch Methods
- (IBAction)scrubberTouched:(id)sender
{
    UITapGestureRecognizer *gesture = (UITapGestureRecognizer *)sender;
    CGPoint position = [gesture locationInView:self.scrubberTouchView];
    CGFloat percentage = position.x / self.elapsedProgressView.frame.size.width;
    [self rescheduleOverlayTimer];
    //djs TODO: call out to a delegate
}

#pragma mark - Text Helper

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
