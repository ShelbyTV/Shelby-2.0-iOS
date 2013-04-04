//
//  SPOverlayView.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/28/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import "SPOverlayView.h"
#import "SPModel.h"
#import "SPVideoReel.h"
#import "SPVideoScrubber.h"

@interface SPOverlayView ()

@property (weak, nonatomic) SPModel *model;
@property (weak, nonatomic) IBOutlet UIButton *rollButton;
@property (weak, nonatomic) IBOutlet UIButton *likesButton;
@property (weak, nonatomic) IBOutlet UIView *videoListView;

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
        [_categoryTitleLabel setTextColor:kShelbyColorWhite];
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
    
    UINib *cellNib = [UINib nibWithNibName:@"SPCategoryViewCell" bundle:nil];
    [self.categoriesCollectionView registerNib:cellNib forCellWithReuseIdentifier:@"SPCategoryViewCell"];

    // Customize Fonts
    [self.categoryTitleLabel setFont:[UIFont fontWithName:@"Ubuntu-Bold" size:self.categoryTitleLabel.font.pointSize]];
    [self.nicknameLabel setFont:[UIFont fontWithName:@"Ubuntu" size:self.nicknameLabel.font.pointSize]];
    [self.nicknameLabel setFont:[UIFont fontWithName:@"Ubuntu-Medium" size:self.nicknameLabel.font.pointSize]];
    
    // Customize Borders
    [self.userImageView.layer setBorderWidth:0.5];
    
    // Customize Background Colors
    [self.nicknameLabel setBackgroundColor:[UIColor clearColor]];
    [self.videoTitleLabel setBackgroundColor:[UIColor clearColor]];
    [self.videoListScrollView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"videoListPanel.png"]]];
    
    // Hide Playlist
    [self hideVideoList];
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
                               withAction:@"Overlay toggled via single tap gesture"
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
        [self.likesButton setHidden:NO];
    } else if ([self.model groupType] == GroupType_Likes) {
        [self.rollButton setHidden:NO];
        [self.rollButton setFrame:self.likesButton.frame];
        [self.likesButton setHidden:YES];
    } else {
        [self.likesButton setHidden:NO];
        [self.rollButton setHidden:NO];
    }

    [UIView animateWithDuration:0.5f animations:^{
        [self setAlpha:1.0f];
    }];
}

- (void)hideOverlayView
{
    [UIView animateWithDuration:0.5f animations:^{
        [self setAlpha:0.0f];
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
- (void)hideVideoList
{
    
    if (self.videoListView.frame.origin.y != (self.frame.size.height - self.videoListView.frame.size.height)) {
        return;
    }
    
    CGRect videoListFrame = self.videoListView.frame;
    
    [UIView animateWithDuration:0.5f animations:^{
        [self.videoListView setFrame:CGRectMake(0, self.frame.size.height, videoListFrame.size.width, videoListFrame.size.height)];
    }];
}

- (void)showVideoList
{
    if (self.videoListView.frame.origin.y != self.frame.size.height) {
        return;
    }
    
    CGRect videoListFrame = self.videoListView.frame;
    
    [UIView animateWithDuration:0.5f animations:^{
        [self.videoListView setFrame:CGRectMake(0, self.frame.size.height - videoListFrame.size.height , videoListFrame.size.width, videoListFrame.size.height)];
    }];
}

#pragma mark - Timer Methods
- (void)rescheduleOverlayTimer
{
    [self.model rescheduleOverlayTimer];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    for (UITouch *touch in touches) {
        
        if (touch.view == [self scrubberContainerView]) {
            self.model.videoReel.toggleOverlayGesuture.enabled = NO;
            CGPoint position = [touch locationInView:[self scrubberContainerView]];
            DLog(@"scrubberContainerView %@", NSStringFromCGPoint(position));
            CGFloat percentage = position.x / self.scrubberContainerView.frame.size.width;
            [[SPVideoScrubber sharedInstance] seekToTimeWithPercentage:percentage];
            self.model.videoReel.toggleOverlayGesuture.enabled = YES;
            [self rescheduleOverlayTimer];
        } else if (touch.view == [self elapsedProgressView]) {
            self.model.videoReel.toggleOverlayGesuture.enabled = NO;
            CGPoint position = [touch locationInView:[self elapsedProgressView]];
            DLog(@"elapsedProgressView %@", NSStringFromCGPoint(position));
            CGFloat percentage = position.x / self.scrubberContainerView.frame.size.width;
            [[SPVideoScrubber sharedInstance] seekToTimeWithPercentage:percentage];
            self.model.videoReel.toggleOverlayGesuture.enabled = YES;
            [self rescheduleOverlayTimer];
        } else if (touch.view == [self bufferProgressView]) {
            self.model.videoReel.toggleOverlayGesuture.enabled = NO;
            CGPoint position = [touch locationInView:[self bufferProgressView]];
            DLog(@"bufferProgressView %@", NSStringFromCGPoint(position));
            CGFloat percentage = position.x / self.scrubberContainerView.frame.size.width;
            [[SPVideoScrubber sharedInstance] seekToTimeWithPercentage:percentage];
            self.model.videoReel.toggleOverlayGesuture.enabled = YES;
            [self rescheduleOverlayTimer];
        } else {
            // Do nothing
        }
        
    }
}

@end
