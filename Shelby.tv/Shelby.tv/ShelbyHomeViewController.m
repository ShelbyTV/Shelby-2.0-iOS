//
//  ShelbyHomeViewController.m
//  Shelby.tv
//
//  Created by Keren on 5/1/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyHomeViewController.h"
#import "Appirater.h"
#import "DashboardEntry+Helper.h"
#import "DisplayChannel.h"
#import "ImageUtilities.h"
#import "Roll+Helper.h"
#import "SettingsViewController.h"
#import "ShelbyAlert.h"
#import "ShelbyBrain.h"
#import "ShelbyDataMediator.h"
#import "ShelbyErrorUtility.h"
#import "ShelbyModelArrayUtility.h"
#import "ShelbyNotificationCenterViewController.h"
#import "ShelbyVideoContainer.h"
#import "SPVideoExtractor.h"
#import "SPVideoReelCollectionViewController.h"
#import "User+Helper.h"
#import "BrowseChannelsTableViewController.h"
#import "UserEducationFullOverlayView.h"
#import "ShelbyCustomNavBarButtoniPhone.h"

NSString * const kShelbyShareVideoHasCompleted = @"kShelbyShareVideoHasCompleted";
NSString * const kShelbyShareFrameIDKey = @"frameID";

static NSDictionary *userEducationTypeToLocalyticsAttributeMap;

@interface ShelbyHomeViewController () {
    SettingsViewController *_settingsVC;
    BrowseChannelsTableViewController *_channelsVC;
    UIViewController *_currentFullScreenVC;
}
@property (nonatomic, strong) ShelbyNavBarViewController *navBarVC;

@property (nonatomic, strong) UIView *navBarButtonView;

@property (nonatomic, strong) NSMutableArray *streamBrowseVCs;
@property (nonatomic, strong) ShelbyStreamBrowseViewController *currentStreamBrowseVC;
@property (nonatomic, strong) ShelbyNotificationCenterViewController *notificationCenterVC;
@property (nonatomic, strong) SPVideoReelCollectionViewController *videoReelCollectionVC;
@property (nonatomic, assign) BOOL animationInProgress;

@property (nonatomic, strong) VideoControlsViewController *videoControlsVC;

@property (nonatomic, strong) ShelbyAirPlayController *airPlayController;
//tracking current channel and index (currently used w/ airPlayController only, for autoadvance)
@property (nonatomic, strong) DisplayChannel *currentlyPlayingChannel;
@property (nonatomic, assign) NSInteger currentlyPlayingIndexInChannel;
@property (nonatomic, strong) ShelbyAlert *currentAlertView;

@property (nonatomic, assign) BOOL shareVideoInProgress;

// optionally keep track of the number of times a user has manually scrolled in video streams
// while browsing (not playing video)
@property (nonatomic) BOOL trackStreamScrollCount;
@property (nonatomic) NSUInteger streamScrollCount;
#define NUM_SCROLLS_BETWEEN_EDUCATION_OVERLAYS 2

#define OVERLAY_ANIMATION_DURATION 0.2
#define NAV_BUTTON_FADE_TIME 0.1
#define AUTOADVANCE_INFO_PEEK_DURATION 5.0

@end

@implementation ShelbyHomeViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _airPlayController = [[ShelbyAirPlayController alloc] init];
        _airPlayController.delegate = self;

        userEducationTypeToLocalyticsAttributeMap =
        @{
          @(UserEducationFullOverlayViewTypeStream) : @"stream",
          @(UserEducationFullOverlayViewTypeChannels) : @"channels",
          @(UserEducationFullOverlayViewTypeTwoColumn) : @"two column layout",
          @(UserEducationFullOverlayViewTypeLike) : @"liking"
        };
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    //if we're interested for user education purposes, keep track of how many times the user has manually scrolled while not playing
    if (![UserEducationFullOverlayView isUserEducatedForType:UserEducationFullOverlayViewTypeTwoColumn] || ![UserEducationFullOverlayView isUserEducatedForType:UserEducationFullOverlayViewTypeLike]) {
        self.trackStreamScrollCount = YES;
    }

    // Setting background color to avoid seeing the phone's background
    self.view.backgroundColor = [UIColor blackColor];
    
    /* Order of views:
     * On top of everything, navBar.
     * Just below navBar: videoControls.
     * Everything else gets added below the video controls (ie. streamBrowseVC, videoReel)
     */
    [self setupNavBarView];
    [self setupVideoControlsView];
    [self showNavBarButton];
    
    self.shareVideoInProgress = NO;
    
    [self.view bringSubviewToFront:self.channelsLoadingActivityIndicator];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(noInternetConnectionNotification:)
                                                 name:kShelbyNoInternetConnectionNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(fetchEntriesDidCompleteForChannelNotification:)
                                                 name:kShelbyBrainFetchEntriesDidCompleteForChannelNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(fetchEntriesDidCompleteForChannelWithErrorNotification:)
                                                 name:kShelbyBrainFetchEntriesDidCompleteForChannelWithErrorNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchNotificationEntriesDidCompletelNotification:) name:kShelbyBrainFetchNotificationEntriesDidCompleteNotification object:nil];
   
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(focusOnEntityNotification:)
                                                 name:kShelbyPlaybackEntityDidChangeNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleDidBecomeActiveNotification:)
                                                 name:kShelbyBrainDidBecomeActiveNotification object:nil];


    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleWillResignActiveNotification:)
                                                 name:kShelbyBrainWillResignActiveNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dismissVideoReelNotification:)
                                                 name:kShelbyBrainDismissVideoReelNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                         selector:@selector(videoDidAutoadvanceNotification:)
                                             name:kShelbyBrainDidAutoadvanceNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(setEntriesNotification:)
                                                 name:kShelbyBrainSetEntriesNotification object:nil];

    self.notificationCenterVC = [[ShelbyNotificationCenterViewController alloc] initWithNibName:@"ShelbyNotificationCenterView" bundle:nil];
    self.notificationCenterVC.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
  
    if ([_currentFullScreenVC isKindOfClass:[ShelbyNotificationCenterViewController class]] || [_currentFullScreenVC isKindOfClass:[SettingsViewController class]]) {
        self.videoControlsVC.view.hidden = YES;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    // if the user still needs to be educated about channels, pop open the nav bar and show the channels education overlay
    if (![UserEducationFullOverlayView isUserEducatedForType:UserEducationFullOverlayViewTypeChannels]) {
        [self presentUserEducationFullOverlayViewForType:UserEducationFullOverlayViewTypeChannels];
        [self.navBarVC expand];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)handleDidBecomeActiveNotification:(NSNotification *)notification
{
    //airplay controller does its own thing
}

- (void)handleWillResignActiveNotification:(NSNotification *)notification
{
    if (self.airPlayController.isAirPlayActive) {
        //do not pause when air playing
        return;
    }
    [self pauseCurrentVideo];
}

- (void)setupNavBarView
{
    self.navBarVC = [[ShelbyNavBarViewController alloc] initWithNibName:@"ShelbyNavBarView" bundle:nil];
    self.navBarVC.delegate = self;
    [self.navBarVC willMoveToParentViewController:self];
    [self addChildViewController:self.navBarVC];
    self.navBar = self.navBarVC.view;
    [self.view addSubview:self.navBar];
    self.navBar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[navBar]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:@{@"navBar":self.navBar}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[navBar]"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:@{@"navBar":self.navBar}]];
    [self.navBarVC didMoveToParentViewController:self];

    self.navBarVC.currentUser = self.currentUser;

    //pre-navigate w/o animation for a prettier launch
    if (self.currentUser) {
        [self.navBarVC didNavigateToUsersStream];
    } else {
        [self.navBarVC didNavigateToCommunityChannel];
    }
}

- (void)setupVideoControlsView
{
    _videoControlsVC = [[VideoControlsViewController alloc] initWithNibName:@"VideoControlsView" bundle:nil];
    _videoControlsVC.delegate = self;
    [_videoControlsVC willMoveToParentViewController:self];
    [_videoControlsVC.view setFrame:CGRectMake(0, kShelbyFullscreenHeight - self.videoControlsVC.view.frame.size.height, _videoControlsVC.view.frame.size.width, _videoControlsVC.view.frame.size.height)];
    [self.view insertSubview:_videoControlsVC.view belowSubview:self.navBar];
    _videoControlsVC.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[controls]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:@{@"controls":_videoControlsVC.view}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[controls(88)]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:@{@"controls":_videoControlsVC.view}]];
    [self addChildViewController:_videoControlsVC];
    [_videoControlsVC didMoveToParentViewController:self];

    //if and when airPlayController takes control (from SPVideoReel), it will update video controls w/ current state of SPVideoPlayer
    self.airPlayController.videoControlsVC = _videoControlsVC;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscape;
}

-(BOOL)shouldAutorotate {
    return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];

    //after rotation, we're always showing a full page, controls should not be faded at all
    [self fadeVideoControlsForOffset:CGPointMake(0, 0) frameHeight:self.view.frame.size.height];
}


- (ShelbyStreamBrowseViewController *)initializeStreamBrowseViewController
{
    return [[ShelbyStreamBrowseViewController alloc] initWithNibName:@"ShelbyStreamBrowseView" bundle:nil];
}

// We assume these are all of our channels, in the correct order (which we cared about on old iPad design)
- (void)setChannels:(NSArray *)channels
{
    if (![channels isEqualToArray:_channels]) {
        _channels = channels;

        //find or create new ShelbyStreamBrowseViewControllers for this array of channels
        NSMutableArray *newStreamBrowseVCs = [@[] mutableCopy];
        for (DisplayChannel *ch in channels) {
            ShelbyStreamBrowseViewController *sbvc = [self streamBrowseViewControllerForChannel:ch];
            if (!sbvc) {
                sbvc = [self initializeStreamBrowseViewController];
                [sbvc setEntries:nil forChannel:ch];
                sbvc.browseManagementDelegate = self.masterDelegate;
                //we want to know about scroll events to keep SPVideoReel in sync, when applicable
                sbvc.browseViewDelegate = self;
                sbvc.collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(44, 0, 0, 0);
            }
            [newStreamBrowseVCs addObject:sbvc];
        }
        
        _streamBrowseVCs = newStreamBrowseVCs;
    }
}

- (void)removeChannel:(DisplayChannel *)channel
{    
    NSMutableArray *lessChannels = [_channels mutableCopy];
    [lessChannels removeObject:channel];
    _channels = lessChannels;

    ShelbyStreamBrowseViewController *sbvc = [self streamBrowseViewControllerForChannel:channel];
    if (sbvc) {
        if (sbvc.view.superview) {
            [sbvc.view removeFromSuperview];
            [sbvc removeFromParentViewController];
        }
        [_streamBrowseVCs removeObject:sbvc];
    }
}

//assumes navigation is otherwise correctly set
- (void)focusOnChannel:(DisplayChannel *)channel
{
    ShelbyStreamBrowseViewController *sbvc = [self streamBrowseViewControllerForChannel:channel];
    if (!sbvc || sbvc == _currentFullScreenVC) {
        STVDebugAssert(sbvc, @"should not be asked to focus on a channel we don't have");
        //XXX NB: If there is no internet connection, a channel (ie. featured) may not have been loaded
        //        but that channel is still in the nav bar and can still be selected.  This is how we get here.
        //not changing, nothing to do
        return;
    }

    //our frame NEVER changes b/c we're the root view controller... we just get a 90 deg rotation transform
    //but our bounds reflects this, so we use bounds to set frame on our children...
    sbvc.view.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);

    [self swapOutViewController:_currentFullScreenVC forViewController:sbvc viewDidInsert:^{
        self.currentStreamBrowseVC = sbvc;

        if (!self.airPlayController.isAirPlayActive) {
            self.videoControlsVC.currentEntity = [self.currentStreamBrowseVC entityForCurrentFocus];
            // If there is no content in Stream, don't show video controls
            self.videoControlsVC.view.hidden = sbvc.hasNoContent;
        } else {
            // airplay mode
            // video controls represent airplay video when in airplay mode, don't touch 'em
        }

    } andTransitionAnimationCompleted:nil];
}

- (CGFloat)swapAnimationTime
{
    return 0.5;
}

- (void)swapOutViewController:(UIViewController *)oldVC forViewController:(UIViewController *)newVC viewDidInsert:(void (^)())viewDidInsert andTransitionAnimationCompleted:(void (^)())transitionAnimationCompleted
{
    [oldVC willMoveToParentViewController:nil];
    [self addChildViewController:newVC];
    [self.view insertSubview:newVC.view belowSubview:self.videoControlsVC.view];

    viewDidInsert();
  
    CGAffineTransform scaleAndTranslateIntoNav = CGAffineTransformConcat(CGAffineTransformMakeScale(.2f, .2f), CGAffineTransformMakeTranslation(0, -self.view.bounds.size.height));
    newVC.view.transform = scaleAndTranslateIntoNav;
    newVC.view.alpha = 1.f;

    [UIView transitionWithView:self.view duration:[self swapAnimationTime] options:(UIViewAnimationOptionAllowAnimatedContent | UIViewAnimationOptionCurveEaseOut) animations:^{
        oldVC.view.transform = scaleAndTranslateIntoNav;
        oldVC.view.alpha = 0.f;
        newVC.view.transform = CGAffineTransformIdentity;
        newVC.view.alpha = 1.f;
    } completion:^(BOOL finished) {
        [oldVC removeFromParentViewController];
        [oldVC.view removeFromSuperview];
        oldVC.view.transform = CGAffineTransformIdentity;
        [newVC didMoveToParentViewController:self];
        _currentFullScreenVC = newVC;
        
        if (transitionAnimationCompleted) {
            transitionAnimationCompleted();
        }
   }];
}

- (void)focusOnEntity:(id<ShelbyVideoContainer>)entity inChannel:(DisplayChannel *)channel
{
    [[self streamBrowseViewControllerForChannel:channel] focusOnEntity:entity inChannel:channel animated:YES];
    if (!self.airPlayController.isAirPlayActive) {
        self.videoControlsVC.currentEntity = entity;
    }
}

- (BOOL)mergeCurrentChannelEntries:(NSArray *)curEntries forChannel:(DisplayChannel *)channel withChannelEntries:(NSArray *)channelEntries
{
    if (!curEntries) {
        curEntries = @[];
    }
    
    ShelbyModelArrayUtility *mergeUtil = [ShelbyModelArrayUtility determineHowToMergePossiblyNew:channelEntries intoExisting:curEntries];
    if ([mergeUtil.actuallyNewEntities count]) {
        [self addEntries:mergeUtil.actuallyNewEntities toEnd:mergeUtil.actuallyNewEntitiesShouldBeAppended ofChannel:channel];
        if (!mergeUtil.actuallyNewEntitiesShouldBeAppended) {
            [[SPVideoExtractor sharedInstance] warmCacheForVideoContainer:mergeUtil.actuallyNewEntities[0]];
            
            //if there's a gap between prepended entities and existing entities, fetch again to fill that gap
            if (mergeUtil.gapAfterNewEntitiesBeforeExistingEntities) {
                [[ShelbyDataMediator sharedInstance] fetchEntriesInChannel:channel
                                                                sinceEntry:[mergeUtil.actuallyNewEntities lastObject]];
            }
            return YES;
        }
    } else {
        //full subset, nothing to add
    }
    
    return NO;
}

- (void)logoutUser
{
    // User is logged out, there are no unseen notifications
    [self.navBarVC setUnseenNotificationCount:0];
}

- (void)focusOnEntityNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    DisplayChannel *channel = userInfo[kShelbyPlaybackCurrentChannelKey];
    if (![self streamBrowseViewControllerForChannel:channel]) {
        return;
    }
    
    id<ShelbyVideoContainer> entity = userInfo[kShelbyPlaybackCurrentEntityKey];
    [self focusOnEntity:entity inChannel:channel];
}

- (void)fetchEntriesDidCompleteForChannelWithErrorNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    DisplayChannel *channel = userInfo[kShelbyBrainChannelKey];
    if (![self streamBrowseViewControllerForChannel:channel]) {
        return;
    }

    [self refreshActivityIndicatorForChannel:channel shouldAnimate:NO];
}

- (void)fetchEntriesDidCompleteForChannelNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    DisplayChannel *channel = userInfo[kShelbyBrainChannelKey];
    if (![self streamBrowseViewControllerForChannel:channel]) {
        return;
    }
    
    NSArray *channelEntries = userInfo[kShelbyBrainChannelEntriesKey];
    BOOL cached =  [((NSNumber *)userInfo[kShelbyBrainCachedKey]) boolValue];
    
    NSArray *curEntries = [self entriesForChannel:channel];
    if(curEntries && [curEntries count] && [channelEntries count]){
        [self mergeCurrentChannelEntries:curEntries forChannel:channel withChannelEntries:channelEntries];
    } else {
        // Don't update entries if we have zero entries in cache
        if ([channelEntries count] != 0 || !cached) {
            [self setEntries:channelEntries forChannel:channel];
        }
        
        if ([channelEntries count]) {
            [[SPVideoExtractor sharedInstance] warmCacheForVideoContainer:channelEntries[0]];
        }
    }
    
    if(!cached){
        [self fetchDidCompleteForChannel:channel];
        [self refreshActivityIndicatorForChannel:channel shouldAnimate:NO];
    }
}

- (void)fetchNotificationEntriesDidCompletelNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    
    NSArray *notificationEntries = userInfo[kShelbyBrainChannelEntriesKey];
    
    [self.notificationCenterVC setNotificationEntries:notificationEntries];
}

- (void)setEntriesNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    DisplayChannel *channel = userInfo[kShelbyBrainChannelKey];
    if (![self streamBrowseViewControllerForChannel:channel]) {
        return;
    }
    
    NSArray *channelEntries = userInfo[kShelbyBrainChannelEntriesKey];
    [self setEntries:channelEntries forChannel:channel];
    [self refreshActivityIndicatorForChannel:channel shouldAnimate:NO];
}

- (void)setEntries:(NSArray *)channelEntries forChannel:(DisplayChannel *)channel
{
    ShelbyStreamBrowseViewController *sbvc = [self streamBrowseViewControllerForChannel:channel];
    if (!sbvc) {
        STVDebugAssert(sbvc, @"expected to set entries for a VC we have");
        return;
    }
    
    [sbvc setEntries:channelEntries forChannel:channel];
    if (!self.airPlayController.isAirPlayActive && self.currentStreamBrowseVC.channel == channel && [channelEntries count]) {
        //if you unlike the video you're playing in likes channel, we exit the player to keep things in sync
        [self dismissVideoReel];
        self.videoControlsVC.currentEntity = [self.currentStreamBrowseVC entityForCurrentFocus];
    }
}

- (ShelbyStreamBrowseViewController *)streamBrowseViewControllerForChannel:(DisplayChannel *)channel
{
    for (ShelbyStreamBrowseViewController *sbvc in _streamBrowseVCs) {
        if (sbvc.channel == channel) {
            return sbvc;
        }
    }
    return nil;
}

- (NSInteger)indexOfDisplayedEntry:(id)entry inChannel:(DisplayChannel *)channel
{
    NSArray *dedupdEntries = [self deduplicatedEntriesForChannel:channel];
    return [dedupdEntries indexOfObject:entry];
}

- (void)addEntries:(NSArray *)newChannelEntries toEnd:(BOOL)shouldAppend ofChannel:(DisplayChannel *)channel
{
    @synchronized(self) {
        BOOL playingThisChannel = (self.videoReelCollectionVC && self.videoReelCollectionVC.channel == channel);

        ShelbyStreamBrowseViewController *sbvc = [self streamBrowseViewControllerForChannel:channel];
        [sbvc addEntries:newChannelEntries toEnd:shouldAppend ofChannel:channel maintainingCurrentFocus:playingThisChannel];

        if (self.currentStreamBrowseVC == sbvc) {
            self.videoControlsVC.currentEntity = [sbvc entityForCurrentFocus];
        }

        if (playingThisChannel) {
            [self.videoReelCollectionVC setDeduplicatedEntries:sbvc.deduplicatedEntries];
        }
    }
}

- (void)fetchDidCompleteForChannel:(DisplayChannel *)channel
{
    // This was used for BrowseViewController when we had channels
}

- (NSArray *)entriesForChannel:(DisplayChannel *)channel
{
    return [[self streamBrowseViewControllerForChannel:channel] entriesForChannel:channel];
}

- (NSArray *)deduplicatedEntriesForChannel:(DisplayChannel *)channel
{
    return [[self streamBrowseViewControllerForChannel:channel] deduplicatedEntriesForChannel:channel];
}

- (void)refreshActivityIndicatorForChannel:(DisplayChannel *)channel shouldAnimate:(BOOL)shouldAnimate
{
    [[self streamBrowseViewControllerForChannel:channel] refreshActivityIndicatorShouldAnimate:shouldAnimate];
}

- (void)setMasterDelegate:(id)masterDelegate
{
    _masterDelegate = masterDelegate;

    for (ShelbyStreamBrowseViewController *sbvc in self.streamBrowseVCs) {
        sbvc.browseManagementDelegate = masterDelegate;
    }
}

- (void)setCurrentUser:(User *)currentUser
{
    _currentUser = currentUser;

    if (_currentUser && ![_currentUser isAnonymousUser]) {
        [self.navBarButtonView removeFromSuperview];
        self.navBarButtonView = nil;
    } else {
        [self showNavBarButton];
    }
    
    // If there is SettingsVC, make sure the user is updated
    if (_settingsVC) {
        _settingsVC.user = currentUser;
    }

    self.navBarVC.currentUser = currentUser;
}

- (void)showNavBarButton
{
    if (!self.navBarVC) {
        //views aren't set up yet...
        return;
    }

    if (self.navBarButtonView) {
        [UIView animateWithDuration:NAV_BUTTON_FADE_TIME animations:^{
            self.navBarButtonView.alpha = 1.0;
        }];
    } else if (!self.currentUser || [self.currentUser isAnonymousUser]) {
        self.navBarButtonView = [[UIView alloc] initWithFrame:CGRectMake(5, 5, 80, 34)];
        UIButton *signup = [[ShelbyCustomNavBarButtoniPhone alloc] init];
        [signup setTitle:@"SIGN UP" forState:UIControlStateNormal];
        [signup sizeToFit];
        // move the button away from the edge of the superview a bit
        signup.frame = CGRectOffset(signup.frame, 10, 3);
        [signup addTarget:self action:@selector(navBarButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        [self.navBarButtonView addSubview:signup];

        [self.navBar addSubview:self.navBarButtonView];
        [self.navBarButtonView setAutoresizingMask:UIViewAutoresizingFlexibleRightMargin];
    }
}

- (void)hideNavBarButton
{
    [UIView animateWithDuration:NAV_BUTTON_FADE_TIME animations:^{
        self.navBarButtonView.alpha = 0.0;
    }];
}

- (void)navBarButtonTapped
{
    [ShelbyHomeViewController sendEventWithCategory:kAnalyticsCategoryPrimaryUX
                                         withAction:kAnalyticsUXTapNavBarButton
                                withNicknameAsLabel:YES];
    [ShelbyAnalyticsClient sendLocalyticsEvent:kLocalyticsEventNameSignupStart withAttributes:@{@"from origin" : @"iPhone nav bar button"}];
    [self dismissVideoReel];
    [self.masterDelegate presentUserSignup];
}

- (void)playChannel:(DisplayChannel *)channel atIndex:(NSInteger)index
{
    self.currentlyPlayingChannel = channel;
    self.currentlyPlayingIndexInChannel = index;

    if ([self.airPlayController isAirPlayActive]) {
        //play back on second screen!
        NSArray *channelEntities = [self deduplicatedEntriesForChannel:channel];
        if ((NSUInteger)index >= [channelEntities count]) {
            STVDebugAssert([channelEntities count] > (NSUInteger)index, @"expected a valid index");
            return;
        }
        [self.airPlayController playEntity:channelEntities[index] inChannel:channel];
        [self showAirPlayViewMode:YES];

    } else if (self.videoReelCollectionVC) {
        if (self.videoReelCollectionVC.channel != channel) {
            STVDebugAssert(self.videoReelCollectionVC.channel == channel, @"videoReel should have been shutdown or changed when channel was changed");
            return;
        }
        [self.videoReelCollectionVC playCurrentPlayer];

    } else {
        // prevent display from sleeping while watching video
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
        
        [self initializeVideoReelWithChannel:channel atIndex:index];

        STVDebugAssert([self.videoReelCollectionVC getCurrentPlaybackEntity] == self.videoControlsVC.currentEntity, @"reel entity (%@) should be same as controls entity (%@)", [self.videoReelCollectionVC getCurrentPlaybackEntity], self.videoControlsVC.currentEntity);

        //entering playback: hide the overlays and update controls state
        [UIView animateWithDuration:OVERLAY_ANIMATION_DURATION animations:^{
            self.navBar.alpha = 0.0;
            self.videoControlsVC.view.alpha = 0.0;
            [self streamBrowseViewControllerForChannel:self.videoReelCollectionVC.channel].viewMode = ShelbyStreamBrowseViewForPlaybackWithoutOverlay;
        } completion:^(BOOL finished) {
            [self updateVideoControlsForPage:self.currentStreamBrowseVC.currentPage];
        }];
    }
}

- (void)dismissVideoReelNotification:(NSNotification *)notification
{
    [self dismissVideoReel];
}

- (void)dismissVideoReel
{
    STVDebugAssert([NSThread isMainThread], @"expecting to be called on main thread");
    if (!self.videoReelCollectionVC) {
        return;
    }
    
    if (!self.airPlayController.isAirPlayActive){
        [self.videoReelCollectionVC pauseCurrentPlayer];
    }
    
    [self streamBrowseViewControllerForChannel:self.videoReelCollectionVC.channel].viewMode = ShelbyStreamBrowseViewDefault;
    
    [self.videoReelCollectionVC shutdown];
    [self.videoReelCollectionVC.view removeFromSuperview];
    [self.videoReelCollectionVC removeFromParentViewController];
    self.videoReelCollectionVC = nil;

    //video controls are different w/ and w/o videoReel
    [self updateVideoControlsForPage:self.currentStreamBrowseVC.currentPage];

    // allow display to sleep
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

#pragma mark - ShelbyHome Private methods

- (void)initializeVideoReelWithChannel:(DisplayChannel *)channel atIndex:(NSInteger)index
{
    STVAssert(!_videoReelCollectionVC, @"expected video reel to be shutdown and nil before initializing a new one");
    
    //XXX didn't need to implement this for iPad... do we need it for iPhone?
//    self.videoReelCollectionVC.airPlayView = self.videoControlsVC.airPlayView;
    
    //XXX re-enable this for blurry backdrop view stuff
    //to allow SPVideoReel controls the hidden state of backdrop image
//    self.videoReelBackdropView.showBackdropImage = YES;
    
    self.videoReelCollectionVC = ({
        //initialize with default layout
        SPVideoReelCollectionViewController *reel = [[SPVideoReelCollectionViewController alloc] init];
        reel.delegate = self.masterDelegate;
        reel.videoPlaybackDelegate = self.videoControlsVC;
        
        reel.view.frame = self.currentStreamBrowseVC.view.frame;
//        //iPad only modifications to SPVideoReel
//        reel.view.backgroundColor = [UIColor clearColor];
//        reel.backdropView = self.videoReelBackdropView;
        reel;
    });
    
    [self addChildViewController:self.videoReelCollectionVC];
    [self.view insertSubview:self.videoReelCollectionVC.view belowSubview:self.currentStreamBrowseVC.view];
    
    [self.videoReelCollectionVC didMoveToParentViewController:self];
    
    self.videoReelCollectionVC.channel = channel;
    [self.videoReelCollectionVC setDeduplicatedEntries:[self deduplicatedEntriesForChannel:channel]];
    [self.videoReelCollectionVC scrollForPlaybackAtIndex:index forcingPlayback:YES animated:NO];
}

- (void)videoDidAutoadvanceNotification:(NSNotification *)notification
{
    // This is fine even if someone else auto advance.
    [self doPeekAndHide];
}

- (void)doPeekAndHide
{
    if (self.currentStreamBrowseVC.viewMode == ShelbyStreamBrowseViewForPlaybackWithoutOverlay) {
        //peek basic video info (this is called exactly when the scroll animation to change videos ends)
        [UIView animateWithDuration:OVERLAY_ANIMATION_DURATION*3 animations:^{
            self.currentStreamBrowseVC.viewMode = ShelbyStreamBrowseViewForPlaybackPeeking;
        }];

        //and hide it
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(AUTOADVANCE_INFO_PEEK_DURATION * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            //but make sure user didn't tap and go into regular overlay mode
            if (self.currentStreamBrowseVC.viewMode == ShelbyStreamBrowseViewForPlaybackPeeking) {
                [UIView animateWithDuration:OVERLAY_ANIMATION_DURATION animations:^{
                    self.currentStreamBrowseVC.viewMode = ShelbyStreamBrowseViewForPlaybackWithoutOverlay;
                    self.navBar.alpha = 0.0;
                    self.videoControlsVC.view.alpha = 0.0;
                }];
            }
        });
    }
}

- (void)didNavigateToCommunityChannel
{
    [self.navBarVC didNavigateToCommunityChannel];
}

- (void)didNavigateToUsersStream
{
    [self.navBarVC didNavigateToUsersStream];
    // if the user has already been educated about channels but not the stream, show them stream education now
    if ([UserEducationFullOverlayView isUserEducatedForType:UserEducationFullOverlayViewTypeChannels] &&
        ![UserEducationFullOverlayView isUserEducatedForType:UserEducationFullOverlayViewTypeStream]) {
        [self presentUserEducationFullOverlayViewForType:UserEducationFullOverlayViewTypeStream];
    }
}

- (void)didNavigateToUsersOfflineLikes
{
    [self.navBarVC didNavigateToUsersShares];
}

- (void)didNavigateToUsersRoll
{
    [self.navBarVC didNavigateToUsersShares];
}

- (void)noInternetConnectionNotification:(NSNotification *)notification
{
    if (!self.videoReelCollectionVC) {
        return;
    }
    
    [self dismissVideoReel];
    [UIView animateWithDuration:OVERLAY_ANIMATION_DURATION animations:^{
        self.navBar.alpha = 1.0;
        self.videoControlsVC.view.alpha = 1.0;
    }];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.currentAlertView) {
            self.currentAlertView = [[ShelbyAlert alloc] initWithTitle:@"Error"
                                                               message:@"Please make sure you are connected to the Internet."
                                                    dismissButtonTitle:@"OK"
                                                        autodimissTime:8
                                                             onDismiss:^(BOOL didAutoDimiss) {
                                                                 self.currentAlertView = nil;
                                                             }];
            [self.currentAlertView show];
        }
    });
}

- (void)presentUserEducationFullOverlayViewForType:(UserEducationFullOverlayViewType)overlayViewType
{
    UserEducationFullOverlayView *userEducationView = [UserEducationFullOverlayView viewForType:overlayViewType];

    // add the user education view as the last child of my view so it will cover everything
    userEducationView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:userEducationView];

    // setup constraints to have the user education view completely fill its superview
    NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:userEducationView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0];
    NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:userEducationView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
    NSLayoutConstraint *leadingConstraint = [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:userEducationView attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0];
    NSLayoutConstraint *trailingConstraint = [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:userEducationView attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0.0];
    [self.view addConstraints:@[topConstraint, bottomConstraint, leadingConstraint, trailingConstraint]];

    // track the showing of this view in our analytics system(s)
    NSString *educationTopicAttributeValue = [userEducationTypeToLocalyticsAttributeMap objectForKey:@(overlayViewType)];
    [ShelbyAnalyticsClient sendLocalyticsEvent:kLocalyticsEventNameUserEducationView withAttributes:@{@"type" : @"iphone full overlay", @"topic" : educationTopicAttributeValue}];
}

#pragma mark - ShelbyStreamBrowseViewDelegate

- (void)shelbyStreamBrowseViewController:(ShelbyStreamBrowseViewController *)vc didScrollTo:(CGPoint)contentOffset
{
    if (vc == self.currentStreamBrowseVC) {
        // StreamBrowseView is our leader, videoReel is our follower.  Keep their scrolling synchronized...
        [self.videoReelCollectionVC scrollTo:contentOffset];

        // and fade the video controls when between pages
        [self fadeVideoControlsForOffset:contentOffset frameHeight:vc.view.frame.size.height];
    }
}

//stream browser just landed on a cell.  Update views based on our state...
- (void)shelbyStreamBrowseViewControllerDidEndDecelerating:(ShelbyStreamBrowseViewController *)vc
{
    if (vc != self.currentStreamBrowseVC){
        return;
    }

    if (self.videoReelCollectionVC) {
        BOOL videoShouldHaveBeenPlaying = self.videoReelCollectionVC.shouldBePlaying;
        id<ShelbyVideoContainer> previousPlaybackEntity = [self.videoReelCollectionVC getCurrentPlaybackEntity];
        [self.videoReelCollectionVC endDecelerating];
        id<ShelbyVideoContainer> currentPlaybackEntity = [self.videoReelCollectionVC getCurrentPlaybackEntity];
        self.videoControlsVC.currentEntity = currentPlaybackEntity;

        if (!videoShouldHaveBeenPlaying && currentPlaybackEntity != previousPlaybackEntity) {
            //user paused & changed videos: transition to default view mode (from playback view mode)
            STVDebugAssert(vc.viewMode != ShelbyStreamBrowseViewDefault, @"expected a playback mode, since we have a video reel");
            [self dismissVideoReel];
            STVDebugAssert(vc.viewMode == ShelbyStreamBrowseViewDefault, @"expected dismissVideoReel to update view mode");
            [UIView animateWithDuration:OVERLAY_ANIMATION_DURATION animations:^{
                self.navBar.alpha = 1.0;
                self.videoControlsVC.view.alpha = 1.0;
            }];
            [ShelbyHomeViewController sendEventWithCategory:kAnalyticsCategoryPrimaryUX
                                                 withAction:kAnalyticsUXSwipeCardToChangeVideoPlaybackModePaused
                                        withNicknameAsLabel:YES];
        } else {
            //playing & changed videos: controls already updated
            [self doPeekAndHide];
            [ShelbyHomeViewController sendEventWithCategory:kAnalyticsCategoryPrimaryUX
                                                 withAction:kAnalyticsUXSwipeCardToChangeVideoPlaybackModePlaying
                                        withNicknameAsLabel:YES];
        }
    } else if (self.airPlayController.isAirPlayActive) {
        //not changing video controls current entity
        [ShelbyHomeViewController sendEventWithCategory:kAnalyticsCategoryPrimaryUX
                                             withAction:kAnalyticsUXSwipeCardToChangeVideoPlaybackModeAirPlay
                                    withNicknameAsLabel:YES];

    } else {
        //on iPhone, we only show one stream, so current entity did change
        self.videoControlsVC.currentEntity = [vc entityForCurrentFocus];
        [ShelbyHomeViewController sendEventWithCategory:kAnalyticsCategoryPrimaryUX
                                             withAction:kAnalyticsUXSwipeCardToChangeVideoNonPlaybackMode
                                    withNicknameAsLabel:YES];
        //every few scrolled entries we may want to present some user education
        if (self.trackStreamScrollCount) {
            self.streamScrollCount += 1;
            if (self.streamScrollCount % NUM_SCROLLS_BETWEEN_EDUCATION_OVERLAYS == 0) {
                if (![UserEducationFullOverlayView isUserEducatedForType:UserEducationFullOverlayViewTypeTwoColumn]) {
                    [self presentUserEducationFullOverlayViewForType:UserEducationFullOverlayViewTypeTwoColumn];

                } else if(![UserEducationFullOverlayView isUserEducatedForType:UserEducationFullOverlayViewTypeLike]) {
                    [self presentUserEducationFullOverlayViewForType:UserEducationFullOverlayViewTypeLike];
                    // we've showed them all the education they need, don't need to keep track of scroll count anymore
                    self.trackStreamScrollCount = NO;
                }
            }
        }
    }
}

- (void)shelbyStreamBrowseViewController:(ShelbyStreamBrowseViewController *)browseVC cellParallaxDidChange:(ShelbyStreamBrowseViewCell *)cell
{
    if (self.currentStreamBrowseVC == browseVC && self.videoReelCollectionVC) {
        [self showPlaybackOverlayForCurrentBrowseViewController];
    }
}

- (void)shelbyStreamBrowseViewController:(ShelbyStreamBrowseViewController *)browseVC wasTapped:(UITapGestureRecognizer *)tapGestureRecognizer
{
    if (self.currentStreamBrowseVC == browseVC) {
        if (self.videoReelCollectionVC) {
            [self togglePlaybackOverlayForCurrentBrowseViewController];
        } else {
            STVDebugAssert(browseVC.viewMode == ShelbyStreamBrowseViewDefault || browseVC.viewMode == ShelbyStreamBrowseViewForAirplay, @"should be in play mode w/o video reel");
            [self playChannel:browseVC.channel atIndex:[browseVC indexPathForCurrentFocus].row];
        }
    }
}

- (void)shelbyStreamBrowseViewController:(ShelbyStreamBrowseViewController *)vc didChangeToPage:(NSUInteger)page
{
    STVAssert(page == 0 || page == 1, @"bad page");
    if (self.currentStreamBrowseVC == vc) {
        [self updateVideoControlsForPage:page];
    }
}

- (void)shelbyStreamBrowseViewController:(ShelbyStreamBrowseViewController *)vc hasNoContnet:(BOOL)noContent
{
    if (self.currentStreamBrowseVC == vc) {
        self.videoControlsVC.view.hidden = noContent;
    }
}

- (void)shelbyStreamBrowseViewControllerTitleTapped:(ShelbyStreamBrowseViewController *)vc
{
    // Ignore if video is playing.
    if (!self.videoControlsVC.videoIsPlaying) {
        [self playChannel:self.currentStreamBrowseVC.channel atIndex:[self.currentStreamBrowseVC indexPathForCurrentFocus].row];
    }
}


- (void)inviteFacebookFriendsWasTapped:(ShelbyStreamBrowseViewController *)vc
{
    [self.masterDelegate inviteFacebookFriendsWasTapped];
}

- (void)userProfileWasTapped:(ShelbyStreamBrowseViewController *)vc withUserID:(NSString *)userID
{
    [self dismissVideoReel];
    
    [self.masterDelegate userProfileWasTapped:userID];
}

- (void)launchMyRoll
{
    if ([self.masterDelegate conformsToProtocol:@protocol(ShelbyHomeDelegate)] && [self.masterDelegate respondsToSelector:@selector(goToUsersRoll)]) {
        [self.masterDelegate goToUsersRoll];
    }
}

- (void)launchMyStream
{
    if ([self.masterDelegate conformsToProtocol:@protocol(ShelbyHomeDelegate)] && [self.masterDelegate respondsToSelector:@selector(goToUsersStream)]) {
        [self.masterDelegate goToUsersStream];
    }
}

- (void)launchMyOfflineLikes
{
    if ([self.masterDelegate conformsToProtocol:@protocol(ShelbyHomeDelegate)] && [self.masterDelegate respondsToSelector:@selector(goToUsersOfflineLikes)]) {
        [self.masterDelegate goToUsersOfflineLikes];
    }
}

- (void)launchCommunityChannel
{
    if ([self.masterDelegate conformsToProtocol:@protocol(ShelbyHomeDelegate)] && [self.masterDelegate respondsToSelector:@selector(goToCommunityChannel)]) {
        [self.masterDelegate goToCommunityChannel];
    }
}

- (IBAction)dvrButtonTapped:(UIButton *)sender {
    //super hacky, fine for now
    if ([sender.titleLabel.text isEqualToString:@"DVR"]) {
        if ([self.masterDelegate conformsToProtocol:@protocol(ShelbyHomeDelegate)] && [self.masterDelegate respondsToSelector:@selector(goToDVR)]) {
            [self.masterDelegate goToDVR];
            [sender setTitle:@"Back" forState:UIControlStateNormal];
        }
    } else {
        if ([self.masterDelegate conformsToProtocol:@protocol(ShelbyHomeDelegate)] && [self.masterDelegate respondsToSelector:@selector(goToCommunityChannel)]) {
            [self.masterDelegate goToCommunityChannel];
            [sender setTitle:@"DVR" forState:UIControlStateNormal];
        }
    }
}

- (void)pauseCurrentVideo
{
    [self.airPlayController pauseCurrentPlayer];
    [self.videoReelCollectionVC pauseCurrentPlayer];
}

#pragma mark - VideoControlsDelegate

- (void)videoControlsPlayCurrentVideo:(VideoControlsViewController *)vcvc
{
    [self.airPlayController playCurrentPlayer];
    [self.videoReelCollectionVC playCurrentPlayer];
}

- (void)videoControlsPauseCurrentVideo:(VideoControlsViewController *)vcvc
{
    [self pauseCurrentVideo];
}

- (void)videoControls:(VideoControlsViewController *)vcvc scrubCurrentVideoTo:(CGFloat)pct
{
    [self.airPlayController scrubCurrentPlayerTo:pct];
    [self.videoReelCollectionVC scrubCurrentPlayerTo:pct];
}

-(void)videoControls:(VideoControlsViewController *)vcvc isScrubbing:(BOOL)isScrubbing
{
    //when scrubbing, hide the overlay so we can see (put it back when we're done scrubbing)
    if (isScrubbing) {
        if (self.airPlayController.isAirPlayActive) {
            [self.airPlayController beginScrubbing];
        } else {
            STVDebugAssert(self.currentStreamBrowseVC.viewMode == ShelbyStreamBrowseViewForPlaybackWithOverlay, @"expected overlay to be showing");
            [UIView animateWithDuration:OVERLAY_ANIMATION_DURATION animations:^{
                self.navBar.alpha = 0.0;
                self.currentStreamBrowseVC.viewMode = ShelbyStreamBrowseViewForPlaybackWithoutOverlay;
            }];
            [self.videoReelCollectionVC beginScrubbing];
        }
    } else {
        if (self.airPlayController.isAirPlayActive) {
            [self.airPlayController endScrubbing];
        } else {
            STVDebugAssert(self.currentStreamBrowseVC.viewMode == ShelbyStreamBrowseViewForPlaybackWithoutOverlay, @"expected overlay not showing");
            [UIView animateWithDuration:OVERLAY_ANIMATION_DURATION animations:^{
                self.navBar.alpha = 1.0;
                self.currentStreamBrowseVC.viewMode = ShelbyStreamBrowseViewForPlaybackWithOverlay;
            }];
            [self.videoReelCollectionVC endScrubbing];
        }
    }
}

- (void)videoControlsLikeCurrentVideo:(VideoControlsViewController *)vcvc
{
    // Analytics
    [ShelbyHomeViewController sendEventWithCategory:kAnalyticsCategoryPrimaryUX withAction:kAnalyticsUXLike withNicknameAsLabel:YES];
    // Appirater Event
    [Appirater userDidSignificantEvent:YES];
    
    BOOL didLike = [self likeVideo:vcvc.currentEntity];
    if (!didLike) {
        DLog(@"***ERROR*** Tried to Like '%@', but action resulted in UNLIKE of the video", vcvc.currentEntity.containedVideo.title);
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"heart-large"]];
            NSInteger imageHeight = imageView.frame.size.height;
            NSInteger imageWidth = imageView.frame.size.width;
            NSInteger viewHeight = self.currentStreamBrowseVC.view.frame.size.height;
            NSInteger viewWidth = self.currentStreamBrowseVC.view.frame.size.width;
            imageView.frame = CGRectMake(viewWidth/2 - imageWidth/4, viewHeight/2 - imageHeight/4, imageWidth/2, imageHeight/2);
            [self.currentStreamBrowseVC.view addSubview:imageView];
            [UIView animateWithDuration:0.1 animations:^{
                imageView.frame = CGRectMake(viewWidth/2 - imageWidth/2, viewHeight/2 - imageHeight/2, imageWidth, imageHeight);
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:0.3 animations:^{
                    imageView.alpha = 0.99;
                } completion:^(BOOL finished) {
                    [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationCurveEaseIn animations:^{
                        imageView.frame = CGRectMake(viewWidth/2 - imageWidth/4, viewHeight/2 - imageHeight/4, imageWidth/2, imageHeight/2);
                        imageView.alpha = 0;
                    } completion:^(BOOL finished) {
                        [imageView removeFromSuperview];
                    }];
                }];
            }];
        });
    }
}

- (void)videoControlsUnlikeCurrentVideo:(VideoControlsViewController *)vcvc
{
    [ShelbyHomeViewController sendEventWithCategory:kAnalyticsCategoryPrimaryUX
                                         withAction:kAnalyticsUXUnlike
                                withNicknameAsLabel:YES];
    BOOL didUnlike = [self unlikeVideo:vcvc.currentEntity];
    if (!didUnlike) {
        DLog(@"***ERROR*** Tried to unlike '%@', but action resulted in LIKE of the video", vcvc.currentEntity.containedVideo.title);
    }
}

- (BOOL)likeVideo:(id<ShelbyVideoContainer>)entity
{
    Frame *f = [Frame frameForEntity:entity];
    BOOL didLike = [f doLike];
    return didLike;
}

- (BOOL)unlikeVideo:(id<ShelbyVideoContainer>)entity
{
    Frame *f = [Frame frameForEntity:entity];
    BOOL didUnlike = [f doUnlike];
    return didUnlike;
}

- (void)shareCurrentVideo:(id<ShelbyVideoContainer>)videoContainer
{
    Frame *frame = [Frame frameForEntity:videoContainer];
    NSString *frameID = frame.frameID;

    if (self.shareVideoInProgress) {
        // Send share complete notification since we are not going to share this video. So need to reset the share button
        [[NSNotificationCenter defaultCenter] postNotificationName:kShelbyShareVideoHasCompleted object:self userInfo:@{kShelbyShareFrameIDKey: frameID}];
        return;
    }
    
    self.shareVideoInProgress = YES;
    
    [ShelbyHomeViewController sendEventWithCategory:kAnalyticsCategoryPrimaryUX
                                         withAction:kAnalyticsUXShareStart
                                withNicknameAsLabel:YES];
    SPShareController *shareController = [[SPShareController alloc] initWithVideoFrame:frame fromViewController:self atRect:CGRectZero];
    shareController.delegate = self;
    BOOL shouldResume = self.videoReelCollectionVC.shouldBePlaying;
    [self.videoReelCollectionVC pauseCurrentPlayer];
    
    __weak ShelbyHomeViewController *weakSelf  = self;
    [shareController shareWithCompletionHandler:^(BOOL completed) {
        weakSelf.shareVideoInProgress = NO;
        if (shouldResume) {
            [self.videoReelCollectionVC playCurrentPlayer];
        }
        
        // KP KP: Share is no longer in video controls
        [[NSNotificationCenter defaultCenter] postNotificationName:kShelbyShareVideoHasCompleted object:self userInfo:@{kShelbyShareFrameIDKey: frameID}];

        if (completed) {
            // Analytics
            [ShelbyHomeViewController sendEventWithCategory:kAnalyticsCategoryPrimaryUX
                                                 withAction:kAnalyticsUXShareFinish
                                        withNicknameAsLabel:YES];
            
            // Appirater Event
            [Appirater userDidSignificantEvent:YES];
        }
    }];
}

- (void)openLikersView:(id<ShelbyVideoContainer>)videoContainer withLikers:(NSMutableOrderedSet *)likers
{
    [self dismissVideoReel];
    [self.masterDelegate openLikersViewForVideo:videoContainer.containedVideo withLikers:likers];
}

- (void)scrollToTopOfCurrentStreamBrowseVC
{
    [self.currentStreamBrowseVC scrollToTop];
    if ([self.currentStreamBrowseVC.deduplicatedEntries count]) {
        self.videoControlsVC.currentEntity = self.currentStreamBrowseVC.deduplicatedEntries[0];
    }
    [self dismissVideoReel];
}

#pragma mark - SPShareControllerDelegate

- (void)shareControllerRequestsFacebookPublishPermissions:(SPShareController *)shareController
{
    [self.masterDelegate userAskForFacebookPublishPermissions];
}

- (void)shareControllerRequestsTwitterPublishPermissions:(SPShareController *)shareController
{
    [self.masterDelegate userAskForTwitterPublishPermissions];
}

#pragma mark - ShelbyAirPlayControllerDelegate

- (void)airPlayControllerDidBeginAirPlay:(ShelbyAirPlayController *)airPlayController
{
    // current SPVideoPlayer has a new owner: _airPlayController
    if (self.videoReelCollectionVC) {
        // current SPVideoPlayer will not reset itself b/c it's in external playback mode
        [self dismissVideoReel];
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    }

    [self showAirPlayViewMode:YES];
}

- (void)airPlayControllerDidEndAirPlay:(ShelbyAirPlayController *)airPlayController
{
    //NB: _airPlayController handles shutdown of SPVideoPlayer
    [self showAirPlayViewMode:NO];
}

- (void)airPlayControllerShouldAutoadvance:(ShelbyAirPlayController *)airPlayController
{
    NSArray *channelEntities = [self deduplicatedEntriesForChannel:self.currentlyPlayingChannel];
    if ([channelEntities count] > (NSUInteger)self.currentlyPlayingIndexInChannel+1) {
        [self playChannel:self.currentlyPlayingChannel atIndex:self.currentlyPlayingIndexInChannel+1];
        //self.currentlyPlayingIndexInChannel is now ++
    }

    //fetch more if we're now on the last video in the channel
    if ([channelEntities count] <= (NSUInteger)self.currentlyPlayingIndexInChannel+1) {
        [self.masterDelegate loadMoreEntriesInChannel:self.currentlyPlayingChannel sinceEntry:[channelEntities lastObject]];
    }
}

#pragma mark - View Helpers

- (void)showAirPlayViewMode:(BOOL)airplayMode
{
    if (airplayMode) {
        if (self.currentStreamBrowseVC.viewMode == ShelbyStreamBrowseViewForAirplay) {
            return;
        }
        //enter airplay mode
        [UIView animateWithDuration:OVERLAY_ANIMATION_DURATION animations:^{
            self.currentStreamBrowseVC.viewMode = ShelbyStreamBrowseViewForAirplay;
            self.videoControlsVC.view.alpha = 1.f;
            self.videoControlsVC.displayMode = VideoControlsDisplayForAirPlay;
            self.navBar.alpha = 1.0;
        }];

    } else {
        //exit airplay mode
        STVDebugAssert(self.currentStreamBrowseVC.viewMode == ShelbyStreamBrowseViewForAirplay, @"shouldn't exit airplay when not in airplay");
        [UIView animateWithDuration:OVERLAY_ANIMATION_DURATION animations:^{
            self.currentStreamBrowseVC.viewMode = ShelbyStreamBrowseViewDefault;
        }];
        self.videoControlsVC.currentEntity = [self.currentStreamBrowseVC entityForCurrentFocus];
        [self updateVideoControlsForPage:self.currentStreamBrowseVC.currentPage];
    }
}

- (void)fadeVideoControlsForOffset:(CGPoint)contentOffset frameHeight:(CGFloat)frameHeight
{
    //video controls stay constant when in airplay mode
    if (self.airPlayController.isAirPlayActive) {
        return;
    }

    if (self.currentStreamBrowseVC.viewMode == ShelbyStreamBrowseViewForPlaybackWithoutOverlay || self.currentStreamBrowseVC.viewMode == ShelbyStreamBrowseViewForPlaybackPeeking || self.currentStreamBrowseVC.viewMode == ShelbyStreamBrowseViewForAirplay) {
        return;
    }
    
    // offsetModHeight goes 0->FrameHeight as a page moves offscreen, returning abruptly to 0 as we hit the new page
    NSInteger offsetModHeight = ((NSInteger)contentOffset.y % (NSInteger)frameHeight);
    // normalize offsetModHeight into [0, 1]
    CGFloat offsetModHeightNormalized = offsetModHeight / frameHeight;
    // shift such that we move smoothly from 1->0->1 as we scroll from one page to the next
    CGFloat pageBoundaryDelta = fabsf(1.0 - 2.0 * offsetModHeightNormalized);
    self.videoControlsVC.view.alpha = pageBoundaryDelta*pageBoundaryDelta;
}

- (void)updateVideoControlsForPage:(NSUInteger)page
{
    //video controls stay constant when in airplay mode
    if (self.airPlayController.isAirPlayActive) {
        return;
    }

    [UIView animateWithDuration:OVERLAY_ANIMATION_DURATION animations:^{
        if (self.videoReelCollectionVC) {
            //playback, summary or detail page
            self.videoControlsVC.displayMode = VideoControlsDisplayActionsAndPlaybackControls;
        } else {
            if (page == 0) {
                //non playback, summary page
                self.videoControlsVC.displayMode = VideoControlsDisplayDefault;
            } else {
                //non playback, detail page
                self.videoControlsVC.displayMode = VideoControlsDisplayActionsOnly;
            }
        }
    }];
}

- (void)togglePlaybackOverlayForCurrentBrowseViewController
{
    if (self.currentStreamBrowseVC.viewMode == ShelbyStreamBrowseViewForPlaybackWithoutOverlay || self.currentStreamBrowseVC.viewMode == ShelbyStreamBrowseViewForPlaybackPeeking) {
        [self showPlaybackOverlayForCurrentBrowseViewController];
    } else {
        [self hidePlaybackOverlayForCurrentBrowseViewController];
    }
}

- (void)showPlaybackOverlayForCurrentBrowseViewController
{
    [UIView animateWithDuration:OVERLAY_ANIMATION_DURATION animations:^{
        self.navBar.alpha = 1.0;
        self.videoControlsVC.view.alpha = 1.0;
        self.currentStreamBrowseVC.viewMode = ShelbyStreamBrowseViewForPlaybackWithOverlay;
    }];
}

- (void)hidePlaybackOverlayForCurrentBrowseViewController
{
    [UIView animateWithDuration:OVERLAY_ANIMATION_DURATION animations:^{
        self.navBar.alpha = 0.0;
        self.videoControlsVC.view.alpha = 0.0;
        self.currentStreamBrowseVC.viewMode = ShelbyStreamBrowseViewForPlaybackWithoutOverlay;
    }];
}

#pragma mark - ShelbyNavBarDelegate

- (void)navBarViewControllerWillExpand:(ShelbyNavBarViewController *)navBarVC
{
    [self hideNavBarButton];
}

- (void)navBarViewControllerWillContract:(ShelbyNavBarViewController *)navBarVC
{
    [self showNavBarButton];
}

- (void)navBarViewControllerStreamWasTapped:(ShelbyNavBarViewController *)navBarVC selectionShouldChange:(BOOL)selectedNewRow
{
    if (selectedNewRow) {
        if (self.videoReelCollectionVC) {
            [self dismissVideoReel];
        }
        [self updateVideoControlsForPage:0];
        [self launchMyStream];
    } else {
        [self scrollToTopOfCurrentStreamBrowseVC];
    }

}

- (void)navBarViewControllerSharesWasTapped:(ShelbyNavBarViewController *)navBarVC selectionShouldChange:(BOOL)selectedNewRow
{
    if (selectedNewRow) {
        if (self.videoReelCollectionVC) {
            [self dismissVideoReel];
        }
        [self updateVideoControlsForPage:0];
        if (self.currentUser) {
            //When logged in, likes == shares; both are on user's roll
            [self launchMyRoll];
        } else {
            //If user isn't logged in, we show their offline likes
            [self launchMyOfflineLikes];
        }
    } else {
        [self scrollToTopOfCurrentStreamBrowseVC];
    }
}

- (void)navBarViewControllerCommunityWasTapped:(ShelbyNavBarViewController *)navBarVC selectionShouldChange:(BOOL)selectedNewRow
{
    if (selectedNewRow) {
        if (self.videoReelCollectionVC) {
            [self dismissVideoReel];
        }
        [self updateVideoControlsForPage:0];
        [self launchCommunityChannel];
    } else {
        [self scrollToTopOfCurrentStreamBrowseVC];
    }
}

- (void)navBarViewControllerChannelsWasTapped:(ShelbyNavBarViewController *)navBarVC selectionShouldChange:(BOOL)selectedNewRow
{
    if (selectedNewRow) {
        if (self.videoReelCollectionVC) {
            [self dismissVideoReel];
        }
        [self presentChannels];
        [navBarVC didNavigateToChannels];
    } else {
        //already showing settings, nothing to do
    }

}

- (void)navBarViewControllerSettingsWasTapped:(ShelbyNavBarViewController *)navBarVC selectionShouldChange:(BOOL)selectedNewRow
{
    if (selectedNewRow) {
        if (self.videoReelCollectionVC) {
            [self dismissVideoReel];
        }
        [self presentSettings];
        [navBarVC didNavigateToSettings];
    } else {
        //already showing settings, nothing to do
    }

}

- (void)navBarViewControllerSignupWasTapped:(ShelbyNavBarViewController *)navBarVC selectionShouldChange:(BOOL)selectedNewRow
{
    [self dismissVideoReel];
    [self.masterDelegate presentUserSignup];
    //presentation is modal, nav hasn't actually changed...
    [navBarVC performSelector:@selector(returnSelectionToPreviousRow) withObject:nil afterDelay:0.3];
}

- (void)navBarViewControllerNotificationCenterWasTapped:(ShelbyNavBarViewController *)navBarVC selectionShouldChange:(BOOL)selectedNewRow
{
    if (selectedNewRow) {
        if (self.videoReelCollectionVC) {
            [self dismissVideoReel];
        }
        [self presentNotificationCenter];
        [navBarVC didNavigateToNotificationCenter];
    } else {
        //already showing settings, nothing to do
    }
}

- (void)navBarViewControllerLoginWasTapped:(ShelbyNavBarViewController *)navBarVC selectionShouldChange:(BOOL)selectedNewRow
{
    [self dismissVideoReel];
    [[[UIAlertView alloc] initWithTitle:@"Already Have an Account?"
                                message:@"You're using Shelby without an account. You can continue like this and convert to an account later, or log in with an existing account. Logging in will erase your progress so far."
                               delegate:self
                      cancelButtonTitle:@"Keep Using"
                      otherButtonTitles:@"Erase & Log in", nil] show];
    [navBarVC performSelector:@selector(returnSelectionToPreviousRow) withObject:nil afterDelay:0.3];
}

#pragma mark - UIAlertViewDelegate Methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        [self.masterDelegate logoutUser];
    }
}

#pragma mark - ShelbyNotificationDelegate Methods
- (void)unseenNotificationCountChanged
{
    [self.navBarVC setUnseenNotificationCount:self.notificationCenterVC.unseenNotifications];
}

- (void)userProfileWasTapped:(NSString *)userID
{
    [self.masterDelegate userProfileWasTapped:userID];
}

- (void)videoWasTapped:(NSString *)videoID
{
    [self.masterDelegate openVideoViewForDashboardID:videoID];
}

- (void)presentSettings
{
    if (!_settingsVC) {
        _settingsVC = [[SettingsViewController alloc] initWithUser:self.currentUser andNibName:@"SettingsView-iPhone"];
        _settingsVC.delegate = self.masterDelegate;
        //this gets overriden by autolayout, just using it to set starting point for transition
    }

    _settingsVC.view.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);

    [self swapOutViewController:_currentFullScreenVC forViewController:_settingsVC viewDidInsert:^{
        _settingsVC.view.translatesAutoresizingMaskIntoConstraints = NO;
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[settings]|"
                                                                          options:0
                                                                          metrics:nil
                                                                            views:@{@"settings":_settingsVC.view}]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[settings]|"
                                                                          options:0
                                                                          metrics:nil
                                                                            views:@{@"settings":_settingsVC.view}]];
        
        self.videoControlsVC.view.hidden = YES;
    } andTransitionAnimationCompleted:nil];
}

- (void)presentChannels
{
    if (_channelsVC) {
        _channelsVC = nil;
    }

    _channelsVC = [[UIStoryboard storyboardWithName:@"BrowseChannels" bundle:nil] instantiateInitialViewController];
    _channelsVC.delegate = self.masterDelegate;
    //this gets overriden by autolayout, just using it to set starting point for transition

    _channelsVC.view.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);

    [self swapOutViewController:_currentFullScreenVC forViewController:_channelsVC viewDidInsert:^{
        _channelsVC.view.translatesAutoresizingMaskIntoConstraints = NO;
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[channels]|"
                                                                          options:0
                                                                          metrics:nil
                                                                            views:@{@"channels":_channelsVC.view}]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[channels]|"
                                                                          options:0
                                                                          metrics:nil
                                                                            views:@{@"channels":_channelsVC.view}]];

        self.videoControlsVC.view.hidden = YES;
    } andTransitionAnimationCompleted:nil];
}

- (void)presentNotificationCenter
{
    [self presentNotificationCenterWithCompletionBlock:nil];
}

- (void)presentNotificationCenterWithCompletionBlock:(shelby_home_complete_block_t)completionBlock
{
    if (_currentFullScreenVC == self.notificationCenterVC && _currentFullScreenVC != nil) {
        if (completionBlock) {
            completionBlock();
        }
        return;
    }
    
    //this gets overriden by autolayout, just using it to set starting point for transition
    self.notificationCenterVC.view.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
    
    [self swapOutViewController:_currentFullScreenVC forViewController:self.notificationCenterVC viewDidInsert:^{
        self.notificationCenterVC.view.translatesAutoresizingMaskIntoConstraints = NO;
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[notificationCenter]|"
                                                                          options:0
                                                                          metrics:nil
                                                                            views:@{@"notificationCenter":self.notificationCenterVC.view}]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[notificationCenter]|"
                                                                          options:0
                                                                          metrics:nil
                                                                            views:@{@"notificationCenter":self.notificationCenterVC.view}]];
        
        self.videoControlsVC.view.hidden = YES;
        
     } andTransitionAnimationCompleted:^{
         if (completionBlock) {
             [self.navBarVC didNavigateToNotificationCenter];
             completionBlock();
         }
     }];
}
@end
