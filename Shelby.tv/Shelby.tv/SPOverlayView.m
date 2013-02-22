//
//  SPOverlayView.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/28/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import "SPOverlayView.h"
#import "SPModel.h"

@interface SPOverlayView ()

@property (weak, nonatomic) SPModel *model;

@property (weak, nonatomic) IBOutlet UIButton *homeButton;

@end

@implementation SPOverlayView

#pragma mark - Initialization Methods
- (id)initWithCoder:(NSCoder *)aDecoder
{
    
    if ( (self = [super initWithCoder:aDecoder]) ) {
        
        // Reference Model
        self.model = [SPModel sharedInstance];
        
        // Customize Colors
        [self.categoryTitleLabel setTextColor:kShelbyColorWhite];
        [self.scrubber setMinimumTrackTintColor:kShelbyColorGreen];
        [self.scrubberTimeLabel setTextColor:kShelbyColorWhite];
        [self.nicknameLabel setTextColor:kShelbyColorBlack];
        [self.videoTitleLabel setTextColor:[UIColor colorWithHex:@"777" andAlpha:1.0f]];
        [self.videoCaptionLabel setTextColor:kShelbyColorBlack];
        [self.userImageView.layer setBorderColor:[kShelbyColorGray CGColor]];
        
    }
    
    return self;
}

#pragma mark - Customization on Instantiation
- (void)awakeFromNib
{
    
    // Customize Images
    [self.scrubber setThumbImage:[UIImage imageNamed:@"scrubberIcon"] forState:UIControlStateNormal];
    [self.scrubber setMaximumTrackImage:[UIImage imageNamed:@"scrubberBarOff"] forState:UIControlStateNormal];
    
    // Customize Fonts
    [self.categoryTitleLabel setFont:[UIFont fontWithName:@"Ubuntu-Bold" size:self.categoryTitleLabel.font.pointSize]];
    [self.nicknameLabel setFont:[UIFont fontWithName:@"Ubuntu" size:self.nicknameLabel.font.pointSize]];
    [self.nicknameLabel setFont:[UIFont fontWithName:@"Ubuntu-Medium" size:self.nicknameLabel.font.pointSize]];
    
    // Customize Borders
    [self.userImageView.layer setBorderWidth:0.5];
    
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
@end
