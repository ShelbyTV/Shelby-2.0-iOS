//
//  ShelbyHomeViewController.h
//  Shelby.tv
//
//  Created by Keren on 5/1/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "SettingsViewController.h"
#import "ShelbyAirPlayController.h"
#import "ShelbyNavBarViewController.h"
#import "ShelbyStreamBrowseViewController.h"
#import "SPShareController.h"
#import "User.h"
#import "VideoControlsViewController.h"

@protocol ShelbyHomeDelegate <NSObject>
- (void)presentUserLogin;
- (void)presentUserSignup;
- (void)logoutUser;
- (void)goToDVR;
- (void)goToUsersRoll;
- (void)goToUsersLikes;
- (void)goToUsersStream;
- (void)goToCommunityChannel;
- (void)inviteFacebookFriendsWasTapped;
@end


@interface ShelbyHomeViewController : ShelbyViewController <UIPopoverControllerDelegate, UIAlertViewDelegate, ShelbyStreamBrowseViewDelegate, VideoControlsDelegate, SPShareControllerDelegate, ShelbyNavBarDelegate, ShelbyAirPlayControllerDelegate>

// We assume these are all of our channels, in the correct order
@property (nonatomic, strong) NSArray *channels;
// KP KP: Better way to send the delegete to the views below?
@property (nonatomic, weak) id masterDelegate;
@property (strong, nonatomic) User *currentUser;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *channelsLoadingActivityIndicator;

- (NSInteger)indexOfDisplayedEntry:(id)entry inChannel:(DisplayChannel *)channel;

- (void)fetchDidCompleteForChannel:(DisplayChannel *)channel;
- (void)setEntries:(NSArray *)channelEntries forChannel:(DisplayChannel *)channel;
- (void)addEntries:(NSArray *)newChannelEntries toEnd:(BOOL)shouldAppend ofChannel:(DisplayChannel *)channel;
- (NSArray *)entriesForChannel:(DisplayChannel *)channel;

- (void)removeChannel:(DisplayChannel *)channel;

//currently only used on iPhone to change currently displayed channel
- (void)focusOnChannel:(DisplayChannel *)channel;
- (void)focusOnEntity:(id<ShelbyVideoContainer>)entity inChannel:(DisplayChannel *)channel;

- (void)refreshActivityIndicatorForChannel:(DisplayChannel *)channel shouldAnimate:(BOOL)shouldAnimate;
- (void)loadMoreActivityIndicatorForChannel:(DisplayChannel *)channel shouldAnimate:(BOOL)shouldAnimate;

// *** NEW API ***
// We should use the following two methods exclusively on start/remove playback
- (void)playChannel:(DisplayChannel *)channel atIndex:(NSInteger)index;
- (void)dismissVideoReel;

//allow brain to manage the navigation when necessary
- (void)didNavigateToCommunityChannel;
- (void)didNavigateToUsersStream;
- (void)didNavigateToUsersLikes;
- (void)didNavigateToUsersRoll;

- (void)videoDidAutoadvance;

- (void)handleDidBecomeActive;

@end
