//
//  ShelbyViewController.h
//  Shelby.tv
//
//  Created by Keren on 5/14/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "GAITrackedViewController.h"

// Google Analytics Constants
extern NSString * const kAnalyticsCategoryBrowse;
extern NSString * const kAnalyticsBrowseActionLaunchPlaylistSingleTap;
extern NSString * const kAnalyticsBrowseActionLaunchPlaylistVerticalSwipe;
extern NSString * const kAnalyticsBrowseActionClosePlayerByPinch;
//extern NSString * const kAnalyticsCategorySession;
extern NSString * const kAnalyticsCategoryShare;
extern NSString * const kAnalyticsShareActionShareButton;
extern NSString * const kAnalyticsShareActionShareSuccess;
//extern NSString * const kAnalyticsShareActionRollSuccess;
extern NSString * const kAnalyticsCategoryVideoPlayer;
extern NSString * const kAnalyticsVideoPlayerActionSwipeHorizontal;
extern NSString * const kAnalyticsVideoPlayerActionDoubleTap;
extern NSString * const kAnalyticsVideoPlayerToggleLike;
extern NSString * const kAnalyticsVideoPlayerUserScrub;
//--Welcome--
extern NSString * const kAnalyticsCategoryWelcome;
extern NSString * const kAnalyticsWelcomeStart;
extern NSString * const kAnalyticsWelcomeFinish;
extern NSString * const kAnalyticsWelcomeTapSignup;
extern NSString * const kAnalyticsWelcomeTapLogin;
extern NSString * const kAnalyticsWelcomeTapPreview;
//--Signup--
extern NSString * const kAnalyticsCategorySignup;
extern NSString * const kAnalyticsSignupStart;
extern NSString * const kAnalyticsSignupFinish;
extern NSString * const kAnalyticsSignupStep1Complete;
extern NSString * const kAnalyticsSignupStep2Complete;
extern NSString * const kAnalyticsSignupStep3Complete;
extern NSString * const kAnalyticsSignupSelectSourceToFollow;
extern NSString * const kAnalyticsSignupDeselectSourceToFollow;
extern NSString * const kAnalyticsSignupConnectAuth;
//--Primary UX--
extern NSString * const kAnalyticsCategoryPrimaryUX;
extern NSString * const kAnalyticsUXSwipeCardParallax;
extern NSString * const kAnalyticsUXTapAirplay;
extern NSString * const kAnalyticsUXTapCardPlayButton;
extern NSString * const kAnalyticsUXVideoDidAutoadvance;
extern NSString * const kAnalyticsUXSwipeCardToChangeVideoNonPlaybackMode;
extern NSString * const kAnalyticsUXSwipeCardToChangeVideoPlaybackModePlaying;
extern NSString * const kAnalyticsUXSwipeCardToChangeVideoPlaybackModePaused;
extern NSString * const kAnalyticsUXLike;
extern NSString * const kAnalyticsUXUnlike;
extern NSString * const kAnalyticsUXShareStart;
extern NSString * const kAnalyticsUXShareFinish;
extern NSString * const kAnalyticsUXTapNavBar;
extern NSString * const kAnalyticsUXTapNavBarButton;

@interface ShelbyViewController : GAITrackedViewController

+ (void)sendEventWithCategory:(NSString *)category
                   withAction:(NSString *)action
                    withLabel:(NSString *)label;
+ (void)sendEventWithCategory:(NSString *)category
                   withAction:(NSString *)action
          withNicknameAsLabel:(BOOL)nicknameAsLabel;
+ (void)sendEventWithCategory:(NSString *)category
                   withAction:(NSString *)action
                    withLabel:(NSString *)label
                    withValue:(NSNumber *)value;

@end
