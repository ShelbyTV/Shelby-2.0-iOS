//
//  SPOverlayView.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/28/12.
//  Copyright (c) 2012 Shelby TV. All rights reserved.
//

#import "SPOverlayView.h"
#import "SPModel.h"
#import "SPVideoReel.h"
#import "SPVideoScrubber.h"

#define kShelbySPSlowSpeed 0.5
#define kShelbySPFastSpeed 0.2

@interface SPOverlayView ()

@property (weak, nonatomic) SPModel *model;
@property (weak, nonatomic) IBOutlet UIButton *rollButton;
@property (weak, nonatomic) IBOutlet UIButton *likesButton;
@property (weak, nonatomic) IBOutlet UIView *videoInfoView;

// Scrubber
- (IBAction)scrubberTouched:(id)sender;

@end

@implementation SPOverlayView

#pragma mark - Initialization Methods
- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Reference Model
        _model = [SPModel sharedInstance];
        
        // Customize Colors
        [_channelTitleLabel setTextColor:kShelbyColorWhite];
        [_nicknameLabel setTextColor:kShelbyColorBlack];
        [_videoTitleLabel setTextColor:[UIColor colorWithHex:@"777" andAlpha:1.0f]];
        [_videoCaptionLabel setTextColor:kShelbyColorBlack];
        [_userImageView.layer setBorderColor:[kShelbyColorGray CGColor]];
    }
    
    return self;
}

#pragma mark - Customization on Instantiation
- (void)awakeFromNib
{
    [super awakeFromNib];

    // Customize Borders
    [self.userImageView.layer setBorderWidth:0.5];
    
    // Customize Background Colors
    [self.nicknameLabel setBackgroundColor:[UIColor clearColor]];
    [self.videoTitleLabel setBackgroundColor:[UIColor clearColor]];
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

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if ([self.model.overlayTimer isValid]) {
        [self.model.overlayTimer invalidate];
    }
    
    return [super hitTest:point withEvent:event];
}

#pragma mark - Overlay Methods
- (void)toggleOverlay
{
    
    // Send event to Google Analytics
    id defaultTracker = [GAI sharedInstance].defaultTracker;
    [defaultTracker sendEventWithCategory:kGAICategoryVideoPlayer
                               withAction:kGAIVideoPlayerActionSingleTap
                                withLabel:[[SPModel sharedInstance].videoReel groupTitle]
                                withValue:nil];
    
    ( self.alpha < 1.0f ) ? [self showOverlayView] : [self hideOverlayView];
    
}

- (BOOL)isOverlayHidden
{
    return (self.alpha == 0 || self.isHidden);
}

- (void)showOverlayView
{
    if ([self.model groupType] == GroupType_PersonalRoll) {
        [self.rollButton setHidden:YES];
        [self.shareButton setHidden:NO];
    } else if ([self.model groupType] == GroupType_Likes) {
        [self.rollButton setHidden:NO];
        [self.shareButton setHidden:YES];
    } else {
        [self.rollButton setHidden:NO];
        [self.shareButton setHidden:YES];
    }

    [[SPVideoScrubber sharedInstance] setupScrubber];
    [UIView animateWithDuration:0.5f animations:^{
        [self setAlpha:1.0f];
    }];
}

- (void)hideOverlayView
{
    [UIView animateWithDuration:0.5f animations:^{
        [self setAlpha:0.0f];
    } completion:^(BOOL finished) {
        [[SPVideoScrubber sharedInstance] stopObserving];
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
    [self.model rescheduleOverlayTimer];
}

#pragma mark - Scrubber Touch Methods
- (IBAction)scrubberTouched:(id)sender
{
    UITapGestureRecognizer *gesture = (UITapGestureRecognizer *)sender;
    CGPoint position = [gesture locationInView:self.scrubberTouchView];
    CGFloat percentage = position.x / self.elapsedProgressView.frame.size.width;
    [[SPVideoScrubber sharedInstance] seekToTimeWithPercentage:percentage];
    [self rescheduleOverlayTimer];
}
@end
