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
    
    [self setUnseenNotificationCount:[self.navBarView.notificationLabel.text intValue]];
}

- (void)setCurrentUser:(User *)currentUser
{
    _currentUser = currentUser;
    [self.navBarView hideRowsForAnonymousUser:[_currentUser isAnonymousUser]];
}

- (void)didNavigateToCommunityChannel
{
    if (self.navBarView.communityButton != self.navBarView.currentRow){
        self.navBarView.currentRow = self.navBarView.communityButton;
    }
    _lastSelectedRow = self.navBarView.communityButton;
}

- (void)didNavigateToChannels
{
    if (self.navBarView.channelsButton != self.navBarView.currentRow){
        self.navBarView.currentRow = self.navBarView.channelsButton;
    }
    _lastSelectedRow = self.navBarView.channelsButton;
}

- (void)didNavigateToUsersStream
{
    if (self.navBarView.streamButton != self.navBarView.currentRow) {
        self.navBarView.currentRow = self.navBarView.streamButton;
    }
    _lastSelectedRow = self.navBarView.streamButton;
}

- (void)didNavigateToUsersShares
{
    if (self.navBarView.sharesButton != self.navBarView.currentRow) {
        self.navBarView.currentRow = self.navBarView.sharesButton;
    }
    _lastSelectedRow = self.navBarView.sharesButton;
}

- (void)didNavigateToSettings
{
    if (self.navBarView.settingsButton != self.navBarView.currentRow) {
        self.navBarView.currentRow = self.navBarView.settingsButton;
    }
    _lastSelectedRow = self.navBarView.settingsButton;
}

- (void)didNavigateToNotificationCenter
{
    if (self.navBarView.notificationCenterButton != self.navBarView.currentRow) {
        self.navBarView.currentRow = self.navBarView.notificationCenterButton;
    }
    _lastSelectedRow = self.navBarView.notificationCenterButton;
}

- (IBAction)navTapped:(UIButton *)sender
{
    [ShelbyNavBarViewController sendEventWithCategory:kAnalyticsCategoryPrimaryUX
                                           withAction:kAnalyticsUXTapNavBar
                                  withNicknameAsLabel:YES];

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
            [ShelbyNavBarViewController sendEventWithCategory:kAnalyticsCategoryPrimaryUX
                                                   withAction:kAnalyticsUXTapNavBarRowStream
                                          withNicknameAsLabel:YES];
        } else if (sender == self.navBarView.sharesButton) {
            [self.delegate navBarViewControllerSharesWasTapped:self selectionShouldChange:(_lastSelectedRow != sender)];
            [ShelbyNavBarViewController sendEventWithCategory:kAnalyticsCategoryPrimaryUX
                                                   withAction:kAnalyticsUXTapNavBarRowShares
                                          withNicknameAsLabel:YES];
        } else if (sender == self.navBarView.communityButton) {
            [self.delegate navBarViewControllerCommunityWasTapped:self selectionShouldChange:(_lastSelectedRow != sender)];
            [ShelbyNavBarViewController sendEventWithCategory:kAnalyticsCategoryPrimaryUX
                                                   withAction:kAnalyticsUXTapNavBarRowFeatured
                                          withNicknameAsLabel:YES];
        } else if (sender == self.navBarView.channelsButton) {
            [self.delegate navBarViewControllerChannelsWasTapped:self selectionShouldChange:(_lastSelectedRow != sender)];
            [ShelbyNavBarViewController sendEventWithCategory:kAnalyticsCategoryPrimaryUX
                                                   withAction:kAnalyticsUXTapNavBarRowChannels
                                          withNicknameAsLabel:YES];
        } else if (sender == self.navBarView.settingsButton) {
            [self.delegate navBarViewControllerSettingsWasTapped:self selectionShouldChange:(_lastSelectedRow != sender)];
            [ShelbyNavBarViewController sendEventWithCategory:kAnalyticsCategoryPrimaryUX
                                                   withAction:kAnalyticsUXTapNavBarRowSettings
                                          withNicknameAsLabel:YES];
        } else if (sender == self.navBarView.signupButton) {
            //not changing nav or ivar, "signupButton" is now used for login... deal with it
            [self.delegate navBarViewControllerLoginWasTapped:self selectionShouldChange:(_lastSelectedRow != sender)];
            [ShelbyNavBarViewController sendEventWithCategory:kAnalyticsCategoryPrimaryUX
                                                   withAction:kAnalyticsUXTapNavBarRowLogin
                                          withNicknameAsLabel:YES];
        } else if (sender == self.navBarView.notificationCenterButton) {
            [self.delegate navBarViewControllerNotificationCenterWasTapped:self selectionShouldChange:(_lastSelectedRow != sender)];
            [ShelbyNavBarViewController sendEventWithCategory:kAnalyticsCategoryPrimaryUX
                                                   withAction:kAnalyticsUXTapNavBarRowNotificationCenter
                                          withNicknameAsLabel:YES];
        } else {
            STVAssert(NO, @"unhandled nav row");
        }
    }
}

- (void)returnSelectionToPreviousRow
{
    self.navBarView.currentRow = _lastSelectedRow;
    [self.delegate navBarViewControllerWillContract:self];
}

- (void)setUnseenNotificationCount:(NSInteger)unseenNotificationCount
{
    self.navBarView.notificationLabel.text = [NSString stringWithFormat:@"%ld", (long)unseenNotificationCount];
    if (unseenNotificationCount) {
        self.navBarView.shouldHideNotificationLabel = NO;
    } else {
        self.navBarView.shouldHideNotificationLabel = YES;
    }
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
