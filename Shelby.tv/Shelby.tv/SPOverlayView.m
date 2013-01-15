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
@synthesize airPlayButton = _airPlayButton;
@synthesize scrubber = _scrubber;
@synthesize scrubberTimeLabel = _scrubberTimeLabel;
@synthesize videoTitleLabel = _videoTitleLabel;
@synthesize videoCaptionLabel = _videoCaptionLabel;
@synthesize userImageView = _userImageView;
@synthesize nicknameLabel = _nicknameLabel;
@synthesize restartPlaybackButton = _restartPlaybackButton;
@synthesize downloadButton = _downloadButton;
@synthesize overlayPlaybackButton = _overlayPlaybackButton;

#pragma mark - Memory Management
- (void)dealloc
{
    self.homeButton = nil;
    self.categoryTitleLabel = nil;
    self.videoListScrollView = nil;
    self.shareButton = nil;
    self.playButton = nil;
    self.airPlayButton = nil;
    self.scrubber = nil;
    self.scrubberTimeLabel = nil;
    self.videoTitleLabel = nil;
    self.videoCaptionLabel = nil;
    self.userImageView = nil;
    self.nicknameLabel = nil;
    self.restartPlaybackButton = nil;
    self.downloadButton = nil;
    self.overlayPlaybackButton = nil;
}

#pragma mark - Customization on Instantiation
- (void)awakeFromNib
{
    // Customize Scrubber
    [self.scrubber setThumbImage:[UIImage imageNamed:@"scrubberIcon"] forState:UIControlStateNormal];
    [self.scrubber setMaximumTrackImage:[UIImage imageNamed:@"scrubberBarOff"] forState:UIControlStateNormal];

    // Customize Fonts
    [self.categoryTitleLabel setFont:[UIFont fontWithName:@"Ubuntu-Bold" size:self.categoryTitleLabel.font.pointSize]];
    [self.categoryTitleLabel setTextColor:kColorWhite];
    
    [self.scrubberTimeLabel setFont:[UIFont fontWithName:@"Arial" size:self.scrubberTimeLabel.font.pointSize]];
    [self.scrubberTimeLabel setTextColor:kColorWhite];
    
    [self.videoTitleLabel setFont:[UIFont fontWithName:@"Ubuntu" size:self.videoTitleLabel.font.pointSize]];
    [self.nicknameLabel setTextColor:kColorBlack];
    
    [self.videoCaptionLabel setTextColor:kColorBlack];
    
    [self.videoTitleLabel setFont:[UIFont fontWithName:@"Ubuntu-Medium" size:self.videoTitleLabel.font.pointSize]];
    [self.videoTitleLabel setTextColor:kColorBlack];
    
    // Customize thumbnail
    [self.userImageView.layer setBorderColor: [[UIColor colorWithRed:173.0f/255.0f green:173.0f/255.0f blue:173.0f/255.0f alpha:1.0f] CGColor]];
    [self.userImageView.layer setBorderWidth: 0.5];
    
    // Customize Dowload button
    [self.downloadButton.titleLabel setFont:[UIFont fontWithName:@"Ubuntu-Medium" size:self.downloadButton.titleLabel.font.pointSize]];
    [self.downloadButton setHidden:YES];
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
