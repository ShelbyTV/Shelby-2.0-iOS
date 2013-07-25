//
//  ShelbyNavBarView.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 7/9/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyNavBarView.h"
#import "UIView+EasingFunctions/UIView+EasingFunctions.h"
#import "AHEasing/easing.h"

@interface ShelbyNavBarView() {
    NSArray *_separatorLines;
}

@property (weak, nonatomic) IBOutlet UIView *slider;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *sliderY;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *streamRowHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *sharesRowHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *settingsRowHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *loginRowHeight;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *selectionIdentifierX;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *selectionIdentifierY;

@end

#define FRAME_ANIMATION_TIME 0.35
#define ALPHA_ANIMATION_TIME 0.25
#define SELECTION_IDENTIFIER_ANIMATION_TIME 0.35

@implementation ShelbyNavBarView

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {

    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];

    //the grey lines that show when nav is expanded
    NSMutableArray *lines = [[NSMutableArray alloc] init];
    for (UIButton *b in @[_streamButton, _likesButton, _sharesButton, _communityButton, _settingsButton, _loginButton]) {
        UIView *hr = [[UIView alloc] init];
        [lines addObject:hr];
        hr.backgroundColor = [kShelbyColorGray colorWithAlphaComponent:0.3];
        hr.translatesAutoresizingMaskIntoConstraints = NO;
        [self insertSubview:hr aboveSubview:b];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[hr]|"
                                                                   options:nil
                                                                   metrics:nil
                                                                     views:@{@"hr":hr, @"b":b}]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[b]-0-[hr(0.5)]"
                                                                   options:nil
                                                                   metrics:nil
                                                                     views:@{@"hr":hr, @"b":b}]];

    }
    _separatorLines = lines;
    [self showSeparatorLines:NO];

}

- (void)didMoveToSuperview
{
    //see bottom of file for animation notes
    [self.slider setEasingFunction:BackEaseInOut forKeyPath:@"frame"];
    for (UIView *l in _separatorLines) {
        [l setEasingFunction:BackEaseInOut forKeyPath:@"frame"];
    }
    //setting userInteractionEnabled in XIB having no effect...
    self.selectionIdentifier.userInteractionEnabled = NO;
}

- (void)setCurrentRow:(UIView *)currentRow
{
    STVAssert(currentRow == nil || [currentRow isKindOfClass:[UIButton class]], @"current row should be a button in current implementation");
    UIButton *previousButton = (UIButton *)_currentRow;
    if (_currentRow != currentRow) {
        _currentRow = currentRow;
    }
    UIButton *currentButton = (UIButton *)currentRow;

    if (_currentRow) {
        //XXX kinda sucks when you select the top row... no animation
        // one possibility would be to animate a little fake bounce...
        [UIView animateWithDuration:FRAME_ANIMATION_TIME animations:^{
            self.sliderY.constant = -(_currentRow.frame.origin.y);
            [self layoutIfNeeded];
        }];

        [UIView animateWithDuration:ALPHA_ANIMATION_TIME animations:^{
            //focus on current row, hide rows that aren't current
            currentButton.userInteractionEnabled = YES;
            currentButton.alpha = 1.0;
            [currentButton setTitleColor:kShelbyColorBlack forState:UIControlStateNormal];
            currentButton.backgroundColor = [kShelbyColorWhite colorWithAlphaComponent:0.9];
            NSMutableArray *allRowsButCurrent = [@[_streamButton, _likesButton, _sharesButton, _communityButton, _settingsButton, _loginButton] mutableCopy];
            [allRowsButCurrent removeObject:_currentRow];
            for (UIButton *b in allRowsButCurrent) {
                b.alpha = 0.0;
                b.userInteractionEnabled = NO;
            }

            [self showSeparatorLines:NO];
        }];

        [UIView animateWithDuration:SELECTION_IDENTIFIER_ANIMATION_TIME animations:^{
            [self updateSelectionIdentifierLocationToCurrentRow];
        }];

    } else {
        //show all rows
        [UIView animateWithDuration:FRAME_ANIMATION_TIME animations:^{
            self.sliderY.constant = 0;
            [self layoutIfNeeded];
        }];

        [UIView animateWithDuration:ALPHA_ANIMATION_TIME animations:^{
            for (UIButton *b in @[_streamButton, _likesButton, _sharesButton, _communityButton, _settingsButton, _loginButton]) {
                b.alpha = 1.0;
                b.backgroundColor = kShelbyColorWhite;
                b.userInteractionEnabled = YES;
                [b setTitleColor:kShelbyColorGreen forState:UIControlStateNormal];
            }
            [previousButton setTitleColor:kShelbyColorBlack forState:UIControlStateNormal];

            [self showSeparatorLines:YES];
        }];

    }
}

- (void)showLoggedInUserRows:(BOOL)showUserRows
{
    if (showUserRows) {
        _streamRowHeight.constant = 44;
        _streamButton.hidden = NO;
        _sharesRowHeight.constant = 44;
        _sharesButton.hidden = NO;
        _settingsRowHeight.constant = 44;
        _settingsButton.hidden = NO;
        _loginRowHeight.constant = 0;
        _loginButton.hidden = YES;
    } else {
        _streamRowHeight.constant = 0;
        _streamButton.hidden = YES;
        _sharesRowHeight.constant = 0;
        _sharesButton.hidden = YES;
        _settingsRowHeight.constant = 0;
        _settingsButton.hidden = YES;
        _loginRowHeight.constant = 44;
        _loginButton.hidden = NO;
    }

    //XXX Until Shelby Sharing is implemented...
    _sharesRowHeight.constant = 0;
    _sharesButton.hidden = YES;
    //XXX
    
    [self layoutIfNeeded];
}

- (void)updateSelectionIdentifierLocationToCurrentRow
{
    UIButton *button = (UIButton *)_currentRow;
    _selectionIdentifierX.constant = button.titleLabel.frame.origin.x  + button.titleLabel.frame.size.width + 5;
    _selectionIdentifierY.constant = _currentRow.frame.origin.y + 18;
    [self layoutIfNeeded];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self updateSelectionIdentifierLocationToCurrentRow];
}

//to allow touch events to pass through the background
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    //slider's subviews, not stationary wrapper
    for (UIView *v in self.slider.subviews) {
        if (v.userInteractionEnabled && [v pointInside:[self convertPoint:point toView:v] withEvent:event]){
            return YES;
        }
    }
    return NO;
}

- (void)showSeparatorLines:(BOOL)showLines
{
    for (UIView *l in _separatorLines) {
        l.alpha = (showLines ? 1.0 : 0.0);
    }
}

/* Animation Notes
 
 BackEaseInOut <-- decent with timing: 0.5, 0.25, x
 BackEaseIn <-- :) this is fun (but timing may be too slow/off at 0.5, 0.25, x)
 BackEaseOut <-- :( no, feels like it's not landing where it should

 ElasticEaseInOut <-- :( spastic
 ElasticEaseIn <-- :( awful
 ElasticEaseOut <-- least bad of the elastic ones, not great

 QuinticEaseInOut <-- decent with timing: 0.5, 0.25, x
 QuinticEaseIn <-- :( feels laggy
 QuinticEaseOut <-- :( just feels smooth, not special

 CircularEaseInOut <-- :( meh
 CircularEaseIn <-- :( terrible
 CircularEaseOut <-- :( boring

 BounceEaseInOut <-- :( awful
 BounceEaseIn <--  :( awful
 BounceEaseOut <-- decent physical feel, but i don't think it's right for us

 ...narrowed it down by quickly testing the above...

 The decent ones to decide between:
   BackEaseInOut       7.5 (frame speed: 0.35)
   BackEaseIn          7 (needs fast frame speed)
   ElasticEaseOut      4
   QuinticEaseInOut    6 simple, smooth (frame speed: 0.5)
   BounceEaseOut       6 very physical (frame speed: 0.5)
 */

@end
