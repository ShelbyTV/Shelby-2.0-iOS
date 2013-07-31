//
//  ShelbyNavBarViewController.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 7/9/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyNavBarViewController.h"
#import "ShelbyNavBarView.h"

@interface ShelbyNavBarViewController () {
    UIView *_lastSelectedRow;
}
@property (nonatomic, weak) ShelbyNavBarView *navBarView;
- (IBAction)navTapped:(id)sender;
@end

@implementation ShelbyNavBarViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _lastSelectedRow = nil;
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
    _lastSelectedRow = self.navBarView.communityButton;
}

- (void)didNavigateToUsersStream
{
    if (self.navBarView.streamButton != self.navBarView.currentRow) {
        self.navBarView.currentRow = self.navBarView.streamButton;
    }
    _lastSelectedRow = self.navBarView.streamButton;
}

- (void)didNavigateToUsersLikes
{
    if (self.navBarView.likesButton != self.navBarView.currentRow) {
        self.navBarView.currentRow = self.navBarView.likesButton;
    }
    _lastSelectedRow = self.navBarView.likesButton;
}

- (void)didNavigateToUsersShares
{
    if (self.navBarView.sharesButton != self.navBarView.currentRow) {
        self.navBarView.currentRow = self.navBarView.sharesButton;
    }
    _lastSelectedRow = self.navBarView.sharesButton;
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
            [self.delegate navBarViewControllerStreamWasTapped:self selectionShouldChange:(_lastSelectedRow != sender)];
        } else if (sender == self.navBarView.likesButton) {
            [self.delegate navBarViewControllerLikesWasTapped:self selectionShouldChange:(_lastSelectedRow != sender)];
        } else if (sender == self.navBarView.sharesButton) {
            [self.delegate navBarViewControllerSharesWasTapped:self selectionShouldChange:(_lastSelectedRow != sender)];
        } else if (sender == self.navBarView.communityButton) {
            [self.delegate navBarViewControllerCommunityWasTapped:self selectionShouldChange:(_lastSelectedRow != sender)];
        } else if (sender == self.navBarView.settingsButton) {
            [self.delegate navBarViewControllerSettingsWasTapped:self selectionShouldChange:(_lastSelectedRow != sender)];
        } else if (sender == self.navBarView.loginButton) {
            [self.delegate navBarViewControllerLoginWasTapped:self selectionShouldChange:(_lastSelectedRow != sender)];
        } else {
            STVAssert(NO, @"unhandled nav row");
        }

    }
}

- (void)returnSelectionToPreviousRow
{
    self.navBarView.currentRow = _lastSelectedRow;
}

// When the nav bar view is expanded, it returns YES for all touches on screen, but then doesn't handle the touch.
// So the event bubbles up to here where we get to handle it.
// In this case, we simply want to collapse the nav bar.
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    //don't care which kind of touches, we'll allow anything to collapse nav bar
    if (!self.navBarView.currentRow) {
        //collapse nav bar, swallow the event
        [self returnSelectionToPreviousRow];
    } else {
        //pass the event up the chain
        [super touchesEnded:touches withEvent:event];
    }
}

@end
