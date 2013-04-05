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

#define kShelbySPSlowSpeed 0.5
#define kShelbySPFastSpeed 0.2

@interface SPOverlayView ()

@property (weak, nonatomic) SPModel *model;
@property (weak, nonatomic) IBOutlet UIButton *rollButton;
@property (weak, nonatomic) IBOutlet UIButton *likesButton;
@property (weak, nonatomic) IBOutlet UIView *videoListView;
@property (weak, nonatomic) IBOutlet UIView *videoInfoView;

- (void)handleScrubberTouchWithPosition:(CGPoint)position inView:(UIView *)touchedView;

// Video List Panning
- (IBAction)panView:(id)sender;
- (void)hideVideoList:(float)speed;
- (void)showVideoList:(float)speed;
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

    // Customize Borders
    [self.userImageView.layer setBorderWidth:0.5];
    
    // Customize Background Colors
    [self.nicknameLabel setBackgroundColor:[UIColor clearColor]];
    [self.videoTitleLabel setBackgroundColor:[UIColor clearColor]];
    [self.videoListScrollView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"videoListPanel.png"]]];
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
        if (self.likesButton.frame.origin.x == self.rollButton.frame.origin.x) {
            [self.rollButton setFrame:CGRectMake(self.rollButton.frame.origin.x
                                                 - self.likesButton.frame.size.width - 5, self.rollButton.frame.origin.y, self.rollButton.frame.size.width, self.rollButton.frame.size.height)];
        }
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
    
    [self hideVideoList:kShelbySPSlowSpeed];
}

- (void)showVideoList
{
    if (self.videoListView.frame.origin.y != self.frame.size.height) {
        return;
    }
    
    [self showVideoList:kShelbySPSlowSpeed];
}

- (void)hideVideoAndChannelInfo
{
    [self.videoInfoView setHidden:YES];
    [self.videoListScrollView setHidden:YES];
}


- (void)showVideoAndChannelInfo
{
    if (![self.videoListScrollView isHidden]) {
        return;
    }
    
    [self.videoInfoView setAlpha:0];
    [self.videoListScrollView setAlpha:0];
    [self.videoInfoView setHidden:NO];
    [self.videoListScrollView setHidden:NO];

    [UIView animateWithDuration:0.3 animations:^{
        [self.videoInfoView setAlpha:1];
        [self.videoListScrollView setAlpha:1];
    }];
}


#pragma mark Video List Panning (Private)

- (void)hideVideoList:(float)speed
{
    CGRect videoListFrame = self.videoListView.frame;
    
    [UIView animateWithDuration:speed animations:^{
        [self.videoListView setFrame:CGRectMake(0, self.frame.size.height, videoListFrame.size.width, videoListFrame.size.height)];
    }];
}

- (void)showVideoList:(float)speed
{
    CGRect videoListFrame = self.videoListView.frame;
    
    [UIView animateWithDuration:speed animations:^{
        [self.videoListView setFrame:CGRectMake(0, self.frame.size.height - videoListFrame.size.height , videoListFrame.size.width, videoListFrame.size.height)];
    }];
}


- (IBAction)panView:(id)sender
{
    UIPanGestureRecognizer *panGesture = sender;
    if (![panGesture isKindOfClass:[UIPanGestureRecognizer class]]) {
        return;
    }
    
    int y = self.videoListView.frame.origin.y;
    CGPoint translation = [panGesture translationInView:self.videoListView.superview];
    
    float yOriginOpen = (self.frame.size.height - self.videoListView.frame.size.height);
    if ([panGesture state] == UIGestureRecognizerStateBegan || [panGesture state] == UIGestureRecognizerStateChanged) {
        if (y + translation.y >= 0 && y + translation.y > yOriginOpen) {
            self.videoListView.frame = CGRectMake(0, y + translation.y, self.videoListView.frame.size.width, self.videoListView.frame.size.height);
        }
        [panGesture setTranslation:CGPointZero inView:self.videoListView];
    } else if ([panGesture state] == UIGestureRecognizerStateEnded) {
        CGPoint velocity = [panGesture velocityInView:self.videoListView.superview];
        if (velocity.y < -200) {
            [self showVideoList:kShelbySPFastSpeed];
        } else if (velocity.y > 200) {
            [self hideVideoList:kShelbySPFastSpeed];
        } else if (kShelbySPVideoHeight - (y + translation.y) > self.videoListView.frame.size.height/2) {
            [self showVideoList:kShelbySPSlowSpeed];
        } else {
            [self hideVideoList:kShelbySPSlowSpeed];
        }
    }
}

#pragma mark - Timer Methods
- (void)rescheduleOverlayTimer
{
    [self.model rescheduleOverlayTimer];
}

#pragma mark - Scrubber Touch Methods
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    for (UITouch *touch in touches) {
        
        if (touch.view == [self scrubberTouchView]) {
            CGPoint position = [touch locationInView:[self scrubberTouchView]];
            DLog(@"scrubberContainerView %@", NSStringFromCGPoint(position));
            [self handleScrubberTouchWithPosition:position inView:[self scrubberContainerView]];
        } else if (touch.view == [self elapsedProgressView]) {
            CGPoint position = [touch locationInView:[self elapsedProgressView]];
            DLog(@"elapsedProgressView %@", NSStringFromCGPoint(position));
            [self rescheduleOverlayTimer];
            [self handleScrubberTouchWithPosition:position inView:[self elapsedProgressView]];
        } else if (touch.view == [self bufferProgressView]) {
            CGPoint position = [touch locationInView:[self bufferProgressView]];
            DLog(@"bufferProgressView %@", NSStringFromCGPoint(position));
            [self handleScrubberTouchWithPosition:position inView:[self bufferProgressView]];
        } else {
            // Do nothing
        }
        
    }
}

- (void)handleScrubberTouchWithPosition:(CGPoint)position inView:(UIView *)touchedView
{
    self.model.videoReel.toggleOverlayGesuture.enabled = NO;
    CGFloat percentage = position.x / self.elapsedProgressView.frame.size.width;
    [[SPVideoScrubber sharedInstance] seekToTimeWithPercentage:percentage];
    self.model.videoReel.toggleOverlayGesuture.enabled = YES;
    [self rescheduleOverlayTimer];
}

@end
