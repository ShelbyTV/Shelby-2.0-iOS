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
- (IBAction)navTapped:(id)sender;
@end

@implementation ShelbyNavBarViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navBarView = (ShelbyNavBarView *)self.view;

    self.navBarView.selectionIdentifier.backgroundColor = kShelbyColorGreen;
    self.navBarView.selectionIdentifier.layer.cornerRadius = 2.5;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setCurrentUser:(User *)currentUser
{
    _currentUser = currentUser;
    [self.navBarView showLoggedInUserRows:(_currentUser != nil)];
}

- (void)didNavigateToCommunityChannel
{
    if (self.navBarView.communityRow != self.navBarView.currentRow){
        self.navBarView.currentRow = self.navBarView.communityRow;
    }
}

- (void)didNavigateToUsersStream
{
    if (self.navBarView.streamRow != self.navBarView.currentRow) {
        self.navBarView.currentRow = self.navBarView.streamRow;
    }
}

- (void)didNavigateToUsersLikes
{
    if (self.navBarView.likesRow != self.navBarView.currentRow) {
        self.navBarView.currentRow = self.navBarView.likesRow;
    }
}

- (void)didNavigateToUsersShares
{
    if (self.navBarView.sharesRow != self.navBarView.currentRow) {
        self.navBarView.currentRow = self.navBarView.sharesRow;
    }
}

- (IBAction)navTapped:(UIButton *)sender
{
    UIView *sendingRow = sender.superview;

    if (self.navBarView.currentRow){
        //we _had_ a current row selected, change to showing them all...
        self.navBarView.currentRow = nil;

    } else {
        //we _were_ waiting for a selection to be made...
        self.navBarView.currentRow = sendingRow;

        if (sendingRow == self.navBarView.streamRow) {
            [self.delegate navBarViewControllerStreamWasTapped:self];
        } else if (sendingRow == self.navBarView.likesRow) {
            [self.delegate navBarViewControllerLikesWasTapped:self];
        } else if (sendingRow == self.navBarView.sharesRow) {
            [self.delegate navBarViewControllerSharesWasTapped:self];
        } else if (sendingRow == self.navBarView.communityRow) {
            [self.delegate navBarViewControllerCommunityWasTapped:self];
        } else if (sendingRow == self.navBarView.settingsRow) {
            [self.delegate navBarViewControllerSettingsWasTapped:self];
        } else {
            STVAssert(NO, @"unhandled nav row");
        }

    }
}



//
//- (IBAction)navButtonTapped:(UIButton *)sender {
//    UIView *sendingRow = sender.superview;
//
//    if (self.navBarView.currentRow){
//        //we _had_ a current row selected, change to showing them all...
//        self.navBarView.currentRow = nil;
//
//    } else {
//        //we _were_ waiting for a selection to be made...
//        self.navBarView.currentRow = sendingRow;
//
//        if (sendingRow == self.navBarView.streamRow) {
//            [self.delegate navBarViewControllerStreamWasTapped:self];
//        } else if (sendingRow == self.navBarView.likesRow) {
//            [self.delegate navBarViewControllerLikesWasTapped:self];
//        } else if (sendingRow == self.navBarView.sharesRow) {
//            [self.delegate navBarViewControllerSharesWasTapped:self];
//        } else if (sendingRow == self.navBarView.communityRow) {
//            [self.delegate navBarViewControllerCommunityWasTapped:self];
//        } else if (sendingRow == self.navBarView.settingsRow) {
//            [self.delegate navBarViewControllerSettingsWasTapped:self];
//        } else {
//            STVAssert(NO, @"unhandled nav row");
//        }
//        
//    }
//}

@end
