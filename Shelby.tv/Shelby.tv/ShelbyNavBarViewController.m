//
//  ShelbyNavBarViewController.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 7/9/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyNavBarViewController.h"

@interface ShelbyNavBarViewController ()
@property (nonatomic, strong) NSArray *allRowViews;
@property (weak, nonatomic) IBOutlet UIView *streamRow;
@property (weak, nonatomic) IBOutlet UIView *likesRow;
@property (weak, nonatomic) IBOutlet UIView *sharesRow;
@property (weak, nonatomic) IBOutlet UIView *communityRow;

@property (weak, nonatomic) IBOutlet UIView *selectionIdentifier;

@end

@implementation ShelbyNavBarViewController {
    BOOL _waitingForSelection;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _waitingForSelection = YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.selectionIdentifier.layer.borderColor = [UIColor greenColor].CGColor;
    self.selectionIdentifier.layer.borderWidth = 1.0;
    self.selectionIdentifier.layer.cornerRadius = 2.0;
    self.allRowViews = @[self.streamRow, self.likesRow, self.sharesRow, self.communityRow];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)navRowTapped:(UIButton *)sender {
    UIView *sendingRow = sender.superview;

    if (_waitingForSelection){
        //user made navigation choice...

        NSMutableArray *ignoredRowViews = [self.allRowViews mutableCopy];
        [ignoredRowViews removeObject:sendingRow];

        [UIView animateWithDuration:0.3 animations:^{
            //hide the stuff
            self.view.frame = CGRectMake(0, -(sendingRow.frame.origin.y), self.view.frame.size.width, self.view.frame.size.height);
            for (UIView *v in ignoredRowViews) {
                v.alpha = 0.0;
                v.userInteractionEnabled = NO;
            }

            //update selection
            sendingRow.alpha = 0.85;
            self.selectionIdentifier.frame = CGRectMake(sender.titleLabel.frame.origin.x - 10, sendingRow.frame.origin.y + 19, self.selectionIdentifier.frame.size.width, self.selectionIdentifier.frame.size.height);
        } completion:^(BOOL finished) {
            _waitingForSelection = NO;
        }];
    } else {
        //user wants to navigate...

        [UIView animateWithDuration:0.3 animations:^{
            //show the stuff
            self.view.frame = CGRectMake(0, 10, self.view.frame.size.width, self.view.frame.size.height);
            for (UIView *v in self.allRowViews) {
                v.alpha = 0.95;
                v.userInteractionEnabled = YES;
            }
        } completion:^(BOOL finished) {
            _waitingForSelection = YES;
        }];
    }

    if (sendingRow == self.streamRow) {
        [self.delegate navBarViewControllerStreamWasTapped:self];
    } else if (sendingRow == self.likesRow) {
        [self.delegate navBarViewControllerLikesWasTapped:self];
    } else if (sendingRow == self.sharesRow) {
        [self.delegate navBarViewControllerSharesWasTapped:self];
    } else if (sendingRow == self.communityRow) {
        [self.delegate navBarViewControllerCommunityWasTapped:self];
    } else {
        STVAssert(NO, @"unhandled nav row");
    }
}

@end
