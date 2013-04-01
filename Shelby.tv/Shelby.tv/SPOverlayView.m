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

// KP KP: TODO: if we keep the word: playlist next to toggleVideoList button, no need to make this as button as we have a big button on top.
@property (weak, nonatomic) IBOutlet UIButton *toggleVideoList;
@property (weak, nonatomic) IBOutlet UIView *videoListView;
@property (weak, nonatomic) IBOutlet UIView *playListControlsView;

@property (weak, nonatomic) IBOutlet UIButton *grabberOpen;
@property (weak, nonatomic) IBOutlet UIButton *grabberClose;

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
        [_scrubberTimeLabel setTextColor:kShelbyColorWhite];
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
    
    // Customize Images
    [self.scrubber setThumbImage:[UIImage imageNamed:@"scrubberIcon"] forState:UIControlStateNormal];
    [self.scrubber setMinimumTrackImage:[[UIImage imageNamed:@"scrubberBarGreen"] stretchableImageWithLeftCapWidth:10.0 topCapHeight:0.0] forState:UIControlStateNormal];
    
    // Customize Fonts
    [self.categoryTitleLabel setFont:[UIFont fontWithName:@"Ubuntu-Bold" size:self.categoryTitleLabel.font.pointSize]];
    [self.nicknameLabel setFont:[UIFont fontWithName:@"Ubuntu" size:self.nicknameLabel.font.pointSize]];
    [self.nicknameLabel setFont:[UIFont fontWithName:@"Ubuntu-Medium" size:self.nicknameLabel.font.pointSize]];
    
    // Customize Borders
    [self.userImageView.layer setBorderWidth:0.5];
    
    [self.homeButton setHidden:NO];
    
    [self.nicknameLabel setBackgroundColor:[UIColor clearColor]];
    [self.videoTitleLabel setBackgroundColor:[UIColor clearColor]];
    [self.videoListScrollView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"videoListPanel.png"]]];
   
    /// iPhone
    if (!DEVICE_IPAD) {
        [self.videoListScrollView setBackgroundColor:[UIColor colorWithHex:@"f7f7f7" andAlpha:1]];
    } else {
        [self hideVideoList:NO];
    }
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
    } completion:^(BOOL finished) {
        [self hideVideoList:NO];
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
    if (DEVICE_IPAD) {
        if (self.videoListView.frame.origin.y == self.frame.size.height - self.playListControlsView.frame.size.height) {
            [self showVideoList:YES];
        } else if (self.videoListView.frame.origin.y == self.frame.size.height - self.videoListView.frame.size.height) {
            [self hideVideoList:YES];
        }
    } else {
        if (self.videoListScrollView.frame.origin.y == 320) {
            [self showVideoList:YES];
        } else if (self.videoListScrollView.frame.origin.y == 220) {
            [self hideVideoList:YES];
        }
    }
}

- (void)toggleMinimalView:(BOOL)animate
{
    int minimalWidth = self.playButton.frame.origin.x - 10;
    float animation = (animate ? 0.5 : 0.01);
    
    
    if (self.videoListView.frame.size.width == self.frame.size.width) {
        [UIView animateWithDuration:animation animations:^{
            [self.videoListView setFrame:CGRectMake(0, self.videoListView.frame.origin.y, minimalWidth, self.videoListView.frame.size.height)];
        } completion:^(BOOL finished) {
            [self.grabberOpen setAlpha:1];
        }];
        
    } else if (self.videoListView.frame.size.width == minimalWidth){
        [UIView animateWithDuration:animation animations:^{
            [self.videoListView setFrame:CGRectMake(0, self.videoListView.frame.origin.y, self.frame.size.width, self.videoListView.frame.size.height)];
            [self.grabberOpen setAlpha:0];
        }];
    }
}

#pragma mark - toggle video list (Private)
- (void)hideVideoList:(BOOL)animate
{
    CGRect videoListFrame = self.videoListView.frame;

    if (DEVICE_IPAD) {
        [UIView animateWithDuration:0.5 animations:^{
            [self.videoListView setFrame:CGRectMake(0, self.frame.size.height - self.playListControlsView.frame.size.height, videoListFrame.size.width, videoListFrame.size.height)];
            [self.playListControlsView setAlpha:0.7];
        } completion:^(BOOL finished) {
            [self.toggleVideoList setSelected:NO];
        }];
    
    } else {
        
        [UIView animateWithDuration:0.5 animations:^{
            [self.videoListScrollView setFrame:CGRectMake(0, 320, 525, 100)];
        } completion:^(BOOL finished) {
            [self.toggleVideoList setSelected:NO];
        }];
    }
}

- (void)showVideoList:(BOOL)animate
{
    float animationTime = (animate ? 0.5 : 0);
    
    CGRect videoListFrame = self.videoListView.frame;
    if (DEVICE_IPAD) {
        [UIView animateWithDuration:animationTime animations:^{
            [self.videoListView setFrame:CGRectMake(0, self.frame.size.height - videoListFrame.size.height , videoListFrame.size.width, videoListFrame.size.height)];
            [self.playListControlsView setAlpha:0];
        } completion:^(BOOL finished) {
            [self.toggleVideoList setSelected:YES];
        }];
    } else {
        [UIView animateWithDuration:animationTime animations:^{
            [self.videoListScrollView setFrame:CGRectMake(0, 220, 525, 100)];
        } completion:^(BOOL finished) {
            [self.toggleVideoList setSelected:YES];
            
        }];
    }
}
@end
