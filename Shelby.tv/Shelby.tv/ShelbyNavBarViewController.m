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

    self.allRowViews = @[self.streamRow, self.likesRow, self.sharesRow, self.communityRow];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)navRowTapped:(UIView *)sender {
    UIView *sendingRow = sender.superview;

    if (_waitingForSelection){
        //hide the stuff
        NSMutableArray *ignoredRowViews = [self.allRowViews mutableCopy];
        [ignoredRowViews removeObject:sendingRow];
        [UIView animateWithDuration:0.3 animations:^{
            self.view.frame = CGRectMake(0, -(sendingRow.frame.origin.y), self.view.frame.size.width, self.view.frame.size.height);
            for (UIView *v in ignoredRowViews) {
                v.alpha = 0.0;
                v.userInteractionEnabled = NO;
            }
            sendingRow.alpha = 0.85;
        } completion:^(BOOL finished) {
            _waitingForSelection = NO;
        }];
    } else {
        //show the stuff
        [UIView animateWithDuration:0.3 animations:^{
            self.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
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
