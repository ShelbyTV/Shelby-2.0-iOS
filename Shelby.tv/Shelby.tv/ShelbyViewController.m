//
//  ShelbyViewController.m
//  Shelby.tv
//
//  Created by Keren on 5/14/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyViewController.h"

#import "GAI.h"

NSString * const kAnalyticsCategoryBrowse                            = @"Browse Metrics";
NSString * const kAnalyticsBrowseActionLaunchPlaylistSingleTap       = @"Launch player by single tap";
NSString * const kAnalyticsBrowseActionLaunchPlaylistVerticalSwipe   = @"Launch player by vertical swipe";
NSString * const kAnalyticsBrowseActionClosePlayerByPinch            = @"Closed player by pinch";
//NSString * const kAnalyticsCategorySession                           = @"Session Metrics";
NSString * const kAnalyticsCategoryShare                             = @"Share Metrics";
NSString * const kAnalyticsShareActionShareButton                    = @"User did tap share button";
NSString * const kAnalyticsShareActionShareSuccess                   = @"User did successfully share";
//NSString * const kAnalyticsShareActionRollSuccess                    = @"User did successfully roll video";
NSString * const kAnalyticsCategoryVideoPlayer                       = @"Video Player Metrics";
NSString * const kAnalyticsVideoPlayerActionSwipeHorizontal          = @"Swiped video player";
NSString * const kAnalyticsVideoPlayerActionDoubleTap                = @"Playback toggled via double tap gesture";
NSString * const kAnalyticsVideoPlayerToggleLike                     = @"User toggled Like";
NSString * const kAnalyticsVideoPlayerUserScrub                      = @"User did scrub";
//--Welcome--
NSString * const kAnalyticsCategoryWelcome                              = @"Welcome Flow";
NSString * const kAnalyticsWelcomeStart                                 = @"Start";
NSString * const kAnalyticsWelcomeFinish                                = @"Finish";
NSString * const kAnalyticsWelcomeTapSignup                             = @"Tap Signup";
NSString * const kAnalyticsWelcomeTapLogin                              = @"Tap Login";
NSString * const kAnalyticsWelcomeTapPreview                            = @"Tap Preview";

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


@end
