//
//  ShelbyViewController.m
//  Shelby.tv
//
//  Created by Keren on 5/14/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyViewController.h"
#import "ShelbyDataMediator.h"

#import "GAI.h"

// Google Analytics Constants
//--Welcome--
NSString * const kAnalyticsCategoryWelcome                              = @"Welcome Flow";
NSString * const kAnalyticsWelcomeStart                                 = @"Start";
NSString * const kAnalyticsWelcomeFinish                                = @"Finish";
NSString * const kAnalyticsWelcomeTapSignup                             = @"Tap Signup";
NSString * const kAnalyticsWelcomeTapLogin                              = @"Tap Login";
NSString * const kAnalyticsWelcomeTapPreview                            = @"Tap Preview";
//--Signup--
NSString * const kAnalyticsCategorySignup                               = @"Signup Flow";
NSString * const kAnalyticsSignupStart                                  = @"Start";
NSString * const kAnalyticsSignupFinish                                 = @"Finish";
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
NSString * const kAnalyticsUXTapCardPlayButton                          = @"Tap Card Play Button";
NSString * const kAnalyticsUXVideoDidAutoadvance                        = @"Video Did Autoadvance";
NSString * const kAnalyticsUXSwipeCardToChangeVideoNonPlaybackMode      = @"Swipe Card to Change Video: Non-Playback";
NSString * const kAnalyticsUXSwipeCardToChangeVideoPlaybackModePlaying  = @"Swipe Card to Chagne Video: Playback: Playing";
NSString * const kAnalyticsUXSwipeCardToChangeVideoPlaybackModePaused   = @"Swipe Card to Chagne Video: Playback: Paused";
NSString * const kAnalyticsUXLike                                       = @"Like";
NSString * const kAnalyticsUXUnlike                                     = @"Unlike";
NSString * const kAnalyticsUXShareStart                                 = @"Share Start";
NSString * const kAnalyticsUXShareFinish                                = @"Share Finish";
NSString * const kAnalyticsUXTapNavBar                                  = @"Tap Nav Bar";
NSString * const kAnalyticsUXTapNavBarButton                            = @"Tap Nav Bar Button";

@interface ShelbyViewController ()

@end

@implementation ShelbyViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

+ (void)sendEventWithCategory:(NSString *)category
                   withAction:(NSString *)action
                    withLabel:(NSString *)label
{
    BOOL queued = [[GAI sharedInstance].defaultTracker sendEventWithCategory:category withAction:action withLabel:label withValue:nil];

    if (!queued) {
        // TODO: Error?
    }
}

+ (void)sendEventWithCategory:(NSString *)category
                   withAction:(NSString *)action
          withNicknameAsLabel:(BOOL)nicknameAsLabel
{
    if (nicknameAsLabel) {
        NSManagedObjectContext *moc = nil;
        if ([NSThread isMainThread]) {
            moc = [[ShelbyDataMediator sharedInstance] mainThreadContext];
        } else {
            moc = [[ShelbyDataMediator sharedInstance] createPrivateQueueContext];
        }
        User *user = [User currentAuthenticatedUserInContext:moc];
        if (user) {
            [self sendEventWithCategory:category withAction:action withLabel:user.nickname];
        } else {
            [self sendEventWithCategory:category withAction:action withLabel:@"anonymous"];
        }
    } else {
        [self sendEventWithCategory:category withAction:action withLabel:nil];
    }
}

+ (void)sendEventWithCategory:(NSString *)category
                   withAction:(NSString *)action
                    withLabel:(NSString *)label
                    withValue:(NSNumber *)value
{
    BOOL queued = [[GAI sharedInstance].defaultTracker sendEventWithCategory:category withAction:action withLabel:label withValue:value];

    if (!queued) {
        // TODO: Error?
    }
}


@end
