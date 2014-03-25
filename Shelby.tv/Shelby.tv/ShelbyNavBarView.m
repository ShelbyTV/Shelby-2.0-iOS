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
    NSArray *_orderedButtons;
    NSArray *_separatorLines;
    UIImageView *_shadowView;
    NSLayoutConstraint *_shadowY;
    BOOL _firstLaunch;
}

@property (weak, nonatomic) IBOutlet UIView *slider;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *sliderY;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *streamRowHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *sharesRowHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *settingsRowHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *loginRowHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *notificationCenterRowHeight;
@end

#define FRAME_ANIMATION_TIME 0.4
#define ALPHA_ANIMATION_TIME 0.3

static CGFloat QuinticEaseInOutCGF(CGFloat p){
    return QuinticEaseInOut(p);
}

static CGFloat BackEaseInOutCGF(CGFloat p) {
    return BackEaseInOut(p);
}

@implementation ShelbyNavBarView

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _firstLaunch = YES;
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];

    _orderedButtons = @[_streamButton, _sharesButton, _communityButton, _channelsButton, _notificationCenterButton, _settingsButton, _signupButton];

    for (UIButton *b in _orderedButtons) {
        b.titleLabel.font = kShelbyFontH3;
    }

    //the grey lines that show when nav is expanded
    NSMutableArray *lines = [[NSMutableArray alloc] init];
    for (UIButton *b in _orderedButtons) {
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

    //shadow (we manually move this when the "bottom" changes)
    _shadowView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"nav-shadow"]];
    _shadowView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.slider addSubview:_shadowView];
    [self.slider addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[shadow]|"
                                                                 options:nil
                                                                 metrics:nil
                                                                   views:@{@"shadow":_shadowView}]];
    _shadowY = [NSLayoutConstraint constraintWithItem:_shadowView
                                            attribute:NSLayoutAttributeTop 
                                            relatedBy:NSLayoutRelationEqual 
                                               toItem:self attribute:NSLayoutAttributeTop 
                                           multiplier:0.f 
                                             constant:0];
    [self.slider addConstraint:_shadowY];
    
    //tweak visuals of notification badge
    self.notificationLabel.backgroundColor = kShelbyColorGreen;
    self.notificationLabel.layer.cornerRadius = self.notificationLabel.bounds.size.height / 2.f;
    self.notificationLabel.margins = CGSizeMake(10.f, 0);
    self.notificationLabel.alpha = 0.f;
}

- (void)didMoveToSuperview
{
    //see bottom of file for animation notes
    [self.slider setEasingFunction:&QuinticEaseInOutCGF forKeyPath:@"frame"];
    for (UIView *l in _separatorLines) {
        [l setEasingFunction:&BackEaseInOutCGF forKeyPath:@"frame"];
    }
}

- (void)setCurrentRow:(UIView *)currentRow
{
    STVAssert(currentRow == nil || [currentRow isKindOfClass:[UIButton class]], @"current row should be a button in current implementation");
    UIButton *previousButton = (UIButton *)_currentRow;
    if (_currentRow != currentRow) {
        _currentRow = currentRow;
    }
    UIButton *currentButton = (UIButton *)currentRow;

    //pretty launch (no animation)
    if (_firstLaunch) {
        STVDebugAssert(_currentRow, @"should have current row on first launch");
         _firstLaunch = NO;
        self.sliderY.constant = -(_currentRow.frame.origin.y);
        [self layoutIfNeeded];
        [self focusOnButton:currentButton];
        [self repositionShadow];
        return;
    }

    if (_currentRow) {
        self.notificationLabel.alpha = 0;
        [UIView animateWithDuration:FRAME_ANIMATION_TIME animations:^{
            self.sliderY.constant = -(_currentRow.frame.origin.y);
            [self layoutIfNeeded];
        }];

        [UIView animateWithDuration:ALPHA_ANIMATION_TIME animations:^{
            [self focusOnButton:currentButton];
        }];

        [self repositionShadow];

    } else {
        //show all rows
        [UIView animateWithDuration:FRAME_ANIMATION_TIME animations:^{
            self.sliderY.constant = 0;
            if (self.shouldHideNotificationLabel) {
                self.notificationLabel.alpha = 0;
            } else {
                self.notificationLabel.alpha = 1;
            }
            [self layoutIfNeeded];
        }];

        [UIView animateWithDuration:ALPHA_ANIMATION_TIME animations:^{
            for (UIButton *b in _orderedButtons) {
                b.alpha = 1.0;
                b.backgroundColor = kShelbyColorWhite;
                b.userInteractionEnabled = YES;
                [b setTitleColor:kShelbyColorGreen forState:UIControlStateNormal];
            }
            [previousButton setTitleColor:kShelbyColorBlack forState:UIControlStateNormal];

            [self showSeparatorLines:YES];
        }];
        [self repositionShadow];

    }
}

- (void)showLoggedInUserRows:(BOOL)showUserRows
{
    if (showUserRows) {
        _streamRowHeight.constant = 44;
        _streamButton.hidden = NO;
        _settingsRowHeight.constant = 44;
        _settingsButton.hidden = NO;
        _loginRowHeight.constant = 0;
        _signupButton.hidden = YES;
        _notificationCenterButton.hidden = NO;
        _notificationCenterRowHeight.constant = 44;
    } else {
        _streamRowHeight.constant = 0;
        _streamButton.hidden = YES;
        _settingsRowHeight.constant = 0;
        _settingsButton.hidden = YES;
        _loginRowHeight.constant = 44;
        _signupButton.hidden = NO;
        _notificationCenterRowHeight.constant = 0;
        _notificationCenterButton.hidden = YES;
    }

    [self layoutIfNeeded];
    if (_currentRow) {
        self.currentRow = _currentRow;
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
}

//allow touch events to pass through the background when contracted, capture everything when expanded
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    //slider's subviews, not stationary wrapper
    for (UIView *v in self.slider.subviews) {
        if (v.userInteractionEnabled && [v pointInside:[self convertPoint:point toView:v] withEvent:event]){
            return YES;
        }
    }

    //tap outside of expanded nav bar view
    if (!self.currentRow) {
        return YES;
    }

    return NO;
}

- (void)showSeparatorLines:(BOOL)showLines
{
    for (UIView *l in _separatorLines) {
        l.alpha = (showLines ? 1.0 : 0.0);
    }
}

- (void)repositionShadow
{
    UIButton *lastbutton = [self lastVisibleButton];
    _shadowY.constant = lastbutton.frame.origin.y + lastbutton.frame.size.height;
}

- (UIButton *)lastVisibleButton
{
    UIButton *b;
    for (UIButton *button in _orderedButtons) {
        if (!button.hidden && button.alpha == 1.0f) {
            b = button;
        }
    }
    return b;
}

- (void)focusOnButton:(UIButton *)currentButton
{
    //focus on current row, hide rows that aren't current
    currentButton.userInteractionEnabled = YES;
    currentButton.alpha = 1.0;
    [currentButton setTitleColor:kShelbyColorWhite forState:UIControlStateNormal];
    currentButton.backgroundColor =  [UIColor colorWithPatternImage:[UIImage imageNamed:@"top-nav-bkgd.png"]];
    NSMutableArray *allRowsButCurrent = [_orderedButtons mutableCopy];
    [allRowsButCurrent removeObject:_currentRow];
    for (UIButton *b in allRowsButCurrent) {
        b.alpha = 0.0;
        b.userInteractionEnabled = NO;
    }
    [self showSeparatorLines:NO];
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