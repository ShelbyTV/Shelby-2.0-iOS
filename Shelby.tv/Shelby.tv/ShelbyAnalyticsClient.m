//
//  ShelbyAnalyticsClient.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 8/14/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyAnalyticsClient.h"
#import "GAI.h"
#import "GAIDictionaryBuilder.h"
#import "GAIFields.h"
#import "GAITracker.h"
#import "LocalyticsSession.h"
#import "ShelbyDataMediator.h"

// Shared Constants
//--Screens--
NSString * const kAnalyticsScreenLogin                                  = @"Login";
NSString * const kAnalyticsScreenEntrance                               = @"Entrance";
NSString * const kAnalyticsScreenChannels                               = @"Channels";
/* created dynamically: signup, browse, videoReel */
NSString * const kAnalyticsScreenSettings                               = @"Settings";
NSString * const kAnalyticsScreenShelbyShare                            = @"Shelby Share";
NSString * const kAnalyticsScreenUserProfile                            = @"User Profile";
NSString * const kAnalyticsScreenLikersList                             = @"Likers List";

// Localytics Constants
//--App Entry--
NSString * const kLocalyticsEventNameGetStarted                         = @"Get Started";
NSString * const kLocalyticsEventNameLoginStart                         = @"Login Start";
NSString * const kLocalyticsEventNameLoginComplete                      = @"Login Complete";

//--User Education--
NSString * const kLocalyticsEventNameUserEducationView                  = @"User Education View";

//--Signup Flow--
NSString * const kLocalyticsEventNameSignupStart                        = @"Signup Start";
NSString * const kLocalyticsEventNameUserInfoUpdate                     = @"User Info Update";

//--Connected Accounts--
NSString * const kLocalyticsEventNameAccountConnectStart                = @"Account Connect Start";
NSString * const kLocalyticsEventNameAccountConnectComplete             = @"Account Connect Complete";
NSString * const kLocalyticsAttributeValueAccountTypeEmail              = @"email";
NSString * const kLocalyticsAttributeValueAccountTypeFacebook           = @"facebook";
NSString * const kLocalyticsAttributeValueAccountTypeShelby             = @"shelby";
NSString * const kLocalyticsAttributeValueAccountTypeTwitter            = @"twitter";

//--User Profile--
NSString * const kLocalyticsEventNameUserProfileView                    = @"User Profile View";

//--Actions on Videos--
NSString * const kLocalyticsEventNameVideoShareStart                    = @"Video Share Start";
NSString * const kLocalyticsEventNameVideoShareComplete                 = @"Video Share Complete";
NSDictionary *activityTypeToShareDestinationStringMap;
NSString * const kLocalyticsEventNameVideoLike                          = @"Video Like";
NSString * const kLocalyticsEventNameVideoUnlike                        = @"Video Unlike";
NSString * const kLocalyticsEventNameFollow                             = @"Follow";
NSString * const kLocalyticsEventNameUnfollow                           = @"Unfollow";

//--Event Attribute Names--
NSString * const kLocalyticsAttributeNameAccountType                    = @"account type";
NSString * const kLocalyticsAttributeNameConnectionType                 = @"connection type";
NSString * const kLocalyticsAttributeNameChannelName                    = @"channel name";
NSString * const kLocalyticsAttributeNameDestinations                   = @"destinations";
NSString * const kLocalyticsAttributeNameFromOrigin                     = @"from origin";
NSString * const kLocalyticsAttributeNameTitle                          = @"title";
NSString * const kLocalyticsAttributeNameTopic                          = @"topic";
NSString * const kLocalyticsAttributeNameType                           = @"type";
NSString * const kLocalyticsAttributeNameUsername                       = @"username";
NSString * const kLocalyticsAttributeNameUserType                       = @"user type";

//--Shared Event Attribute: from origin--
NSString * const kLocalyticsAttributeValueFromOriginChannelsItem        = @"channels item";
NSString * const kLocalyticsAttributeValueFromOriginCustomUrl           = @"custom url";
NSString * const kLocalyticsAttributeValueFromOriginEntranceScreen      = @"entrance screen";
NSString * const kLocalyticsAttributeValueFromOriginFollowedRollsItem   = @"followed rolls item";
NSString * const kLocalyticsAttributeValueFromOriginLikerListItem       = @"liker list item";
NSString * const kLocalyticsAttributeValueFromOriginNotifCenterActor    = @"notification center actor";
NSString * const kLocalyticsAttributeValueFromOriginPushNotification    = @"push notification";
NSString * const kLocalyticsAttributeValueFromOriginSettings            = @"settings";
NSString * const kLocalyticsAttributeValueFromOriginSharePane           = @"share pane";
NSString * const kLocalyticsAttributeValueFromOriginSignup              = @"signup";
NSString * const kLocalyticsAttributeValueFromOriginStreamCard          = @"stream card";
NSString * const kLocalyticsAttributeValueFromOriginUserProfile         = @"user profile";
NSString * const kLocalyticsAttributeValueFromOriginVideoCard           = @"video card";
NSString * const kLocalyticsAttributeValueFromOriginVideoCardOwner      = @"video card owner";
NSString * const kLocalyticsAttributeValueFromOriginVideoControls       = @"video controls";


//--Not Yet Updated for Josh+Chris' revamping of Localytics--
NSString * const kLocalyticsWatchVideo                                  = @"watch";
NSString * const kLocalyticsWatchVideo25pct                             = @"watch_25_pct";
NSString * const kLocalyticsEntranceStart                               = @"entrance_start";
NSString * const kLocalyticsDidLaunchAfterVideoPush                     = @"open_app_via_video_push";
NSString * const kLocalyticsDidPreview                                  = @"did_preview";
NSString * const kLocalyticsTapAddChannelsInStream                      = @"tap_add_channels_in_stream";
NSString * const kLocalyticsTapCardLikersList                           = @"view_likers";
NSString * const kLocalyticsTapCardPlay                                 = @"tap_card_play";
NSString * const kLocalyticsTapHideFacebookInStream                     = @"tap_hide_facebook_in_stream";
NSString * const kLocalyticsTapHideTwitterInStream                      = @"tap_hide_twitter_in_stream";
NSString * const kLocalyticsTapPlayerControlsPlay                       = @"tap_player_controls_play";
NSString * const kLocalyticsTapPlayerControlsExpand                     = @"tap_player_controls_expand";
NSString * const kLocalyticsTapPlayerControlsContract                   = @"tap_player_controls_contract";
NSString * const kLocalyticsTapVideoFromNotificationView                = @"view_video_notification";
NSString * const kLocalyticsTapVideoPlayerOverlayPlay                   = @"tap_video_player_overlay_play";

// Google Analytics Constants
//--Welcome--
NSString * const kAnalyticsCategoryWelcome                              = @"Welcome Flow";
NSString * const kAnalyticsWelcomeStart                                 = @"Start";
NSString * const kAnalyticsWelcomeFinish                                = @"Finish";
NSString * const kAnalyticsWelcomeTapSignup                             = @"Tap Signup";
NSString * const kAnalyticsWelcomeTapSignupWithFacebook                 = @"Tap Signup With Facebook";
NSString * const kAnalyticsWelcomeTapLogin                              = @"Tap Login";
NSString * const kAnalyticsWelcomeTapPreview                            = @"Tap Preview";
//--Login--
NSString * const kAnalyticsCategoryLogin                                = @"Login Screen";
NSString * const kAnalyticsLoginWithEmail                               = @"Tap Login with Email";
NSString * const kAnalyticsLoginWithFacebook                            = @"Tap Login with Facebook";
//--Signup--
NSString * const kAnalyticsCategorySignup                               = @"Signup Flow";
NSString * const kAnalyticsSignupStart                                  = @"Start";
NSString * const kAnalyticsSignupFinish                                 = @"Finish";
NSString * const kAnalyticsSignupWithFacebookStart                      = @"FB Signup Start";
NSString * const kAnalyticsSignupWithFacebookInitialSuccess             = @"FB Signup Initial Success";
NSString * const kAnalyticsSignupStep1Complete                          = @"Step 1 Complete";
NSString * const kAnalyticsSignupStep2Complete                          = @"Step 2 Complete";
NSString * const kAnalyticsSignupStep3Complete                          = @"Step 3 Complete";
NSString * const kAnalyticsSignupSelectSourceToFollow                   = @"Selected Source to Follow";
NSString * const kAnalyticsSignupDeselectSourceToFollow                 = @"Deselected Source to Follow";
NSString * const kAnalyticsSignupConnectAuth                            = @"Connected Auth";
//--Push--
NSString * const kAnalyticsCategoryPush                                 = @"Push Notification";
NSString * const kAnalyticsPushAfterVideoPush                           = @"Open app via video push";
NSString * const kAnalyticsPushAfterUserPush                            = @"Open app via follow push";
//--Primary UX--
NSString * const kAnalyticsCategoryPrimaryUX                            = @"Primary UX";
NSString * const kAnalyticsUXSwipeCardParallax                          = @"Swipe Card Parallax";
NSString * const kAnalyticsUXTapAirplay                                 = @"Tap Airplay";
NSString * const kAnalyticsUXAirplayBegin                               = @"AirPlay Begin";
NSString * const kAnalyticsUXAirplayEnd                                 = @"AirPlay End";
NSString * const kAnalyticsUXTapCardPlayButton                          = @"Tap Card Play Button";
NSString * const kAnalyticsUXTapCardSharingUser                         = @"Tap Card - Sharing User";
NSString * const kAnalyticsUXTapCardLikersList                          = @"Tap Card - Likers List";
NSString * const kAnalyticsUXTapLikerListLiker                          = @"Tap Likers List - Liker";
NSString * const kAnalyticsUXTapUserProfileFromNotificationView         = @"Tap User Profile From Notification View";
NSString * const kAnalyticsUXTapVideoFromNotificationView               =  @"Tap Video From Notification View";
NSString * const kAnalyticsUXVideoDidAutoadvance                        = @"Video Did Autoadvance";
NSString * const kAnalyticsUXSwipeCardToChangeVideoNonPlaybackMode      = @"Swipe Card to Change Video: Non-Playback";
NSString * const kAnalyticsUXSwipeCardToChangeVideoPlaybackModePlaying  = @"Swipe Card to Chagne Video: Playback: Playing";
NSString * const kAnalyticsUXSwipeCardToChangeVideoPlaybackModePaused   = @"Swipe Card to Chagne Video: Playback: Paused";
NSString * const kAnalyticsUXSwipeCardToChangeVideoPlaybackModeAirPlay  = @"Swipe Card to Chagne Video: Playback: AirPlay";
NSString * const kAnalyticsUXLike                                       = @"Like";
NSString * const kAnalyticsUXUnlike                                     = @"Unlike";
NSString * const kAnalyticsUXFollow                                     = @"Tap Follow";
NSString * const kAnalyticsUXFollowing                                  = @"Tap Unfollow";
NSString * const kAnalyticsUXShareStart                                 = @"Share Start";
NSString * const kAnalyticsUXShareFinish                                = @"Share Finish";
NSString * const kAnalyticsUXTapNavBar                                  = @"Tap Nav Bar";
NSString * const kAnalyticsUXTapNavBarButton                            = @"Tap Nav Bar Button";
NSString * const kAnalyticsUXTapNavBarRowFeatured                       = @"Tap Nav Bar - Featured";
NSString * const kAnalyticsUXTapNavBarRowChannels                       = @"Tap Nav Bar - Channels";
NSString * const kAnalyticsUXTapNavBarRowLikes                          = @"Tap Nav Bar - Likes";
NSString * const kAnalyticsUXTapNavBarRowLogin                          = @"Tap Nav Bar - Login";
NSString * const kAnalyticsUXTapNavBarRowSettings                       = @"Tap Nav Bar - Settings";
NSString * const kAnalyticsUXTapNavBarRowShares                         = @"Tap Nav Bar - Shares";
NSString * const kAnalyticsUXTapNavBarRowStream                         = @"Tap Nav Bar - Stream";
NSString * const kAnalyticsUXTapNavBarRowNotificationCenter             = @"Tap Nav Bar - Notification Center";
//--App Invite--
NSString * const kAnalyticsCategoryAppInvite                            = @"App Invite";
NSString * const kAnalyticsAppInviteFacebookOpened                      = @"Facebook App Invite: Opened";
NSString * const kAnalyticsAppInviteFacebookCancelled                   = @"Facebook App Invite: Cancelled";
NSString * const kAnalyticsAppInviteFacebookSent                        = @"Facebook App Invite: Sent";
//--App Events of Interest--
NSString * const kAnalyticsCategoryAppEventOfInterest                   = @"Interesting App Event";
NSString * const kAnalyticsAppEventLoadMoreReturnedEmpty                = @"Load More Returned Empty";
NSString * const kAnalyticsAppEventAirPlayDetected                      = @"iosAirPlayDetected";
//--App Issues--
NSString * const kAnalyticsCategoryIssues                               = @"App Issues";
NSString * const kAnalyticsIssueContextSaveError                        = @"Context Save Error";
NSString * const kAnalyticsIssueYTExtractionFallback                    = @"Fallback to STVYouTubeExtractor";
NSString * const kAnalyticsIssueSTVExtractorFail                        = @"STVYouTubeExtractor Fail";
NSString * const kAnalyticsIssueSTVVimeoExtractorFail                   = @"STVVimeoExtractor Fail";
NSString * const kAnalyticsIssueVideoMissingProviderID                  = @"Video missing providerID";
//--AB Tests--
NSString * const kAnalyticsCategoryABTest                               = @"AB Test";
NSString * const kAnalyticsABTestRetention                              = @"retention1.0";


@implementation ShelbyAnalyticsClient

//Shared
+ (void)initialize {
    activityTypeToShareDestinationStringMap = @{
                                                UIActivityTypeMessage : @"text message",
                                                UIActivityTypePostToFacebook : @"facebook native",
                                                UIActivityTypePostToTwitter : @"twitter native",
                                                UIActivityTypeAirDrop : @"air drop",
                                                UIActivityTypeMail : @"email native"
                                                };
}

+ (void)trackScreen:(NSString *)screenName
{
    //centralizing view tracking by going manual in GA (instead of implicit view tracking via self.screenName)
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:screenName];
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];

    [[LocalyticsSession shared] tagScreen:screenName];
}

+ (NSString *)destinationStringForUIActivityType:(NSString *)activityType
{
    NSString *destinationString = [activityTypeToShareDestinationStringMap valueForKey:activityType];
    if (destinationString)  {
        return destinationString;
    } else {
        return activityType ?: @"unknown";
    }
}

//Localytics
+ (void)sendLocalyticsEvent:(NSString *)eventTag
{
    [[LocalyticsSession shared] tagEvent:eventTag];
}

+ (void)sendLocalyticsEvent:(NSString *)eventTag withAttributes:(NSDictionary *)attributes
{
    [[LocalyticsSession shared] tagEvent:eventTag attributes:attributes];
}

+ (void)sendLocalyticsEvent:(NSString *)eventTag withUserTypeAndAttributes:(NSDictionary *)attributes
{
    NSString *userType = @"unknown";
    User *user = [[ShelbyDataMediator sharedInstance] fetchAuthenticatedUserOnMainThreadContext];
    if (user) {
        userType = [user userTypeStringForAnalytics];
    }

    NSMutableDictionary *attributesPlusUserType = [[NSMutableDictionary alloc] initWithDictionary:attributes];
    [attributesPlusUserType setValue:userType forKey:kLocalyticsAttributeNameUserType];

    [self sendLocalyticsEvent:eventTag withAttributes:attributesPlusUserType];
}

+ (void)sendLocalyticsEventForStartConnectingAccountType:(NSString *)accountType fromOrigin:(NSString *)origin
{
    [self sendLocalyticsEvent:kLocalyticsEventNameAccountConnectStart
    withUserTypeAndAttributes:@{
                                kLocalyticsAttributeNameAccountType : accountType ?: @"unknown",
                                kLocalyticsAttributeNameFromOrigin : origin ?: @"unknown"
                                }];
}

+ (void)sendLocalyticsEventForFinishConnectingAccountType:(NSString *)accountType
{
    // if the user was previously an anonymous user, this was a conversion, otherwise it was just connecting a new account
    NSString *connectionType = @"unknown";
    User *user = [[ShelbyDataMediator sharedInstance] fetchAuthenticatedUserOnMainThreadContext];
    if (user) {
        connectionType = [user isAnonymousUser] ? @"conversion" : @"connection";
    }
    [self sendLocalyticsEvent:kLocalyticsEventNameAccountConnectComplete
                                withAttributes:@{
                                                 kLocalyticsAttributeNameAccountType : accountType ?: @"unknown",
                                                 kLocalyticsAttributeNameConnectionType : connectionType
                                                 }];
}

+ (NSDictionary *)addUpdateDescriptionAttributeForEntityName:(NSString *)entityName
                                                toAttributes:(NSDictionary *)attributes
                                                    oldValue:(NSString *)oldValue
                                                    newValue:(NSString *)newValue;
{
    NSString *propertyChange = @"not updated";
    if (![newValue isEqualToString:oldValue]) {
        if (!oldValue || ![oldValue length]) {
            propertyChange = @"added";
        } else {
            propertyChange = @"updated";
        }
    }

    NSMutableDictionary *newAttributes = [[NSMutableDictionary alloc] init];
    [newAttributes setValue:propertyChange forKey:entityName];
    [newAttributes addEntriesFromDictionary:attributes];
    return newAttributes;
}

//Google Analtyics
+ (void)sendEventWithCategory:(NSString *)category
                       action:(NSString *)action
                        label:(NSString *)label
{
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:category action:action label:label value:nil] build]];
}

+ (void)sendEventWithCategory:(NSString *)category
                       action:(NSString *)action
              nicknameAsLabel:(BOOL)nicknameAsLabel
{
    if (nicknameAsLabel) {
        User __block *user;
        if ([NSThread isMainThread]) {
            NSManagedObjectContext *moc = [[ShelbyDataMediator sharedInstance] mainThreadContext];
            user = [User currentAuthenticatedUserInContext:moc];
        } else {
            DLog(@"ShelbyVC grabbing user on background thread... i don't LOVE this :-/");
            [[ShelbyDataMediator sharedInstance] privateContextPerformBlockAndWait:^(NSManagedObjectContext *privateMOC) {
                user = [User currentAuthenticatedUserInContext:privateMOC];
            }];
        }
        if (user) {
            [self sendEventWithCategory:category action:action label:user.nickname];
        } else {
            [self sendEventWithCategory:category action:action label:@"anonymous"];
        }
    } else {
        [self sendEventWithCategory:category action:action label:nil];
    }
}

+ (void)sendEventWithCategory:(NSString *)category
                       action:(NSString *)action
                        label:(NSString *)label
                        value:(NSNumber *)value
{
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:category action:action label:label value:value] build]];
}

@end
