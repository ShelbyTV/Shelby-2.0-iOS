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
extern NSString * const kLocalyticsEventNameUserEducationView;

//--Signup Flow--
extern NSString * const kLocalyticsEventNameSignupStart;
extern NSString * const kLocalyticsEventNameUserInfoUpdate;

//--Connected Accounts--
extern NSString * const kLocalyticsEventNameAccountConnectStart;
extern NSString * const kLocalyticsEventNameAccountConnectComplete;
extern NSString * const kLocalyticsAttributeValueAccountTypeEmail;
extern NSString * const kLocalyticsAttributeValueAccountTypeFacebook;
extern NSString * const kLocalyticsAttributeValueAccountTypeShelby;
extern NSString * const kLocalyticsAttributeValueAccountTypeTwitter;

//--User Profile--
extern NSString * const kLocalyticsEventNameUserProfileView;

//--Actions on Videos--
NSString * const kLocalyticsEventNameVideoShareStart;
NSString * const kLocalyticsEventNameVideoShareComplete;
NSString * const kLocalyticsEventNameVideoLike;
NSString * const kLocalyticsEventNameVideoUnlike;


//--Shared Event Attribute: from origin--
extern NSString * const kLocalyticsAttributeValueFromOriginChannelsItem;
extern NSString * const kLocalyticsAttributeValueFromOriginCustomUrl;
extern NSString * const kLocalyticsAttributeValueFromOriginEntranceScreen;
extern NSString * const kLocalyticsAttributeValueFromOriginFollowedRollsItem;
extern NSString * const kLocalyticsAttributeValueFromOriginLikerListItem;
extern NSString * const kLocalyticsAttributeValueFromOriginNotifCenterActor;
extern NSString * const kLocalyticsAttributeValueFromOriginPushNotification;
extern NSString * const kLocalyticsAttributeValueFromOriginSettings;
extern NSString * const kLocalyticsAttributeValueFromOriginSharePane;
extern NSString * const kLocalyticsAttributeValueFromOriginSignup;
extern NSString * const kLocalyticsAttributeValueFromOriginStreamCard;
extern NSString * const kLocalyticsAttributeValueFromOriginUserProfile;
extern NSString * const kLocalyticsAttributeValueFromOriginVideoCard;
extern NSString * const kLocalyticsAttributeValueFromOriginVideoCardOwner;
extern NSString * const kLocalyticsAttributeValueFromOriginVideoControls;


//--Not Yet Updated for Josh+Chris' revamping of Localytics--
extern NSString * const kLocalyticsWatchVideo;
extern NSString * const kLocalyticsWatchVideo25pct;
extern NSString * const kLocalyticsEntranceStart;
extern NSString * const kLocalyticsDidLaunchAfterVideoPush;
extern NSString * const kLocalyticsDidLaunchAfterUserPush;
extern NSString * const kLocalyticsDidPreview;
extern NSString * const kLocalyticsFollowUser;
extern NSString * const kLocalyticsFollowingUser;
extern NSString * const kLocalyticsFollowChannel;
extern NSString * const kLocalyticsUnfollowChannel;
extern NSString * const kLocalyticsTapAddChannelsInStream;
extern NSString * const kLocalyticsTapCardLikersList;
extern NSString * const kLocalyticsTapCardPlay;
extern NSString * const kLocalyticsTapHideFacebookInStream;
extern NSString * const kLocalyticsTapHideTwitterInStream;
extern NSString * const kLocalyticsTapPlayerControlsPlay;
extern NSString * const kLocalyticsTapPlayerControlsExpand;
extern NSString * const kLocalyticsTapPlayerControlsContract;
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
// translate Apple's techy-looking strings like com.apple.UIKit.activity.PostToTwitter to more readable strings
// like "twitter native" to then be used as attribute values for events
+ (NSString *)destinationStringForUIActivityType:(NSString *)activityType;

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
