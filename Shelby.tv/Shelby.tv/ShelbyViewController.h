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

@interface ShelbyViewController : GAITrackedViewController

+ (void)sendEventWithCategory:(NSString *)category
                   withAction:(NSString *)action
                    withLabel:(NSString *)label;


@end
