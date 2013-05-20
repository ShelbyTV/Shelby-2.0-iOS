//
//  ShelbyHomeViewController.h
//  Shelby.tv
//
//  Created by Keren on 5/1/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BrowseViewController.h"
#import <MessageUI/MessageUI.h>
#import "SettingsViewController.h"
#import "User.h"

@protocol ShelbyHomeDelegate <NSObject>

- (void)loginUserWithEmail:(NSString *)email password:(NSString *)password;
- (void)logoutUser;
- (void)connectToFacebook;
- (void)connectToTwitter;
@end


@interface ShelbyHomeViewController : UIViewController <UIPopoverControllerDelegate, SettingsViewDelegate, AuthorizationDelegate, MFMailComposeViewControllerDelegate>

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

- (void)refreshActivityIndicatorForChannel:(DisplayChannel *)channel shouldAnimate:(BOOL)shouldAnimate;
- (void)loadMoreActivityIndicatorForChannel:(DisplayChannel *)channel shouldAnimate:(BOOL)shouldAnimate;

// KP KP: TODO: merge these two methods. With an :animated property
- (void)launchPlayerForChannel:(DisplayChannel *)channel atIndex:(NSInteger)index;
- (void)animateLaunchPlayerForChannel:(DisplayChannel *)channel atIndex:(NSInteger)index;

- (void)animateDismissPlayerForChannel:(DisplayChannel *)channel atFrame:(Frame *)videoFrame;
- (void)dismissPlayer;

- (void)userLoginFailedWithError:(NSString *)errorMessage;
- (void)connectToFacebookFailedWithError:(NSString *)errorMessage;
@end
