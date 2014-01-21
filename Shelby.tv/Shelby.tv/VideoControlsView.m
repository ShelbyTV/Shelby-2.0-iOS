//
//  VideoControlsView.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 7/1/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "VideoControlsView.h"
#import "DeviceUtilities.h"

@interface VideoControlsView()

@end

@implementation VideoControlsView {
    NSArray *_normalLikeButtons;
    NSArray *_nonplaybackLikeButtons;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

- (void)awakeFromNib
{
    self.bufferProgressView.trackImage = [[UIImage imageNamed:@"scrub-track-background"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 2, 0, 2)
                                                                                                        resizingMode:UIImageResizingModeStretch];
    self.bufferProgressView.progressImage = [[UIImage imageNamed:@"scrub-track-progress"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 2, 0, 2)
                                                                                                         resizingMode:UIImageResizingModeStretch];
    
    _normalLikeButtons = @[self.likeButton, self.unlikeButton];
    if (DEVICE_IPAD) {
        _nonplaybackLikeButtons = @[];
    } else {
        _nonplaybackLikeButtons = @[self.nonplaybackLikeButton, self.nonplaybackUnlikeButton];
    }

    for (UIButton *b in _nonplaybackLikeButtons) {
        b.backgroundColor = [UIColor blackColor];
        //alpha is set in -[VideoControlsViewController updateViewForCurrentDisplayMode]
    }

    [self setFont];
}

- (void)setFont
{
    //buttons get title font (labels remain body copy)
    for (UIButton *b in [_normalLikeButtons arrayByAddingObjectsFromArray:_nonplaybackLikeButtons]) {
        b.titleLabel.font = kShelbyFontH4Bold;
    }
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    if (DEVICE_IPAD) {
        return [super pointInside:point withEvent:event];
    } else {
        //to allow touch events to pass through the background
        for (UIView *v in self.subviews) {
            if (v.userInteractionEnabled && [v pointInside:[self convertPoint:point toView:v] withEvent:event]){
                return YES;
            }
        }
        return NO;
    }
}

// Implementation note for the Scrubhead related methods...
// We are using our bufferProgressView as the scrub track.  Our view controller does the same.
// If you wish to set up the scrub track differently, you will need to adjust all of these as well
// as any methods in VideoControlsViewController that reference our bufferProgressView.
- (void)positionScrubheadForPercent:(CGFloat)pct
{
    [self positionScrubberForDelta:(self.bufferProgressView.frame.size.width * pct)];
}

- (void)positionScrubheadForTouch:(UITouch *)touch
{
    [self positionScrubberForDelta:[touch locationInView:self.bufferProgressView].x];
}

- (void)positionScrubberForDelta:(CGFloat)bufferProgressRelativeDelta
{
    //cap delta within scrubber track width
    bufferProgressRelativeDelta = fmaxf(0.f, fminf(self.bufferProgressView.frame.size.width, bufferProgressRelativeDelta));

    CGFloat x = self.bufferProgressView.frame.origin.x + bufferProgressRelativeDelta - (self.scrubheadButton.frame.size.width/2.0);
    self.scrubheadButton.frame = CGRectMake(x, self.bufferProgressView.frame.origin.y - 14, self.scrubheadButton.frame.size.width, self.scrubheadButton.frame.size.height);
}

- (CGFloat)playbackTargetPercentForTouch:(UITouch *)touch
{
    CGPoint bufferRelativePosition = [touch locationInView:self.bufferProgressView];
    CGFloat pct = bufferRelativePosition.x / self.bufferProgressView.frame.size.width;
    return fmaxf(0.f, fminf(1.f, pct));
}

@end
