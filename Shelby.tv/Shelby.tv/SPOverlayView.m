//
//  SPOverlayView.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/28/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import "SPOverlayView.h"

@interface SPOverlayView ()

@end

@implementation SPOverlayView
@synthesize homeButton = _homeButton;
@synthesize categoryTitleLabel = _categoryTitleLabel;
@synthesize videoListScrollView = _videoListScrollView;
@synthesize shareButton = _shareButton;
@synthesize playButton = _playButton;
@synthesize airPlayView = _airPlayView;
@synthesize scrubber = _scrubber;
@synthesize scrubberTimeLabel = _scrubberTimeLabel;
@synthesize videoTitleLabel = _videoTitleLabel;
@synthesize videoCaptionLabel = _videoCaptionLabel;
@synthesize userImageView = _userImageView;
@synthesize nicknameLabel = _nicknameLabel;
@synthesize restartPlaybackButton = _restartPlaybackButton;

#pragma mark - Memory Management
- (void)dealloc
{
    self.homeButton = nil;
    self.categoryTitleLabel = nil;
    self.videoListScrollView = nil;
    self.shareButton = nil;
    self.playButton = nil;
    self.airPlayView = nil;
    self.scrubber = nil;
    self.scrubberTimeLabel = nil;
    self.videoTitleLabel = nil;
    self.videoCaptionLabel = nil;
    self.userImageView = nil;
    self.nicknameLabel = nil;
    self.restartPlaybackButton = nil;
}

#pragma mark - Customization on Instantiation
- (void)awakeFromNib
{
    // Customize Scrubber
    [self.scrubber setThumbImage:[UIImage imageNamed:@"scrubberIcon"] forState:UIControlStateNormal];
    [self.scrubber setMinimumTrackTintColor:kColorGreen];
    [self.scrubber setMaximumTrackImage:[UIImage imageNamed:@"scrubberBarOff"] forState:UIControlStateNormal];

    // Customize Fonts
    [self.categoryTitleLabel setFont:[UIFont fontWithName:@"Ubuntu-Bold" size:self.categoryTitleLabel.font.pointSize]];
    [self.categoryTitleLabel setTextColor:kColorWhite];
    
    [self.scrubberTimeLabel setTextColor:kColorWhite];
    
    [self.videoTitleLabel setFont:[UIFont fontWithName:@"Ubuntu" size:self.videoTitleLabel.font.pointSize]];
    [self.nicknameLabel setTextColor:[UIColor colorWithHex:@"777" andAlpha:1.0f]];
    
    [self.videoCaptionLabel setTextColor:kColorBlack];
    
    [self.videoTitleLabel setFont:[UIFont fontWithName:@"Ubuntu-Medium" size:self.videoTitleLabel.font.pointSize]];
    [self.videoTitleLabel setTextColor:kColorBlack];
    
    // Customize thumbnail
    [self.userImageView.layer setBorderColor:[kColorGray CGColor]];
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

@end
