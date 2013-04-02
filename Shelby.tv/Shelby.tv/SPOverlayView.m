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

@interface SPOverlayView ()

@property (weak, nonatomic) SPModel *model;

@property (weak, nonatomic) IBOutlet UIView *videoListView;

- (void)hideVideoList:(BOOL)animate;
- (void)showVideoList:(BOOL)animate;
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
    
    // Customize Fonts
    [self.categoryTitleLabel setFont:[UIFont fontWithName:@"Ubuntu-Bold" size:self.categoryTitleLabel.font.pointSize]];
    [self.nicknameLabel setFont:[UIFont fontWithName:@"Ubuntu" size:self.nicknameLabel.font.pointSize]];
    [self.nicknameLabel setFont:[UIFont fontWithName:@"Ubuntu-Medium" size:self.nicknameLabel.font.pointSize]];
    
    // Customize Borders
    [self.userImageView.layer setBorderWidth:0.5];
    
    [self.nicknameLabel setBackgroundColor:[UIColor clearColor]];
    [self.videoTitleLabel setBackgroundColor:[UIColor clearColor]];
    [self.videoListScrollView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"videoListPanel.png"]]];
    [self hideVideoList:NO];
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

#pragma mark - Toggle UI Methods
- (void)toggleOverlay
{
    
    // Send event to Google Analytics
    id defaultTracker = [GAI sharedInstance].defaultTracker;
    [defaultTracker sendEventWithCategory:kGAICategoryVideoPlayer
                               withAction:@"Overlay toggled via single tap gesture"
                                withLabel:[[SPModel sharedInstance].videoReel groupTitle]
                                withValue:nil];
    
    if ( self.alpha < 1.0f ) {
        
        [self showOverlayView];
        
    } else {
        
        [self hideOverlayView];
   
    }
}

- (void)showOverlayView
{
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

- (void)rescheduleOverlayTimer
{
    [self.model rescheduleOverlayTimer];
}


- (void)toggleVideoListView
{
    if (self.videoListView.frame.origin.y == self.frame.size.height) {
        [self showVideoList:YES];
    } else if (self.videoListView.frame.origin.y == self.frame.size.height - self.videoListView.frame.size.height) {
        [self hideVideoList:YES];
    }
}

#pragma mark - toggle video list (Private)
- (void)hideVideoList:(BOOL)animate
{
    CGRect videoListFrame = self.videoListView.frame;
    
    [UIView animateWithDuration:0.5 animations:^{
        [self.videoListView setFrame:CGRectMake(0, self.frame.size.height, videoListFrame.size.width, videoListFrame.size.height)];
    } completion:^(BOOL finished) {
    }];
    
}

- (void)showVideoList:(BOOL)animate
{
    float animationTime = (animate ? 0.5 : 0);
    
    CGRect videoListFrame = self.videoListView.frame;
    
    [UIView animateWithDuration:animationTime animations:^{
        [self.videoListView setFrame:CGRectMake(0, self.frame.size.height - videoListFrame.size.height , videoListFrame.size.width, videoListFrame.size.height)];
    } completion:^(BOOL finished) {
    }];
}

@end
