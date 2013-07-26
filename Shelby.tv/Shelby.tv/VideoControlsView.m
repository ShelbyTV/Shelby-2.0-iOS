//
//  VideoControlsView.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 7/1/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "VideoControlsView.h"

@interface VideoControlsView()

@end

@implementation VideoControlsView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

//to allow touch events to pass through the background
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    for (UIView *v in self.subviews) {
        if (v.userInteractionEnabled && [v pointInside:[self convertPoint:point toView:v] withEvent:event]){
            return YES;
        }
    }
    return NO;
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
    CGFloat x = self.bufferProgressView.frame.origin.x + bufferProgressRelativeDelta - (self.scrubheadButton.frame.size.width/2.0);
    self.scrubheadButton.frame = CGRectMake(x, self.bufferProgressView.frame.origin.y - 11, self.scrubheadButton.frame.size.width, self.scrubheadButton.frame.size.height);
}

- (CGFloat)playbackTargetPercentForTouch:(UITouch *)touch
{
    CGPoint bufferRelativePosition = [touch locationInView:self.bufferProgressView];
    CGFloat pct = bufferRelativePosition.x / self.bufferProgressView.frame.size.width;
    return pct;
}

@end
