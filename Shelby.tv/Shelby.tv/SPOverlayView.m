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
@synthesize controlBarView = _controlBarView;
@synthesize containerView = _containerView;
@synthesize videoListScrollView = _videoListScrollView;
@synthesize shareButton = _shareButton;
@synthesize playButton = _playButton;
@synthesize airPlayButton = _airPlayButton;
@synthesize scrubber = _scrubber;
@synthesize videoTitleLabel = _videoTitleLabel;
@synthesize captionLabel = _captionLabel;
@synthesize userImageView = _userImageView;
@synthesize nicknameLabel = _nicknameLabel;
@synthesize restartPlaybackButton = _restartPlaybackButton;

#pragma mark - Memory Management
- (void)dealloc
{
    self.homeButton = nil;
    self.categoryTitleLabel = nil;
    self.controlBarView = nil;
    self.containerView = nil;
    self.videoListScrollView = nil;
    self.shareButton = nil;
    self.playButton = nil;
    self.airPlayButton = nil;
    self.scrubber = nil;
    self.videoTitleLabel = nil;
    self.captionLabel = nil;
    self.userImageView = nil;
    self.nicknameLabel = nil;
    self.restartPlaybackButton = nil;
}

#pragma mark - Customization on Instantiation
- (void)awakeFromNib
{
    
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
