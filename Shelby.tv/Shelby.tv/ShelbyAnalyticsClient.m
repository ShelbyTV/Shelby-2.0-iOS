//
//  ShelbyAnalyticsClient.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 8/14/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyAnalyticsClient.h"
#import "GAI.h"
#import "ShelbyDataMediator.h"

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
//--Primary UX--
NSString * const kAnalyticsCategoryPrimaryUX                            = @"Primary UX";
NSString * const kAnalyticsUXSwipeCardParallax                          = @"Swipe Card Parallax";
NSString * const kAnalyticsUXTapAirplay                                 = @"Tap Airplay";
NSString * const kAnalyticsUXAirplayBegin                               = @"AirPlay Begin";
NSString * const kAnalyticsUXAirplayEnd                                 = @"AirPlay End";
NSString * const kAnalyticsUXTapCardPlayButton                          = @"Tap Card Play Button";
NSString * const kAnalyticsUXVideoDidAutoadvance                        = @"Video Did Autoadvance";
NSString * const kAnalyticsUXSwipeCardToChangeVideoNonPlaybackMode      = @"Swipe Card to Change Video: Non-Playback";
NSString * const kAnalyticsUXSwipeCardToChangeVideoPlaybackModePlaying  = @"Swipe Card to Chagne Video: Playback: Playing";
NSString * const kAnalyticsUXSwipeCardToChangeVideoPlaybackModePaused   = @"Swipe Card to Chagne Video: Playback: Paused";
NSString * const kAnalyticsUXSwipeCardToChangeVideoPlaybackModeAirPlay  = @"Swipe Card to Chagne Video: Playback: AirPlay";
NSString * const kAnalyticsUXLike                                       = @"Like";
NSString * const kAnalyticsUXUnlike                                     = @"Unlike";
NSString * const kAnalyticsUXShareStart                                 = @"Share Start";
NSString * const kAnalyticsUXShareFinish                                = @"Share Finish";
NSString * const kAnalyticsUXTapNavBar                                  = @"Tap Nav Bar";
NSString * const kAnalyticsUXTapNavBarButton                            = @"Tap Nav Bar Button";
NSString * const kAnalyticsUXTapNavBarRowFeatured                       = @"Tap Nav Bar - Featured";
NSString * const kAnalyticsUXTapNavBarRowLikes                          = @"Tap Nav Bar - Likes";
NSString * const kAnalyticsUXTapNavBarRowLogin                          = @"Tap Nav Bar - Login";
NSString * const kAnalyticsUXTapNavBarRowSettings                       = @"Tap Nav Bar - Settings";
NSString * const kAnalyticsUXTapNavBarRowShares                         = @"Tap Nav Bar - Shares";
NSString * const kAnalyticsUXTapNavBarRowStream                         = @"Tap Nav Bar - Stream";
//--App Invite--
NSString * const kAnalyticsCategoryAppInvite                            = @"App Invite";
NSString * const kAnalyticsAppInviteFacebookOpened                      = @"Facebook App Invite: Opened";
NSString * const kAnalyticsAppInviteFacebookCancelled                   = @"Facebook App Invite: Cancelled";
NSString * const kAnalyticsAppInviteFacebookSent                        = @"Facebook App Invite: Sent";
//--App Events of Interest--
NSString * const kAnalyticsCategoryAppEventOfInterest                   = @"Interesting App Event";
NSString * const kAnalyticsAppEventLoadMoreReturnedEmpty                = @"Load More Returned Empty";
//--App Issues--
NSString * const kAnalyticsCategoryIssues                               = @"App Issues";
NSString * const kAnalyticsIssueContextSaveError                        = @"Context Save Error";
NSString * const kAnalyticsIssueYTExtractionFallback                    = @"Fallback to STVYouTubeExtractor";
NSString * const kAnalyticsIssueVideoMissingProviderID                  = @"Video missing providerID";

@implementation ShelbyAnalyticsClient

+ (void)sendEventWithCategory:(NSString *)category
                       action:(NSString *)action
                        label:(NSString *)label
{
    BOOL queued = [[GAI sharedInstance].defaultTracker sendEventWithCategory:category withAction:action withLabel:label withValue:nil];

    if (!queued) {
        // dropping, could retry if important
    }
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
    BOOL queued = [[GAI sharedInstance].defaultTracker sendEventWithCategory:category withAction:action withLabel:label withValue:value];

    if (!queued) {
        // dropping, could retry if important
    }
}

@end
