//
//  ShelbyNavBarViewController.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 7/9/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyNavBarViewController.h"
#import "ShelbyNavBarView.h"

@interface ShelbyNavBarViewController ()

@property (nonatomic, weak) ShelbyNavBarView *navBarView;

@property (nonatomic, strong) NSArray *allRowViews;
@property (weak, nonatomic) UIView *currentRow;

@end

@implementation ShelbyNavBarViewController {
    BOOL _waitingForSelection;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _waitingForSelection = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navBarView = (ShelbyNavBarView *)self.view;

    self.allRowViews = @[self.navBarView.streamRow, self.navBarView.likesRow, self.navBarView.sharesRow, self.navBarView.communityRow];

    self.navBarView.selectionIdentifier.layer.borderColor = [UIColor greenColor].CGColor;
    self.navBarView.selectionIdentifier.layer.borderWidth = 1.0;
    self.navBarView.selectionIdentifier.layer.cornerRadius = 2.0;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setCurrentUser:(User *)currentUser
{
    _currentUser = currentUser;
    if (currentUser) {
        self.navBarView.streamRowHeight.constant = 44;
        self.navBarView.streamButton.hidden = NO;
        self.navBarView.sharesRowHeight.constant = 44;
        self.navBarView.sharesButton.hidden = NO;
    } else {
        self.navBarView.streamRowHeight.constant = 0;
        self.navBarView.streamButton.hidden = YES;
        self.navBarView.sharesRowHeight.constant = 0;
        self.navBarView.sharesButton.hidden = YES;
    }

}

- (void)didNavigateToCommunityChannel
{
    if (self.navBarView.communityRow != self.currentRow){
        [self navigateForButton:self.navBarView.communityButton row:self.navBarView.communityRow];
    }
}

- (void)didNavigateToUsersStream
{
    if (self.navBarView.streamRow != self.currentRow) {
        [self navigateForButton:self.navBarView.streamButton row:self.navBarView.streamRow];
    }
}

- (void)didNavigateToUsersLikes
{
    if (self.navBarView.likesRow != self.currentRow) {
        [self navigateForButton:self.navBarView.likesButton row:self.navBarView.likesRow];
    }
}

- (void)didNavigateToUsersShares
{
    if (self.navBarView.sharesRow != self.currentRow) {
        [self navigateForButton:self.navBarView.sharesButton row:self.navBarView.sharesRow];
    }
}

- (IBAction)navButtonTapped:(UIButton *)sender {
    UIView *sendingRow = sender.superview;

    if (_waitingForSelection){
        [self navigateForButton:sender row:sendingRow];

        if (sendingRow == self.navBarView.streamRow) {
            [self.delegate navBarViewControllerStreamWasTapped:self];
        } else if (sendingRow == self.navBarView.likesRow) {
            [self.delegate navBarViewControllerLikesWasTapped:self];
        } else if (sendingRow == self.navBarView.sharesRow) {
            [self.delegate navBarViewControllerSharesWasTapped:self];
        } else if (sendingRow == self.navBarView.communityRow) {
            [self.delegate navBarViewControllerCommunityWasTapped:self];
        } else {
            STVAssert(NO, @"unhandled nav row");
        }

    } else {
        [self showNavigation];
    }
}

- (void)navigateForButton:(UIButton *)sender row:(UIView *)row
{
    self.currentRow = row;
    NSMutableArray *ignoredRowViews = [self.allRowViews mutableCopy];
    [ignoredRowViews removeObject:row];

    [UIView animateWithDuration:0.3 animations:^{
        //hide the stuff
        self.view.frame = CGRectMake(0, -(row.frame.origin.y), self.view.frame.size.width, self.view.frame.size.height);
        for (UIView *v in ignoredRowViews) {
            v.alpha = 0.0;
            v.userInteractionEnabled = NO;
        }

        //update selection
        row.alpha = 0.85;
        self.navBarView.selectionIdentifier.frame = CGRectMake(sender.titleLabel.frame.origin.x - 10, row.frame.origin.y + 19, self.navBarView.selectionIdentifier.frame.size.width, self.navBarView.selectionIdentifier.frame.size.height);
    } completion:^(BOOL finished) {
        _waitingForSelection = NO;
    }];
}

- (void)showNavigation
{
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

@end
