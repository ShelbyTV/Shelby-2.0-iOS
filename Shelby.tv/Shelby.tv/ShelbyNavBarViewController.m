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
    self.navBarView.selectionIdentifier.layer.cornerRadius = 3.0;
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self.navBarView didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

- (void)setCurrentUser:(User *)currentUser
{
    _currentUser = currentUser;
    [self.navBarView showLoggedInUserRows:(_currentUser != nil)];
}

- (void)didNavigateToCommunityChannel
{
    if (self.navBarView.communityButton != self.navBarView.currentRow){
        self.navBarView.currentRow = self.navBarView.communityButton;
    }
}

- (void)didNavigateToUsersStream
{
    if (self.navBarView.streamButton != self.navBarView.currentRow) {
        self.navBarView.currentRow = self.navBarView.streamButton;
    }
}

- (void)didNavigateToUsersLikes
{
    if (self.navBarView.likesButton != self.navBarView.currentRow) {
        self.navBarView.currentRow = self.navBarView.likesButton;
    }
}

- (void)didNavigateToUsersShares
{
    if (self.navBarView.sharesButton != self.navBarView.currentRow) {
        self.navBarView.currentRow = self.navBarView.sharesButton;
    }
}

- (IBAction)navTapped:(UIButton *)sender
{
    if (self.navBarView.currentRow){
        //we _had_ a current row selected, change to showing them all...
        [self.delegate navBarViewControllerWillExpand:self];
        self.navBarView.currentRow = nil;

    } else {
        //we _were_ waiting for a selection to be made...
        [self.delegate navBarViewControllerWillContract:self];
        self.navBarView.currentRow = sender;

        if (sender == self.navBarView.streamButton) {
            [self.delegate navBarViewControllerStreamWasTapped:self];
        } else if (sender == self.navBarView.likesButton) {
            [self.delegate navBarViewControllerLikesWasTapped:self];
        } else if (sender == self.navBarView.sharesButton) {
            [self.delegate navBarViewControllerSharesWasTapped:self];
        } else if (sender == self.navBarView.communityButton) {
            [self.delegate navBarViewControllerCommunityWasTapped:self];
        } else if (sender == self.navBarView.settingsButton) {
            [self.delegate navBarViewControllerSettingsWasTapped:self];
        } else if (sender == self.navBarView.loginButton) {
            [self.delegate navBarViewControllerLoginWasTapped:self];
        } else {
            STVAssert(NO, @"unhandled nav row");
        }

    }
}

@end
