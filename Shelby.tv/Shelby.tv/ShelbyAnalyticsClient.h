//
//  ShelbyAnalyticsClient.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 8/14/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User+Helper.h"

// Shared Constants
//--Screens--
extern NSString * const kAnalyticsScreenLogin;
extern NSString * const kAnalyticsScreenEntrance;
extern NSString * const kAnalyticsScreenChannels;
/* created dynamically: signup, browse, videoReel */
extern NSString * const kAnalyticsScreenSettings;
extern NSString * const kAnalyticsScreenShelbyShare;
extern NSString * const kAnalyticsScreenUserProfile;
extern NSString * const kAnalyticsScreenLikersList;

// Localytics Constants
//--App Entry--
extern NSString * const kLocalyticsEventNameGetStarted;
extern NSString * const kLocalyticsEventNameLoginStart;
extern NSString * const kLocalyticsEventNameLoginComplete;

//--User Education--
extern NSString * const kLocalyticsEventNameShowUserEducation;

//--Signup Flow--
extern NSString * const kLocalyticsEventNameStartSignup;
extern NSString * const kLocalyticsEventNameUpdateUserInfo;

//--Connected Accounts--
extern NSString * const kLocalyticsEventNameStartConnectingAccount;
extern NSString * const kLocalyticsEventNameFinishConnectingAccount;
extern NSString * const kLocalyticsAttributeValueAccountTypeEmail;
extern NSString * const kLocalyticsAttributeValueAccountTypeFacebook;
extern NSString * const kLocalyticsAttributeValueAccountTypeShelby;
extern NSString * const kLocalyticsAttributeValueAccountTypeTwitter;


//--Shared Event Attribute: from origin--
extern NSString * const kLocalyticsAttributeValueFromOriginEntranceScreen;
extern NSString * const kLocalyticsAttributeValueFromOriginSettings;
extern NSString * const kLocalyticsAttributeValueFromOriginSharePane;
extern NSString * const kLocalyticsAttributeValueFromOriginSignup;
extern NSString * const kLocalyticsAttributeValueFromOriginStreamCard;
extern NSString * const kLocalyticsAttributeValueFromOriginUserProfile;


//--Not Yet Updated for Josh+Chris' revamping of Localytics--
extern NSString * const kLocalyticsWatchVideo;
extern NSString * const kLocalyticsWatchVideo25pct;
extern NSString * const kLocalyticsLikeVideo;
extern NSString * const kLocalyticsShareComplete;
extern NSString * const kLocalyticsShareCompleteAnonymousUser;
extern NSString * const kLocalyticsEntranceStart;
extern NSString * const kLocalyticsWelcomeStart;
extern NSString * const kLocalyticsDidLogin;
extern NSString * const kLocalyticsDidLaunchAfterVideoPush;
extern NSString * const kLocalyticsDidLaunchAfterUserPush;
extern NSString * const kLocalyticsDidPreview;
extern NSString * const kLocalyticsFollowUser;
extern NSString * const kLocalyticsFollowingUser;
extern NSString * const kLocalyticsFollowChannel;
extern NSString * const kLocalyticsUnfollowChannel;
extern NSString * const kLocalyticsTapAddChannelsInStream;
extern NSString * const kLocalyticsTapCardSharingUser;
extern NSString * const kLocalyticsTapCardLikersList;
extern NSString * const kLocalyticsTapCardLike;
extern NSString * const kLocalyticsTapCardUnlike;
extern NSString * const kLocalyticsTapCardPlay;
extern NSString * const kLocalyticsTapHideFacebookInStream;
extern NSString * const kLocalyticsTapHideTwitterInStream;
extern NSString * const kLocalyticsTapLikerListLiker;
extern NSString * const kLocalyticsTapPlayerControlsPlay;
extern NSString * const kLocalyticsTapPlayerControlsLike;
extern NSString * const kLocalyticsTapPlayerControlsUnlike;
extern NSString * const kLocalyticsTapPlayerControlsExpand;
extern NSString * const kLocalyticsTapPlayerControlsContract;
extern NSString * const kLocalyticsTapUserProfileFromNotificationView;
extern NSString * const kLocalyticsTapVideoFromNotificationView;
extern NSString * const kLocalyticsTapVideoPlayerOverlayPlay;

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
//--Push--
extern NSString * const kAnalyticsCategoryPush;
extern NSString * const kAnalyticsPushAfterVideoPush;
extern NSString * const kAnalyticsPushAfterUserPush;
//--Primary UX--
extern NSString * const kAnalyticsCategoryPrimaryUX;
extern NSString * const kAnalyticsUXSwipeCardParallax;
extern NSString * const kAnalyticsUXTapAirplay;
extern NSString * const kAnalyticsUXAirplayBegin;
extern NSString * const kAnalyticsUXAirplayEnd;
extern NSString * const kAnalyticsUXTapCardPlayButton;
extern NSString * const kAnalyticsUXTapCardSharingUser;
extern NSString * const kAnalyticsUXTapCardLikersList;
extern NSString * const kAnalyticsUXTapLikerListLiker;
extern NSString * const kAnalyticsUXTapUserProfileFromNotificationView;
extern NSString * const kAnalyticsUXTapVideoFromNotificationView;
extern NSString * const kAnalyticsUXVideoDidAutoadvance;
extern NSString * const kAnalyticsUXSwipeCardToChangeVideoNonPlaybackMode;
extern NSString * const kAnalyticsUXSwipeCardToChangeVideoPlaybackModePlaying;
extern NSString * const kAnalyticsUXSwipeCardToChangeVideoPlaybackModePaused;
extern NSString * const kAnalyticsUXSwipeCardToChangeVideoPlaybackModeAirPlay;
extern NSString * const kAnalyticsUXLike;
extern NSString * const kAnalyticsUXUnlike;
extern NSString * const kAnalyticsUXFollow;
extern NSString * const kAnalyticsUXFollowing;

extern NSString * const kAnalyticsUXShareStart;
extern NSString * const kAnalyticsUXShareFinish;
extern NSString * const kAnalyticsUXTapNavBar;
extern NSString * const kAnalyticsUXTapNavBarButton;
extern NSString * const kAnalyticsUXTapNavBarRowFeatured;
extern NSString * const kAnalyticsUXTapNavBarRowChannels;
extern NSString * const kAnalyticsUXTapNavBarRowLikes;
extern NSString * const kAnalyticsUXTapNavBarRowLogin;
extern NSString * const kAnalyticsUXTapNavBarRowSettings;
extern NSString * const kAnalyticsUXTapNavBarRowShares;
extern NSString * const kAnalyticsUXTapNavBarRowStream;
extern NSString * const kAnalyticsUXTapNavBarRowNotificationCenter;
//--Facebook App Invite--
extern NSString * const kAnalyticsCategoryAppInvite;
extern NSString * const kAnalyticsAppInviteFacebookOpened;
extern NSString * const kAnalyticsAppInviteFacebookCancelled;
extern NSString * const kAnalyticsAppInviteFacebookSent;
//--App Events of Interest--
extern NSString * const kAnalyticsCategoryAppEventOfInterest;
extern NSString * const kAnalyticsAppEventLoadMoreReturnedEmpty;
extern NSString * const kAnalyticsAppEventAirPlayDetected;
//--App Issues--
extern NSString * const kAnalyticsCategoryIssues;
extern NSString * const kAnalyticsIssueContextSaveError;
extern NSString * const kAnalyticsIssueYTExtractionFallback;
extern NSString * const kAnalyticsIssueSTVExtractorFail;
extern NSString * const kAnalyticsIssueSTVVimeoExtractorFail;
extern NSString * const kAnalyticsIssueVideoMissingProviderID;
//--AB Tests--
extern NSString * const kAnalyticsCategoryABTest;
extern NSString * const kAnalyticsABTestRetention;


@interface ShelbyAnalyticsClient : NSObject

//Shared
+ (void)trackScreen:(NSString *)screenName;

//Localytics
+ (void)sendLocalyticsEvent:(NSString *)eventTag;

+ (void)sendLocalyticsEvent:(NSString *)eventTag
             withAttributes:(NSDictionary *)attributes;

+ (void)sendLocalyticsEventForStartConnectingAccountType:(NSString *)accountType fromOrigin:(NSString *)fromOrigin;

+ (void)sendLocalyticsEventForFinishConnectingAccountType:(NSString *)accountType;

// This is used to add an event attribute describing whether or not a string property of something was changed
// during the event and how
// Let's say the property is called "username" and so you pass "username" for the entityName parameter,
// then
// --> if oldValue and newValue are the same, returns attributes with {@"username" : "not updated"} added
// --> if oldValue and newValue are different, and oldValue is nil or an empty string, returns attributes with {@"username" : "added"} added
// --> if oldValue and newValue are different, but oldValue is not nil or not an empty string, returns attributes with {@"username" : "updated"} added
+ (NSDictionary *)addUpdateDescriptionAttributeForEntityName:(NSString *)entityName
                                                toAttributes:(NSDictionary *)attributes
                                                    oldValue:(NSString *)oldValue
                                                    newValue:(NSString *)newValue;

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
