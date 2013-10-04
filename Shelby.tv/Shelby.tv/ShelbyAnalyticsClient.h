//
//  ShelbyAnalyticsClient.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 8/14/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

// Shared Constants
//--Screens--
extern NSString * const kAnalyticsScreenWelcomeA1;
extern NSString * const kAnalyticsScreenWelcomeA2;
extern NSString * const kAnalyticsScreenWelcomeA3;
extern NSString * const kAnalyticsScreenWelcomeA4l;
extern NSString * const kAnalyticsScreenWelcomeA4r;
extern NSString * const kAnalyticsScreenWelcomeB;
extern NSString * const kAnalyticsScreenLogin;
/* created dynamically: signup, browse, videoReel */
extern NSString * const kAnalyticsScreenSettings;
extern NSString * const kAnalyticsScreenShelbyShare;

// Localytics Constants
extern NSString * const kLocalyticsWatchVideo;
extern NSString * const kLocalyticsLikeVideo;
extern NSString * const kLocalyticsShareComplete;
extern NSString * const kLocalyticsStartSignup;
extern NSString * const kLocalyticsFinishSignup;

// Google Analytics Constants
//--Welcome--
extern NSString * const kAnalyticsCategoryWelcome;
extern NSString * const kAnalyticsWelcomeStart;
extern NSString * const kAnalyticsWelcomeFinish;
extern NSString * const kAnalyticsWelcomeTapSignup;
extern NSString * const kAnalyticsWelcomeTapSignupWithFacebook;
extern NSString * const kAnalyticsWelcomeTapLogin;
extern NSString * const kAnalyticsWelcomeTapPreview;
//--Login--
extern NSString * const kAnalyticsCategoryLogin;
extern NSString * const kAnalyticsLoginWithEmail;
extern NSString * const kAnalyticsLoginWithFacebook;
//--Signup--
extern NSString * const kAnalyticsCategorySignup;
extern NSString * const kAnalyticsSignupStart;
extern NSString * const kAnalyticsSignupFinish;
extern NSString * const kAnalyticsSignupWithFacebookStart;
extern NSString * const kAnalyticsSignupWithFacebookInitialSuccess;
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
extern NSString * const kAnalyticsUXAirplayBegin;
extern NSString * const kAnalyticsUXAirplayEnd;
extern NSString * const kAnalyticsUXTapCardPlayButton;
extern NSString * const kAnalyticsUXVideoDidAutoadvance;
extern NSString * const kAnalyticsUXSwipeCardToChangeVideoNonPlaybackMode;
extern NSString * const kAnalyticsUXSwipeCardToChangeVideoPlaybackModePlaying;
extern NSString * const kAnalyticsUXSwipeCardToChangeVideoPlaybackModePaused;
extern NSString * const kAnalyticsUXSwipeCardToChangeVideoPlaybackModeAirPlay;
extern NSString * const kAnalyticsUXLike;
extern NSString * const kAnalyticsUXUnlike;
extern NSString * const kAnalyticsUXShareStart;
extern NSString * const kAnalyticsUXShareFinish;
extern NSString * const kAnalyticsUXTapNavBar;
extern NSString * const kAnalyticsUXTapNavBarButton;
extern NSString * const kAnalyticsUXTapNavBarRowFeatured;
extern NSString * const kAnalyticsUXTapNavBarRowLikes;
extern NSString * const kAnalyticsUXTapNavBarRowLogin;
extern NSString * const kAnalyticsUXTapNavBarRowSettings;
extern NSString * const kAnalyticsUXTapNavBarRowShares;
extern NSString * const kAnalyticsUXTapNavBarRowStream;
//--Facebook App Invite--
extern NSString * const kAnalyticsCategoryAppInvite;
extern NSString * const kAnalyticsAppInviteFacebookOpened;
extern NSString * const kAnalyticsAppInviteFacebookCancelled;
extern NSString * const kAnalyticsAppInviteFacebookSent;
//--App Events of Interest--
extern NSString * const kAnalyticsCategoryAppEventOfInterest;
extern NSString * const kAnalyticsAppEventLoadMoreReturnedEmpty;
//--App Issues--
extern NSString * const kAnalyticsCategoryIssues;
extern NSString * const kAnalyticsIssueContextSaveError;
extern NSString * const kAnalyticsIssueYTExtractionFallback;
extern NSString * const kAnalyticsIssueSTVExtractorFail;
extern NSString * const kAnalyticsIssueVideoMissingProviderID;
//--AB Tests--
extern NSString * const kAnalyticsCategoryABTest;
extern NSString * const kAnalyticsABTestRetention;


@interface ShelbyAnalyticsClient : NSObject

//Shared
+ (void)trackScreen:(NSString *)screenName;

//Localytics
+ (void)sendLocalyticsEvent:(NSString *)eventTag;

//Google Analytics
+ (void)sendEventWithCategory:(NSString *)category
                       action:(NSString *)action
                        label:(NSString *)label;

+ (void)sendEventWithCategory:(NSString *)category
                       action:(NSString *)action
              nicknameAsLabel:(BOOL)nicknameAsLabel;

+ (void)sendEventWithCategory:(NSString *)category
                       action:(NSString *)action
                        label:(NSString *)label
                        value:(NSNumber *)value;

@end
