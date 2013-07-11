//
//  ShelbyNavBarView.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 7/9/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyNavBarView.h"

@interface ShelbyNavBarView()

@property (weak, nonatomic) IBOutlet UIButton *streamButton;
@property (weak, nonatomic) IBOutlet UIButton *likesButton;
@property (weak, nonatomic) IBOutlet UIButton *sharesButton;
@property (weak, nonatomic) IBOutlet UIButton *communityButton;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *streamRowHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *sharesRowHeight;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *selectionIdentifierX;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *selectionIdentifierY;

@end

@implementation ShelbyNavBarView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

- (void)setCurrentRow:(UIView *)currentRow
{
    if (_currentRow != currentRow) {
        _currentRow = currentRow;
    }

    if (_currentRow) {
        [UIView animateWithDuration:0.3 animations:^{
            //move frame to focus on given row
            self.frame = CGRectMake(0, -(_currentRow.frame.origin.y), self.frame.size.width, self.frame.size.height);

            //focus on current row, hide rows that aren't current
            _currentRow.alpha = 0.85;
            NSMutableArray *allRowsButCurrent = [@[_streamRow, _likesRow, _sharesRow, _communityRow] mutableCopy];
            [allRowsButCurrent removeObject:_currentRow];
            for (UIView *v in allRowsButCurrent) {
                v.alpha = 0.0;
                v.userInteractionEnabled = NO;
            }

            //show selection on current row
            UIButton *button = [_currentRow.subviews lastObject];
            _selectionIdentifierX.constant = button.titleLabel.frame.origin.x - 10;
            _selectionIdentifierY.constant = _currentRow.frame.origin.y + 19;
            [self layoutIfNeeded];
        }];

    } else {
        //show all rows
        [UIView animateWithDuration:0.3 animations:^{
            self.frame = CGRectMake(0, 10, self.frame.size.width, self.frame.size.height);

            for (UIView *v in @[_streamRow, _likesRow, _sharesRow, _communityRow]) {
                v.alpha = 0.95;
                v.userInteractionEnabled = YES;
            }
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
    } else {
        _streamRowHeight.constant = 0;
        _streamButton.hidden = YES;
        _sharesRowHeight.constant = 0;
        _sharesButton.hidden = YES;
    }
    [self layoutIfNeeded];
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

@end
