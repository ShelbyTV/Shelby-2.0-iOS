//
//  SPVideoReel.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/1/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import "SPVideoReel.h"
#import "SPOverlayView.h"
#import "SPVideoExtractor.h"
#import "SPVideoItemView.h"
#import "SPVideoPlayer.h"
#import "SPVideoScrubber.h"
#import "DeviceUtilities.h"
#import "SPCategoryViewCell.h"
#import "SPLikesCatgoryViewCell.h"
#import "TwitterHandler.h"
#import "FacebookHandler.h"

@interface SPVideoReel ()

@property (weak, nonatomic) AppDelegate *appDelegate;
@property (weak, nonatomic) SPModel *model;
@property (weak, nonatomic) SPOverlayView *overlayView;
@property (nonatomic) UIScrollView *videoScrollView;
@property (nonatomic) NSMutableArray *videoFrames;
@property (nonatomic) NSMutableArray *moreVideoFrames;
@property (nonatomic) NSMutableArray *videoPlayers;
@property (nonatomic) NSMutableArray *playableVideoPlayers;
@property (nonatomic) NSMutableArray *itemViews;
@property (copy, nonatomic) NSString *categoryID;
@property (assign, nonatomic) BOOL fetchingOlderVideos;
@property (assign, nonatomic) BOOL loadingOlderVideos;
@property (assign, nonatomic) SecretMode secretMode;

// Make sure we let user roll immediately after they log in.
@property (nonatomic) NSInvocation *invocationMethod;

@property (nonatomic) NSMutableArray *categories; // TODO: to move to a collection view data file
@property (nonatomic) NSString *userNickname; // TODO: refactor out!!

/// Setup Methods
- (void)setup;
- (void)setupVideoFrames:(NSArray *)videoFrames;
- (void)setupVariables;
- (void)setupObservers;
- (void)setupVideoScrollView;
- (void)setupVideoListScrollView;
- (void)setupOverlayView;
- (void)setupAirPlay;
- (void)setupVideoPlayers;
- (void)setupGestures;
- (void)setupOverlayVisibileItems;

/// Storage Methods
- (void)storeIdentifierOfCurrentVideoInStream;

/// Update Methods
- (void)currentVideoDidChangeToVideo:(NSUInteger)position;
- (void)updatePlaybackUI;
- (void)queueMoreVideos:(NSUInteger)position;
- (void)fetchOlderVideos:(NSUInteger)position;
- (void)dataSourceShouldUpdateFromLocalArray;
- (void)dataSourceShouldUpdateFromWeb:(NSNotification *)notification;
- (void)dataSourceDidUpdate;
- (void)scrollToNextVideoAfterUnplayableVideo:(NSNotification*)notification;
- (void)purgeVideoPlayerInformationFromPreviousVideoGroup;

/// Gesture Methods
- (void)togglePlaylist:(UISwipeGestureRecognizer *)gesture;

/// Action Methods
- (IBAction)shareButtonAction:(id)sender;
- (IBAction)likeAction:(id)sender;
- (IBAction)rollAction:(id)sender;
- (void)rollVideo;
- (void)launchUserGroup:(NSUInteger)groupNumber;
- (void)launchCategory:(id)category;
- (void)launchStream;
- (void)launchLikes;
- (void)launchPersonalRoll;

/// Secret Modes
- (void)resetSecretVersionButton;
- (void)toggleSecretModes:(id)sender;

@end

@implementation SPVideoReel 

#pragma mark - Memory Management
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kShelbySPUserDidScrollToUpdate object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kShelbySPLoadVideoAfterUnplayableVideo object:nil];
    
    DLog(@"SPVideoReel Deallocated");
}

#pragma mark - Initialization
- (void)loadWithGroupType:(GroupType)groupType
               groupTitle:(NSString *)title
              videoFrames:(NSMutableArray *)videoFrames
            andCategoryID:(NSString *)categoryID
{
    [self setCategoryID:categoryID];
    [self loadWithGroupType:groupType groupTitle:title andVideoFrames:videoFrames];
}

- (void)loadWithGroupType:(GroupType)groupType
               groupTitle:(NSString *)title
           andVideoFrames:(NSMutableArray *)videoFrames
{
    [self setGroupType:groupType];
    [self setGroupTitle:title];
    [self setupVideoFrames:videoFrames];
    [self setup];
}

- (void)buildViewAndFetchDataSource
{
    [self fetchAllCategories];
    [self fetchUserNickname];
    
    [self setup];
    
}

#pragma mark - View Lifecycle Methods
- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setCategories:[@[] mutableCopy]];
 
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    [self.view setFrame:CGRectMake(0.0f, 0.0f, kShelbySPVideoWidth, kShelbySPVideoHeight)];
    [self.view setBackgroundColor:[UIColor blackColor]];
    
}

#pragma mark - Setup Methods
- (void)setup
{
    
    id defaultTracker = [GAI sharedInstance].defaultTracker;
    [defaultTracker sendEventWithCategory:kGAICategoryBrowse
                               withAction:@"User did launch playlist"
                                withLabel:_groupTitle
                                withValue:nil];

    [self purgeVideoPlayerInformationFromPreviousVideoGroup];
    
    [self setTrackedViewName:[NSString stringWithFormat:@"Playlist - %@", _groupTitle]];
    [self setupVariables];
    [self setupObservers];
    [self setupVideoScrollView];
    [self setupOverlayView];
    [self setupGestures];
    [self setupVideoPlayers];
    [self setupVideoListScrollView];
    [self setupAirPlay];
    [self setupOverlayVisibileItems];

}

- (void)setupVideoFrames:(NSMutableArray *)videoFrames
{
    
    if ( _videoFrames ) {
        [self.videoFrames removeAllObjects];
        self.videoFrames = nil;
    }
    
    if ( _moreVideoFrames ) {
        [self.moreVideoFrames removeAllObjects];
        self.moreVideoFrames = nil;
    }
    
    self.videoFrames = [@[] mutableCopy];
    
    if ( [videoFrames count] > 20 ) { // If there are more than 20 frames in videoFrames
        
        for (Frame *videoFrame in videoFrames) {
            
            if ([self.videoFrames count] < 20) { // Load the first 20 videoFrames into _videoFrames
                
                [self.videoFrames addObject:videoFrame];
                
            } else { // Load the rest of the videoFrames into _moreVideoFrames
                
                if (!self.moreVideoFrames) {
                    self.moreVideoFrames = [@[] mutableCopy];
                }
                
                [self.moreVideoFrames addObject:videoFrame];
                
            }
        }
        
    } else { // If there are <= 20 frames in videoFrames
        
        self.videoFrames = [NSMutableArray arrayWithArray:videoFrames];
        
    }
}

- (void)setupVariables
{
    /// AppDelegate
    self.appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    /// Model
    self.model = [SPModel sharedInstance];
    self.model.videoReel = self;
    self.model.groupType = _groupType;
    self.model.numberOfVideos = [self.videoFrames count];

    /// NSMutableArrays
    if ( !_videoPlayers ) {
        self.videoPlayers = [@[] mutableCopy];
    }
    
    if ( !_itemViews ) {
        self.itemViews = [@[] mutableCopy];
    }
}


- (void)setupObservers
{
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dataSourceShouldUpdateFromWeb:)
                                                 name:kShelbySPUserDidScrollToUpdate
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(scrollToNextVideoAfterUnplayableVideo:)
                                                 name:kShelbySPLoadVideoAfterUnplayableVideo
                                               object:nil];
    
}

- (void)setupVideoScrollView
{
    
    if ( ![[self.view subviews] containsObject:_videoScrollView] ) {
        
        self.videoScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, kShelbySPVideoWidth, kShelbySPVideoHeight)];
        self.videoScrollView.delegate = self;
        self.videoScrollView.pagingEnabled = YES;
        self.videoScrollView.showsHorizontalScrollIndicator = NO;
        self.videoScrollView.showsVerticalScrollIndicator = NO;
        self.videoScrollView.scrollsToTop = NO;
        [self.videoScrollView setDelaysContentTouches:YES];
        [self.view addSubview:_videoScrollView];
        
    }
    
    self.videoScrollView.contentSize = CGSizeMake(kShelbySPVideoWidth * [self.model numberOfVideos], kShelbySPVideoHeight);
    [self.videoScrollView setContentOffset:CGPointMake(0, 0) animated:YES];
    
}

- (void)setupOverlayView
{
    
    if ( ![[self.view subviews] containsObject:_overlayView] ) {
        
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SPOverlayView" owner:self options:nil];
        if (![nib isKindOfClass:[NSArray class]] || [nib count] == 0 || ![nib[0] isKindOfClass:[UIView class]]) {
            return;
        }
        
        self.overlayView = nib[0];
        self.model.overlayView = [self overlayView];
        [self.view addSubview:_overlayView];
        
    } else {
        
        self.model.overlayView = [self overlayView];
        
    }


    if ( [[NSUserDefaults standardUserDefaults] boolForKey:kShelbyDefaultUserAuthorized] && ![self.overlayView.versionButton isEnabled] ) {

        /* 
         Show version button if user
         - is logged in
         - is administrator
         - button was not previously enabled
         */
        
        CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
        User *user = [dataUtility fetchUser];
        BOOL isAdmin = [user admin];
        
        if ( isAdmin ) {
        
            [self resetSecretVersionButton];
            
        }
        
    }
    
}

- (void)setupVideoPlayers
{
    if ( [self.model numberOfVideos] ) {

        for ( NSUInteger i = 0; i < _model.numberOfVideos; ++i ) {
            
            Frame *videoFrame = (self.videoFrames)[i];
            
            CGRect viewframe = [self.videoScrollView frame];
            viewframe.origin.x = viewframe.size.width * i;
            viewframe.origin.y = 0.0f;
            SPVideoPlayer *player = [[SPVideoPlayer alloc] initWithBounds:viewframe withVideoFrame:videoFrame];
            
            [self.videoPlayers addObject:player];
            [self.videoScrollView addSubview:player.view];
            
            if ( 0 == i ) {
                
                self.model.currentVideo = 0;
                self.model.currentVideoPlayer = (self.videoPlayers)[_model.currentVideo];
                
            }
            
        }
        
        if ( _groupType == GroupType_Stream ) {  // If  stream, play video stored for kShelbySPCurrentVideoStreamID if it exists. Otherwise, default to video at zeroeth position
            for ( NSUInteger i = 0; i < [self.model numberOfVideos]; ++i ) {
                
                Frame *videoFrame = (self.videoFrames)[i];
                NSString *storedStreamID = [[NSUserDefaults standardUserDefaults] objectForKey:kShelbySPCurrentVideoStreamID];
                
                if ( [videoFrame.frameID isEqualToString:storedStreamID] ) {
                    
                    self.model.currentVideo = i;
                    self.model.currentVideoPlayer = (self.videoPlayers)[_model.currentVideo];
                    
                }
            }
        }
        
        [self currentVideoDidChangeToVideo:_model.currentVideo];
    }
}

- (void)setupVideoListScrollView
{
    CGFloat itemViewWidth = [SPVideoItemView width];
    CGFloat itemViewHeight = [SPVideoItemView height];
    self.overlayView.videoListScrollView.contentSize = CGSizeMake(itemViewWidth*_model.numberOfVideos, itemViewHeight);
    self.overlayView.videoListScrollView.delegate = self;
    
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_group_async(group, queue, ^{
        
        for ( NSUInteger i = 0; i < _model.numberOfVideos; ++i ) {
            
            NSManagedObjectContext *context = [self.appDelegate context];
            NSManagedObjectID *objectID = [(self.videoFrames)[i] objectID];
            if (!objectID) {
                return;
            }
            Frame *videoFrame = (Frame *)[context existingObjectWithID:objectID error:nil];
            if (!videoFrame) {
                return;
            }
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SPVideoItemView" owner:self options:nil];
            if (![nib isKindOfClass:[NSArray class]] || [nib count] == 0 || ![nib[0] isKindOfClass:[UIView class]]) {
                return;
            }

            SPVideoItemView *itemView = nib[0];
            [itemView setTag:i];
        
            CGRect itemFrame = itemView.frame;
            itemFrame.origin.x = itemViewWidth * i;
            itemFrame.origin.y = 0.0f;
            [itemView setFrame:itemFrame];
            
            [AsynchronousFreeloader loadImageFromLink:videoFrame.video.thumbnailURL
                                         forImageView:itemView.thumbnailImageView
                                      withPlaceholder:[UIImage imageNamed:@"videoListThumbnail"]
                                       andContentMode:UIViewContentModeCenter];
        
            dispatch_async(dispatch_get_main_queue(), ^{
                
                NSManagedObjectContext *context = [self.appDelegate context];
                NSManagedObjectID *objectID = [(self.videoFrames)[i] objectID];
                if (!objectID) {
                    return;
                }
                Frame *mainQueuevideoFrame = (Frame *)[context existingObjectWithID:objectID error:nil];
                if (!mainQueuevideoFrame) {
                    return;
                }
                
                [itemView.videoTitleLabel setText:mainQueuevideoFrame.video.title];
                [itemView.videoSharerLabel setText:mainQueuevideoFrame.creator.nickname];
                [self.itemViews addObject:itemView];
                [self.overlayView.videoListScrollView addSubview:itemView];
            
                if ( i == _model.currentVideo ) {
                    itemView.backgroundColor = kShelbyColorGreen;
                    itemView.videoTitleLabel.textColor = kShelbyColorBlack;
                    itemView.videoSharerLabel.textColor = kShelbyColorBlack;
                    [self.overlayView.videoListScrollView setContentOffset:CGPointMake(i * 1024.0f, 0.0f)];
                }
                
            });
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{

            // Add visual selected state (e.g., green background) to currentVideo's itemView object
            
            if ( _model.currentVideo ) {
                
                SPVideoItemView *itemView = (self.itemViews)[_model.currentVideo];
                
                // Scroll To currentVideo if self.currentVideo != 0
                if ( 0 != self.model.currentVideo) {
                    
                    CGFloat x = _videoScrollView.frame.size.width * _model.currentVideo;
                    CGFloat y = _videoScrollView.contentOffset.y;
                    [self.videoScrollView setContentOffset:CGPointMake(x, y) animated:YES];
                    
                    CGFloat itemViewX = itemView.frame.size.width * (_model.currentVideo-1);
                    CGFloat itemViewY = _overlayView.videoListScrollView.contentOffset.y;
                    [self.overlayView.videoListScrollView setContentOffset:CGPointMake(itemViewX, itemViewY) animated:YES];
                    
                }
                
                [self.model.overlayView.videoListScrollView flashScrollIndicators];
            }
                    
        });
    });
}

- (void)setupAirPlay
{
    // Instantiate AirPlay button for MPVolumeView
    MPVolumeView *volumeView = [[MPVolumeView alloc] initWithFrame:_overlayView.airPlayView.bounds];
    [volumeView setShowsVolumeSlider:NO];
    [volumeView setShowsRouteButton:YES];
    [self.overlayView.airPlayView addSubview:volumeView];
    
    for (UIView *view in volumeView.subviews) {
        
        if ( [view isKindOfClass:[UIButton class]] ) {
            
            self.airPlayButton = (UIButton *)view;
            
        }
    }
}

- (void)setupGestures
{
    // Setup gestrues only onces - Toggle Overlay Gesture
    if (![[self.view gestureRecognizers] containsObject:self.toggleOverlayGesuture]) {
        _toggleOverlayGesuture = [[UITapGestureRecognizer alloc] initWithTarget:_overlayView action:@selector(toggleOverlay)];
        [self.toggleOverlayGesuture setNumberOfTapsRequired:1];
        [self.toggleOverlayGesuture setDelegate:self];
        [self.toggleOverlayGesuture requireGestureRecognizerToFail:self.overlayView.scrubberGesture];
        [self.view addGestureRecognizer:self.toggleOverlayGesuture];

        // Playlist Gestures
        UISwipeGestureRecognizer *upGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(togglePlaylist:)];
        upGesture.direction = UISwipeGestureRecognizerDirectionUp;
        [self.view addGestureRecognizer:upGesture];
        
        UISwipeGestureRecognizer *downGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(togglePlaylist:)];
        downGesture.direction = UISwipeGestureRecognizerDirectionDown;
        [self.view addGestureRecognizer:downGesture];

    }
}

- (void)setupOverlayVisibileItems
{
    if ([self.model numberOfVideos]) {
        [self.overlayView showVideoAndChannelInfo];
    } else {
        [self.overlayView hideVideoAndChannelInfo];
    }
}

#pragma mark - Storage Methods (Public)
- (void)storeLoadedVideoPlayer:(SPVideoPlayer *)player
{
    if ( ![self playableVideoPlayers] ) {
        self.playableVideoPlayers = [@[] mutableCopy];
    }
    
    // Add newly loaded SPVideoPlayer to list of SPVideoPlayers
    [self.playableVideoPlayers addObject:player];
    
    // If screen is retina (e.g., iPad 3 or greater), allow 3 videos. Otherwise, allow only 3 videos to be stored
    NSUInteger maxVideosAllowed;
    if ([[UIScreen mainScreen] isRetinaDisplay]) {
        maxVideosAllowed = 3;
    } else if (![DeviceUtilities isIpadMini1]) {
        maxVideosAllowed = 2;
    } else {
        maxVideosAllowed = 1;
    }
    
    if ( [self.playableVideoPlayers count] > maxVideosAllowed ) { // If more than X number of videos are loaded, unload the older videos in the list
        
        SPVideoPlayer *oldestPlayer = (SPVideoPlayer *)(self.playableVideoPlayers)[0];
        
        if ( oldestPlayer != _model.currentVideoPlayer ) { // If oldestPlayer isn't currently being played, remove it
            
            [oldestPlayer resetPlayer];
            [self.playableVideoPlayers removeObject:oldestPlayer];
            
        } else { // If oldestPlayer is being played, remove next-oldest video
            
            if ( [self.playableVideoPlayers count] > 1) {
                
                SPVideoPlayer *nextOldestPlayer = (SPVideoPlayer *)(self.playableVideoPlayers)[1];
                [nextOldestPlayer resetPlayer];
                [self.playableVideoPlayers removeObject:nextOldestPlayer];

            }
        }
    }
}


#pragma mark - Update Methods (Public)
- (void)extractVideoForVideoPlayer:(NSUInteger)position
{
    SPVideoPlayer *player = (self.videoPlayers)[position];
    
    NSManagedObjectContext *context = [self.appDelegate context];
    NSManagedObjectID *objectID = [player.videoFrame objectID];
    if (!objectID) {
        return;
    }
    
    Frame *videoFrame = (Frame *)[context existingObjectWithID:objectID error:nil];
    if (!videoFrame) {
        return;
    }
    if ( position < _model.numberOfVideos ) {
        
        if ([videoFrame.video offlineURL] && [[videoFrame.video offlineURL] length] > 0 ) { // Load player from disk if video was previously downloaded
            
            [player loadVideoFromDisk];
            
        } else { // Queue video for mp4 extraction
            
            [player queueVideo];
            
        }
    
    } else {
    
        // Do nothing
    
    }
}

- (void)currentVideoDidFinishPlayback
{
    NSUInteger position = _model.currentVideo + 1;
    CGFloat x = position * kShelbySPVideoWidth;
    CGFloat y = _videoScrollView.contentOffset.y;
    
    if ( position <= (_model.numberOfVideos-1) ) {
    
        [self.videoScrollView setContentOffset:CGPointMake(x, y) animated:YES];
        [self currentVideoDidChangeToVideo:position];
    
    }
}

- (IBAction)playButtonAction:(id)sender
{
    [self.model.currentVideoPlayer togglePlayback:self];
}

- (IBAction)shareButtonAction:(id)sender
{
    // Disable overlayTimer
    [self.model.overlayView showOverlayView];
    [self.model.overlayTimer invalidate];
    
    [self.model.currentVideoPlayer share];
}

- (IBAction)likeAction:(id)sender
{
    NSManagedObjectContext *context = [self.appDelegate context];
    NSManagedObjectID *objectID = [self.model.currentVideoPlayer.videoFrame objectID];
    if (!objectID) {
        return;
    }
    
    Frame *frame = (Frame *)[context existingObjectWithID:objectID error:nil];
    if (!frame) {
        return;
    }
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kShelbyDefaultUserAuthorized]) {
        [ShelbyAPIClient postFrameToLikes:frame.frameID];
    } else { // Logged Out
        CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_StoreLoggedOutLike];
        [ShelbyAPIClient postFrameToLikes:frame.frameID];
        [dataUtility storeFrameInLoggedOutLikes:frame];
    }
    
    SPModel *model = (SPModel *)[SPModel sharedInstance];
    [model.overlayView showOverlayView];
    [model.overlayView showLikeNotificationView];
    [NSTimer scheduledTimerWithTimeInterval:5.0f
                                     target:model.overlayView
                                   selector:@selector(hideLikeNotificationView)
                                   userInfo:nil
                                    repeats:NO];
}

- (IBAction)rollAction:(id)sender
{
    if (![[NSUserDefaults standardUserDefaults] boolForKey:kShelbyDefaultUserAuthorized]) {
 
        // Setting invocation, so we would roll immediately after user logs in.
        NSMethodSignature *rollSignature = [SPVideoReel instanceMethodSignatureForSelector:@selector(rollVideo)];
        NSInvocation *rollInvocation = [NSInvocation invocationWithMethodSignature:rollSignature];
        [rollInvocation setTarget:self];
        [rollInvocation setSelector:@selector(rollVideo)];
        [self setInvocationMethod:rollInvocation];
        
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"You need to be logged in to roll" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Login", nil];
        [alertView show];
    } else {
        [self rollVideo];
    }
}

- (void)rollVideo
{
    // Disable overlayTimer
    [self.model.overlayView showOverlayView];
    [self.model.overlayTimer invalidate];
    
    [self.model.currentVideoPlayer roll];    
}

- (IBAction)itemButtonAction:(id)sender
{
    // Send event to Google Analytics
    id defaultTracker = [GAI sharedInstance].defaultTracker;
    [defaultTracker sendEventWithCategory:kGAICategoryVideoList
                               withAction:@"Video selected via video list item press"
                                withLabel:_groupTitle
                                withValue:nil];
    
    // Pause currentVideo Player
    [self.model.currentVideoPlayer pause];
    
    // Reference SPVideoItemView from position in videoListScrollView object
    SPVideoItemView *itemView = (SPVideoItemView *)[sender superview];
    NSUInteger position = itemView.tag;
    
    // Force scroll videoScrollView
    CGFloat videoX = kShelbySPVideoWidth * position;
    CGFloat videoY = _videoScrollView.contentOffset.y;
    
    if ( position < _model.numberOfVideos ) {
        [self.videoScrollView setContentOffset:CGPointMake(videoX, videoY) animated:YES];
    }
    
    // Perform actions on videoChange
    [self currentVideoDidChangeToVideo:position];
    
}

- (void)restartPlaybackButtonAction:(id)sender
{
    // Send event to Google Analytics
    id defaultTracker = [GAI sharedInstance].defaultTracker;
    [defaultTracker sendEventWithCategory:kGAICategoryVideoPlayer
                               withAction:@"Playback toggled via restart button"
                                withLabel:_groupTitle
                                withValue:nil];
    
    [self.model.currentVideoPlayer restartPlayback];
}

//- (IBAction)beginScrubbing:(id)sender
//{
//	[[SPVideoScrubber sharedInstance] beginScrubbing];
//}
//
//- (IBAction)scrub:(id)sender
//{
//    [[SPVideoScrubber sharedInstance] scrub];
//}
//
//- (IBAction)endScrubbing:(id)sender
//{
//    [[SPVideoScrubber sharedInstance] endScrubbing];
//}

#pragma mark - Storage Methods (Private)
- (void)storeIdentifierOfCurrentVideoInStream
{
    NSManagedObjectContext *context = [self.appDelegate context];
    NSManagedObjectID *objectID = [(self.videoFrames)[_model.currentVideo] objectID];
    if (!objectID) {
        return;
    }

    Frame *videoFrame = (Frame *)[context existingObjectWithID:objectID error:nil];
    if (!videoFrame) {
        return;
    }
    [[NSUserDefaults standardUserDefaults] setObject:videoFrame.frameID forKey:kShelbySPCurrentVideoStreamID];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


#pragma mark -  Update Methods (Private)
- (void)currentVideoDidChangeToVideo:(NSUInteger)position
{
    
    // Post notification (to rollViews that may have a keyboard loaded in view)
    [[NSNotificationCenter defaultCenter] postNotificationName:kShelbySPUserDidSwipeToNextVideo object:nil];
    
    // Disable timer
    [self.model.overlayTimer invalidate];
    
    // Show Overlay
    [self.overlayView showOverlayView];
    
    // Pause current videoPlayer
    [self.model.currentVideoPlayer pause];
    
    // Stop observing video for videoScrubber
    [[SPVideoScrubber sharedInstance] stopObserving];

    // Reset currentVideoPlayer reference after scrolling has finished
    self.model.currentVideo = position;
    self.model.currentVideoPlayer = (self.videoPlayers)[position];
    
    // If videoReel is instance of Stream, store currentVideoID
    if ( _groupType == GroupType_Stream ) {
        
        [self storeIdentifierOfCurrentVideoInStream];
        
    }
    
    // Deal with playback methods & UI of current and previous video
    [self updatePlaybackUI];
    
    // Clear old values on infoCard
    [self.overlayView.videoTitleLabel setText:nil];
    [self.overlayView.videoCaptionLabel setText:nil];
    [self.overlayView.nicknameLabel setText:nil];
    [self.overlayView.userImageView setImage:nil];
    
    // Reference NSManageObjectContext
    NSManagedObjectContext *context = [self.appDelegate context];
    NSManagedObjectID *objectID = [(self.videoFrames)[_model.currentVideo] objectID];
    if (!objectID) {
        return;
    }

    Frame *videoFrame = (Frame *)[context existingObjectWithID:objectID error:nil];
    if (!videoFrame) {
        return;
    }
    // Set new values on infoPanel
    self.overlayView.videoTitleLabel.text = videoFrame.video.title;
    
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    self.overlayView.videoCaptionLabel.text = [dataUtility fetchTextFromFirstMessageInConversation:videoFrame.conversation];
    self.overlayView.nicknameLabel.text = [NSString stringWithFormat:@"Shared by %@", videoFrame.creator.nickname];
    [AsynchronousFreeloader loadImageFromLink:videoFrame.creator.userImage
                                 forImageView:_overlayView.userImageView
                          withPlaceholder:[UIImage imageNamed:@"infoPanelIconPlaceholder"]
                               andContentMode:UIViewContentModeScaleAspectFit];
    
    // Update videoListScrollView (if _itemViews is initialized)
    if ( 0 < [self.itemViews count] ) {
        
        // Remove selected state color from all SPVideoItemView objects
        for (SPVideoItemView *itemView in self.itemViews) {
            itemView.backgroundColor = kShelbyColorWhite;
            itemView.videoTitleLabel.textColor = kShelbyColorBlack;
            itemView.videoSharerLabel.textColor = kShelbyColorBlack;
        }
        
        // Update currentVideo's SPVideoItemView object UI and position in videoListScrollView object
        SPVideoItemView *itemView = (self.itemViews)[position];
        itemView.backgroundColor = kShelbyColorGreen;
        itemView.videoTitleLabel.textColor = kShelbyColorBlack;
        itemView.videoSharerLabel.textColor = kShelbyColorBlack;
        if ( position < _model.numberOfVideos-1 ) {
            CGFloat itemX = itemView.frame.size.width * position;
            CGFloat itemY = 0.0f;
            [self.overlayView.videoListScrollView setContentOffset:CGPointMake(itemX, itemY) animated:YES];
        }
        
    }
    
    // Queue current and next 3 videos
    [self queueMoreVideos:position];
    
}

- (void)updatePlaybackUI
{    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self.overlayView.elapsedProgressView setProgress:0.0f];
        [self.overlayView.bufferProgressView setProgress:0.0f];
        [self.overlayView.elapsedTimeLabel setText:@""];
        [self.overlayView.totalDurationLabel setText:@""];
        
        if ( [self.model.currentVideoPlayer isPlayable] ) { // Video IS Playable
            
            [self.model.currentVideoPlayer play];
            
            if ( [self.model.currentVideoPlayer playbackFinished] ) { // Playable video DID finish playing
                
                [self.overlayView.restartPlaybackButton setHidden:NO];
                
            } else { // Playable video DID NOT finish playing
                
                [self.overlayView.restartPlaybackButton setHidden:YES];
                
            }
            
        } else { // Video IS NOT Playable
            
            [self.overlayView.restartPlaybackButton setHidden:YES];
            
        }
        
    });

}

- (void)queueMoreVideos:(NSUInteger)position
{
    if ( [self.videoPlayers count] ) {
        // For all iPads
        [[SPVideoExtractor sharedInstance] cancelRemainingExtractions];
        [self extractVideoForVideoPlayer:position]; // Load video for current visible view
        if (position + 1 < self.model.numberOfVideos) {
            [self extractVideoForVideoPlayer:position+1];
        }
        
        // iPad 3 or better (e.g., device with more RAM and better processor)
        if ([[UIScreen mainScreen] isRetinaDisplay]) {
            if (position + 2 < self.model.numberOfVideos) {
                [self extractVideoForVideoPlayer:position+2];
            }
        } 
    }
}

- (void)fetchOlderVideos:(NSUInteger)position
{
    
    if ( [self.moreVideoFrames count] ) { // Load older videos from Database
        
        [self dataSourceShouldUpdateFromLocalArray];
        
    } else { // Get older videos from Web
    
        if ( position >= _model.numberOfVideos - 7 && ![self fetchingOlderVideos] ) {
            
            self.fetchingOlderVideos = YES;
            
            CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
            
            switch ( _groupType ) {
                    
                case GroupType_Stream: {
                    
                    NSUInteger totalNumberOfVideosInDatabase = [dataUtility fetchStreamCount];
                    NSString *numberToString = [NSString stringWithFormat:@"%d", totalNumberOfVideosInDatabase];
                    [ShelbyAPIClient getMoreFramesInStream:numberToString];
                    
                } break;
                    
                case GroupType_Likes: {
                    
                    NSUInteger totalNumberOfVideosInDatabase = [dataUtility fetchLikesCount];
                    NSString *numberToString = [NSString stringWithFormat:@"%d", totalNumberOfVideosInDatabase];
                    [ShelbyAPIClient getMoreFramesInLikes:numberToString];
                    
                } break;
                    
                case GroupType_PersonalRoll: {
                    
                    NSUInteger totalNumberOfVideosInDatabase = [dataUtility fetchPersonalRollCount];
                    NSString *numberToString = [NSString stringWithFormat:@"%d", totalNumberOfVideosInDatabase];
                    [ShelbyAPIClient getMoreFramesInPersonalRoll:numberToString];
                    
                } break;
                    
                case GroupType_CategoryChannel: {
                    
                    NSUInteger totalNumberOfVideosInDatabase = [dataUtility fetchCountForCategoryChannel:_categoryID];
                    NSString *numberToString = [NSString stringWithFormat:@"%d", totalNumberOfVideosInDatabase];
                    [ShelbyAPIClient getMoreFrames:numberToString forCategoryChannel:_categoryID];

                } break;
                    
                case GroupType_CategoryRoll: {
                    
                    NSUInteger totalNumberOfVideosInDatabase = [dataUtility fetchCountForCategoryRoll:_categoryID];
                    NSString *numberToString = [NSString stringWithFormat:@"%d", totalNumberOfVideosInDatabase];
                    [ShelbyAPIClient getMoreFrames:numberToString forCategoryRoll:_categoryID];
                    
                    
                } break;
            }
        }
    }
}

- (void)dataSourceShouldUpdateFromLocalArray
{
    
    if ( [self.moreVideoFrames count] > 20 ) { // If there are more than 20 frames in videoFrames
        
        NSArray *tempMoreVideoFrames = [NSArray arrayWithArray:_moreVideoFrames];
        
        for ( NSUInteger i = 0; i<20; i++ ) {
            
            [self.videoFrames addObject:[tempMoreVideoFrames objectAtIndex:i]];
            [self.moreVideoFrames removeObjectAtIndex:0];
            
        }
        
    } else { // If there are <= 20 frames in videoFrames
        
        [self.videoFrames addObjectsFromArray:_moreVideoFrames];
        [self.moreVideoFrames removeAllObjects];
        
    }

    [self dataSourceDidUpdate];
    
}

- (void)dataSourceShouldUpdateFromWeb:(NSNotification *)notification
{
    
    if ( [self fetchingOlderVideos] && ![self loadingOlderVideos] ) {
    
        [self setLoadingOlderVideos:YES];
        
        NSManagedObjectContext *context = [self.appDelegate context];
        NSManagedObjectID *lastFramedObjectID = [[self.videoFrames lastObject] objectID];
        if (!lastFramedObjectID) {
            return;
        }
        Frame *lastFrame = (Frame *)[context existingObjectWithID:lastFramedObjectID error:nil];
        if (!lastFrame) {
            return;
        }
        NSDate *date = lastFrame.timestamp;
    
        CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
        NSMutableArray *olderFramesArray = [@[] mutableCopy];
        
        switch ( _groupType ) {
                
            case GroupType_Likes:{
                [olderFramesArray addObjectsFromArray:[dataUtility fetchMoreLikesEntriesAfterDate:date]];
            } break;
                
            case GroupType_PersonalRoll:{
                [olderFramesArray addObjectsFromArray:[dataUtility fetchMorePersonalRollEntriesAfterDate:date]];
            } break;
        
            case GroupType_Stream:{
                [olderFramesArray addObjectsFromArray:[dataUtility fetchMoreStreamEntriesAfterDate:date]];
            } break;
                
            case GroupType_CategoryChannel:{
                [olderFramesArray addObjectsFromArray:[dataUtility fetchMoreFramesInCategoryChannel:_categoryID afterDate:date]];
            } break;
                
            case GroupType_CategoryRoll:{
                [olderFramesArray addObjectsFromArray:[dataUtility fetchMoreFramesInCategoryRoll:_categoryID afterDate:date]];
            } break;
                
        }
        
        // Compare last video from _videoFrames against first result of olderFramesArrays, and deduplicate if necessary
        if ( [olderFramesArray count] ) {

            Frame *firstFrame = (Frame *)olderFramesArray[0];
            NSManagedObjectID *firstFrameObjectID = [firstFrame objectID];
            if (!firstFrameObjectID) {
                return;
            }

            firstFrame = (Frame *)[context existingObjectWithID:firstFrameObjectID error:nil];
            if (!firstFrame) {
                return;
            }
            if ( [firstFrame.videoID isEqualToString:lastFrame.videoID] ) {
                [olderFramesArray removeObject:firstFrame];
            }
            
            // Add deduplicated frames from olderFramesArray to videoFrames
            [self.videoFrames addObjectsFromArray:olderFramesArray];
            
            [self dataSourceDidUpdate];
            
        } else {
            
            /*
             
             No older videos fetched.
             Don't rest flags to avoid unncessary API calls, since they'll return no older frames.
             
             */
        }
    }
}

- (void)dataSourceDidUpdate
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // Update variables
        NSUInteger numberOfVideosBeforeUpdate = [self.model numberOfVideos];
        self.model.numberOfVideos = [self.videoFrames count];
        
        // Update videoScrollView and videoListScrollView
        for ( NSUInteger i = numberOfVideosBeforeUpdate; i < _model.numberOfVideos; ++i ) {

            if ( [self.videoFrames count] >= i ) {
                
                // videoScrollView
                NSManagedObjectContext *context = [self.appDelegate context];
                NSManagedObjectID *objectID = [(self.videoFrames)[i] objectID];
                if (!objectID) {
                    continue;
                }
                Frame *videoFrame = (Frame *)[context existingObjectWithID:objectID error:nil];
                if (!videoFrame) {
                    return;
                }
                CGRect viewframe = [self.videoScrollView frame];
                viewframe.origin.x = viewframe.size.width * i;
                SPVideoPlayer *player = [[SPVideoPlayer alloc] initWithBounds:viewframe withVideoFrame:videoFrame];
                
                // videoListScrollView
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SPVideoItemView" owner:self options:nil];
                if (![nib isKindOfClass:[NSArray class]] || [nib count] == 0 || ![nib[0] isKindOfClass:[UIView class]]) {
                    return;
                }
                
                SPVideoItemView *itemView = nib[0];
                if (![itemView isKindOfClass:[UIView class]]) {
                    return;
                }
                
                CGFloat itemViewWidth = [SPVideoItemView width];
                CGFloat itemViewHeight = [SPVideoItemView height];
                CGRect itemFrame = itemView.frame;
                itemFrame.origin.x = itemViewWidth * i;
                [itemView setFrame:itemFrame];
                [itemView setTag:i];
                
                [AsynchronousFreeloader loadImageFromLink:videoFrame.video.thumbnailURL
                                             forImageView:itemView.thumbnailImageView
                                          withPlaceholder:[UIImage imageNamed:@"videoListThumbnail"]
                                           andContentMode:UIViewContentModeCenter];
                
                // Update UI on Main Thread
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    // Reference _videoFrames[i] on main thread
                    NSManagedObjectContext *context = [self.appDelegate context];
                    if (!self.videoFrames || [self.videoFrames count] <= i) {
                        return;
                    }
                    NSManagedObjectID *objectID = [(self.videoFrames)[i] objectID];
                    if (!objectID) {
                        return ;
                    }
                    Frame *mainQueuevideoFrame = (Frame *)[context existingObjectWithID:objectID error:nil];
                    if (!mainQueuevideoFrame) {
                        return;
                    }
                    // Update scrollViews
                    self.videoScrollView.contentSize = CGSizeMake(kShelbySPVideoWidth * (i + 1), kShelbySPVideoHeight);
                    [self.videoPlayers addObject:player];
                    [self.videoScrollView addSubview:player.view];
                    [self.videoScrollView setNeedsDisplay];
                    
                    // Update itemViews
                    itemView.backgroundColor = kShelbyColorWhite;
                    itemView.videoTitleLabel.textColor = kShelbyColorBlack;
                    itemView.videoSharerLabel.textColor = kShelbyColorBlack;
                    [itemView.videoTitleLabel setText:mainQueuevideoFrame.video.title];
                    [itemView.videoSharerLabel setText:mainQueuevideoFrame.creator.nickname];
                    self.overlayView.videoListScrollView.contentSize = CGSizeMake(itemViewWidth*(i+1), itemViewHeight);
                    [self.itemViews addObject:itemView];
                    [self.overlayView.videoListScrollView addSubview:itemView];
                    [self.overlayView.videoListScrollView setNeedsDisplay];
                    
                    // Set flags
                    [self setFetchingOlderVideos:NO];
                    [self setLoadingOlderVideos:NO];
                });
                
            }
            
        }
    });
}

- (void)scrollToNextVideoAfterUnplayableVideo:(NSNotification *)notification
{
    
    // Position after unloadable video (e.g., next video's position)
    NSUInteger position = _model.currentVideo + 1;

    if ( position < _model.numberOfVideos ) { // If next video isn't the last loaded video
        NSString *skippedVideoID = [notification object];
        if (![skippedVideoID isKindOfClass:[NSString class]]) {
            skippedVideoID = nil;
        }
        
        NSManagedObjectContext *context = [self.appDelegate context];
        NSManagedObjectID *currentVideoFrameObjectID = [self.model.currentVideoPlayer.videoFrame objectID];
        Frame *currentVideoFrame = (Frame *)[context existingObjectWithID:currentVideoFrameObjectID error:nil];
        if (!currentVideoFrame) {
            return;
        }
        NSString *currentVideoID = [currentVideoFrame videoID];
        if (![self.model.currentVideoPlayer isPlayable] && [skippedVideoID isEqualToString:currentVideoID]) { // Load AND scroll to next video if current video is in focus
            CGFloat videoX = kShelbySPVideoWidth * position;
            CGFloat videoY = _videoScrollView.contentOffset.y;
            [self.videoScrollView setContentOffset:CGPointMake(videoX, videoY) animated:YES];
            [self currentVideoDidChangeToVideo:position];
        } else { // Load next video, (but do not scroll)
            [self extractVideoForVideoPlayer:position];
        }
    }
}

- (void)purgeVideoPlayerInformationFromPreviousVideoGroup
{
    // Cancel remaining MP4 extractions
    [[SPVideoExtractor sharedInstance] cancelRemainingExtractions];
    
    // Remove Scrubber Timer and Observer
    [[SPVideoScrubber sharedInstance] stopObserving];
    
    // Remove references on model
    [self.model destroyModel];
    
    // Stop residual audio playback (this shouldn't be happening to begin with)
    [self.videoPlayers makeObjectsPerformSelector:@selector(pause)];
    [self.videoPlayers removeAllObjects];
    self.videoPlayers = nil;
    
    [self.playableVideoPlayers makeObjectsPerformSelector:@selector(pause)];
    [self.playableVideoPlayers removeAllObjects];
    self.playableVideoPlayers = nil;
    
    [[self.videoScrollView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
//    [self.videoScrollView removeFromSuperview];
//    self.videoScrollView = nil;
    
    [[self.overlayView.videoListScrollView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
//    [self.overlayView.videoListScrollView removeFromSuperview];
//    self.overlayView.videoListScrollView = nil;
    
    [self.itemViews removeAllObjects];
    self.itemViews = nil;
    
    // Instantiate dataUtility for cleanup
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    
    // Remove older videos (categoryID will be nil for stream, likes, and personal roll)
    [dataUtility removeOlderVideoFramesForGroupType:_groupType andCategoryID:_categoryID];
    
    // All video.extractedURL references are temporary (session-dependent), so they should be removed when the app shuts down.
    [dataUtility removeAllVideoExtractionURLReferences];
}

#pragma mark - Gesture Methods (Private)
- (void)togglePlaylist:(UISwipeGestureRecognizer *)gesture
{
    [self.overlayView togglePlaylist:gesture];
}

#pragma mark - UIScrollViewDelegate Methods
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if ( scrollView == _model.overlayView.videoListScrollView ) {
        
        [scrollView flashScrollIndicators];
        
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    
    // Switch the indicator when more than 50% of the previous/next page is visible
    CGFloat pageWidth = scrollView.frame.size.width;
    NSString *gaAction = nil;
    NSString *gaEventCategory = nil;
    
    if (scrollView == _videoScrollView) {
        CGFloat scrollAmount = (scrollView.contentOffset.x - pageWidth / 2) / pageWidth;
        NSUInteger page = floor(scrollAmount) + 1;
        
        // Toggle playback on old and new SPVideoPlayer objects
        if ( page != _model.currentVideo ) {
            [self.videoPlayers makeObjectsPerformSelector:@selector(pause)];
        } else {
            return;
        }
        
        [self currentVideoDidChangeToVideo:page];
        [self fetchOlderVideos:page];
        
        gaAction = @"Swiped video player";
        gaEventCategory = kGAICategoryVideoPlayer;
    } else if (scrollView == _overlayView.videoListScrollView) {
        CGFloat scrollAmount = 5*(scrollView.contentOffset.x - pageWidth / 2) / pageWidth; // Multiply by ~3 since each visible section has ~3 videos.
        NSUInteger page = floor(scrollAmount) + 1;
        [self fetchOlderVideos:page];
        
        gaAction = @"Swiped video list";
        gaEventCategory = kGAICategoryVideoList;

        [self.overlayView rescheduleOverlayTimer];
    }
    
    // Send event to Google Analytics
    id defaultTracker = [GAI sharedInstance].defaultTracker;
    [defaultTracker sendEventWithCategory:gaEventCategory
                               withAction:gaAction
                                withLabel:_groupTitle
                                withValue:nil];
    
}

- (void)launchUserGroup:(NSUInteger)groupNumber
{
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];

    if (groupNumber == 0 || groupNumber == 2) {
        if (![[NSUserDefaults standardUserDefaults] boolForKey:kShelbyDefaultUserAuthorized]) { 
            NSMethodSignature *streamSignature = [SPVideoReel instanceMethodSignatureForSelector:@selector(launchUserGroup:)];
            NSInvocation *streamInvocation = [NSInvocation invocationWithMethodSignature:streamSignature];
            [streamInvocation setTarget:self];
            [streamInvocation setArgument:&groupNumber atIndex:2];
            [streamInvocation setSelector:@selector(launchUserGroup:)];
            [self setInvocationMethod:streamInvocation];
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"You need to be logged in to access these videos." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Login", nil];
            [alertView show];
            return;
        }
    }
    
    switch (groupNumber) {
        case 0:
        { // Stream
            [self launchStream];
            
            break;
        }
        case 1:
        { // Likes
            NSUInteger likesCount = [dataUtility fetchLikesCount];
            if ( 0 == likesCount ) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"You have no likes." delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
                [alertView show];
                return;
            } else {
                [self launchLikes];
            }

            break;
        }
        case 2:
        { // Personal Roll
            [self launchPersonalRoll];
            break;
        }
        default:
            break;
    }

    [self.overlayView.categoriesCollectionView reloadData];
}

- (void)launchCategory:(id)category
{
    if ([category isKindOfClass:[NSManagedObject class]]) {
        NSManagedObjectContext *context = [self.appDelegate context];
        NSManagedObjectID *objectID = [category objectID];
        CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
        if ([category isMemberOfClass:[Channel class]]) {
            Channel *channel = (Channel *)[context existingObjectWithID:objectID error:nil];
            if (!channel) {
                return;
            }
            NSMutableArray *videoFrames = [dataUtility fetchFramesInCategoryChannel:[channel channelID]];
            [self loadWithGroupType:GroupType_CategoryChannel groupTitle:[channel displayTitle] videoFrames:videoFrames andCategoryID:[channel channelID]];
        } else if ([category isMemberOfClass:[Roll class]]) {
            Roll *roll = (Roll *)[context existingObjectWithID:objectID error:nil];
            if (!roll) {
                return;
            }
            NSMutableArray *videoFrames = [dataUtility fetchFramesInCategoryChannel:[roll rollID]];
            [self loadWithGroupType:GroupType_CategoryRoll groupTitle:[roll title] videoFrames:videoFrames andCategoryID:[roll rollID]];
        }
    }
    
    [self.overlayView.categoriesCollectionView reloadData];
}

- (void)launchStream
{
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    NSMutableArray *videoFrames = [dataUtility fetchStreamEntries];
    [self loadWithGroupType:GroupType_Stream groupTitle:@"Stream" andVideoFrames:videoFrames];
    [self.overlayView.categoriesCollectionView reloadData];
}

- (void)launchLikes
{
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    NSMutableArray *videoFrames = [dataUtility fetchLikesEntries];
    [self loadWithGroupType:GroupType_Likes groupTitle:@"Likes" andVideoFrames:videoFrames];
    [self.overlayView.categoriesCollectionView reloadData];
}

- (void)launchPersonalRoll
{
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    NSMutableArray *videoFrames = [dataUtility fetchPersonalRollEntries];
    NSString *title = nil;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kShelbyDefaultUserAuthorized]) {
        title = [NSString stringWithFormat:@"%@.shelby.tv", self.userNickname];
    } else {
        title = @"Your .TV";
    }
    
    [self loadWithGroupType:GroupType_PersonalRoll groupTitle:title andVideoFrames:videoFrames];
    [self.overlayView.categoriesCollectionView reloadData];
}

#pragma mark - UIAlertViewDelegate Methods
- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        [self loginAction];
    } else {
        [self setInvocationMethod:nil];
    }
}

// TODO: this might go to a different VC.
#pragma mark - Authorization Methods (Private)
- (void)loginAction
{
    [self.model.currentVideoPlayer pause];
    
    AuthorizationViewController *authorizationViewController = [[AuthorizationViewController alloc] initWithNibName:@"AuthorizationView" bundle:nil];
    
    CGFloat xOrigin = self.view.frame.size.width / 2.0f - authorizationViewController.view.frame.size.width / 4.0f;
    CGFloat yOrigin = self.view.frame.size.height / 5.0f - authorizationViewController.view.frame.size.height / 4.0f;
    CGSize loginDialogSize = authorizationViewController.view.frame.size;
    [authorizationViewController setDelegate:self];
    [authorizationViewController setModalInPopover:YES];
    [authorizationViewController setModalPresentationStyle:UIModalPresentationFormSheet];
    
    [self presentViewController:authorizationViewController animated:YES completion:nil];
    
    authorizationViewController.view.superview.frame = CGRectMake(xOrigin, yOrigin, loginDialogSize.width, loginDialogSize.height);
}

#pragma  mark - AuthorizationDelegate
- (void)authorizationDidComplete
{
    [self.invocationMethod invoke];
    [self setInvocationMethod:nil];
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kShelbyDefaultUserAuthorized];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    User *user = [dataUtility fetchUser];
    BOOL isAdmin = [user admin];
    
    if ( isAdmin ) {
        [self resetSecretVersionButton];
    }

    [self fetchUserNickname];
}

- (void)authorizationDidNotComplete
{
    [self setInvocationMethod:nil];
    [self.model.currentVideoPlayer play];
}


#pragma mark - Private Methods
- (NSManagedObjectContext *)context
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    return [appDelegate context];
}

- (void)fetchUserNickname
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kShelbyDefaultUserAuthorized]) {
        CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
        User *user = [dataUtility fetchUser];
        [self setUserNickname:[user nickname]];
    }
}

- (void)fetchAllCategories
{
    CoreDataUtility *datautility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    [self.categories removeAllObjects];
    [self.categories addObjectsFromArray:[datautility fetchAllCategories]];
    
    [self.overlayView.categoriesCollectionView reloadData];
    
}

#pragma mark - Secret Methods (Private)
- (void)resetSecretVersionButton
{
    [self.overlayView.versionButton setEnabled:YES];
    [self.overlayView.versionButton addTarget:self action:@selector(toggleSecretModes:) forControlEvents:UIControlEventTouchUpInside];
    [self setSecretMode:SecretMode_None];
    [self.overlayView.versionButton setTitle:[NSString stringWithFormat:@"Shelby.tv for iPad v%@", kShelbyCurrentVersion] forState:UIControlStateNormal];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kShelbyDefaultOfflineModeEnabled];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kShelbyDefaultOfflineViewModeEnabled];
    [[NSUserDefaults standardUserDefaults] synchronize];
    DLog(@"Offline+View Mode DISABLED!")
}

- (void)toggleSecretModes:(id)sender
{
    
    /*
     Each switch statement sets the conditions for the next SecretMode.
     
     Example:
     Entering SecretMode_None sets the condition for SecretMode_Offline.
     Entering SecretMode_Offline sets the condition for SecretMode_OfflineView.
     Entering SecretMode_OfflineView sets the condition for SecretMode_None.
     
     */
    
    if ( [[NSUserDefaults standardUserDefaults] boolForKey:kShelbyDefaultUserAuthorized] && [[NSUserDefaults standardUserDefaults] boolForKey:kShelbyDefaultUserIsAdmin] ) {
        
        switch ( _secretMode ) {
                
            case SecretMode_None: {
                
                [self setSecretMode:SecretMode_Offline];
                [self.overlayView.versionButton setTitle:[NSString stringWithFormat:@"Shelby.tv for iPad v%@-O", kShelbyCurrentVersion] forState:UIControlStateNormal];
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kShelbyDefaultOfflineModeEnabled];
                [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kShelbyDefaultOfflineViewModeEnabled];
                [[NSUserDefaults standardUserDefaults] synchronize];
                DLog(@"Offline Mode ENABLED!")
                
            } break;
                
            case SecretMode_Offline: {
                
                [self setSecretMode:SecretMode_OfflineView];
                [self.overlayView.versionButton setTitle:[NSString stringWithFormat:@"Shelby.tv for iPad v%@-OV", kShelbyCurrentVersion] forState:UIControlStateNormal];
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kShelbyDefaultOfflineModeEnabled];
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kShelbyDefaultOfflineViewModeEnabled];
                [[NSUserDefaults standardUserDefaults] synchronize];
                DLog(@"Offline+View Mode ENABLED!")
                
            } break;
                
            case SecretMode_OfflineView: {
                
                [self setSecretMode:SecretMode_None];
                [self.overlayView.versionButton setTitle:[NSString stringWithFormat:@"Shelby.tv for iPad v%@", kShelbyCurrentVersion] forState:UIControlStateNormal];
                [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kShelbyDefaultOfflineModeEnabled];
                [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kShelbyDefaultOfflineViewModeEnabled];
                [[NSUserDefaults standardUserDefaults] synchronize];
                DLog(@"Offline+View Mode DISABLED!")
                
            } break;
        }
    }
}

// TODO: factor the data source delegete methods to a model class.
#pragma mark - UICollectionView Datasource
- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section
{
    // KP KP TODO: remove once we have design for FB/Twitter
    if (section == 2) {
        return 2;
    }

    return (0 == section  ? 2 : [self.categories count]);
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView
{
#ifdef DEBUG    // KP KP TODO: remove once we have design for FB/Twitter
    return 3;  // Adding the FB/Twitter channels for now, in debug mode only.
#else
    return 2;
#endif
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    id cell =  nil;
    if (indexPath.section == 0 && indexPath.row == 1) {
        cell = (SPLikesCatgoryViewCell *)[cv dequeueReusableCellWithReuseIdentifier:@"SPLikesCatgoryViewCell" forIndexPath:indexPath];
    } else {
        cell = (SPCategoryViewCell *)[cv dequeueReusableCellWithReuseIdentifier:@"SPCategoryViewCell" forIndexPath:indexPath];
    }
    
    int row = indexPath.row;
    NSString *title = nil;
    
    // KP KP: TODO - remove once we have design for FB/Twitter
    if (indexPath.section == 2) {
        if (row == 0) {
            title = @"Facebook";
        } else {
            title = @"Twitter";
        }
    } else if (indexPath.section == 0) { // Me Cards
        if (row == 0) {
            title = @"Stream";
        } else if (row == 1) {
            title = @"Likes";
//        } else if (row == 2) {
//            if ([[NSUserDefaults standardUserDefaults] boolForKey:kShelbyDefaultUserAuthorized]) {
//                title = [NSString stringWithFormat:@"%@.shelby.tv", self.userNickname];
//            } else {
//                title = @"Your .TV";
//            }
        }
        
        if ([title isEqualToString:self.groupTitle] || ([title hasSuffix:@".shelby.tv"] && self.groupType == GroupType_PersonalRoll)) {
            [cell setCurrentCategory:YES];
        } else {
            [cell setCurrentCategory:NO];
        }
        
    } else if (indexPath.row < [self.categories count]) {
        NSManagedObjectContext *context = [self context];
        NSManagedObjectID *objectID = [(self.categories)[indexPath.row] objectID];
        Channel *channel = (Channel *)[context existingObjectWithID:objectID error:nil];
        NSString *channelTitle = [channel displayTitle];
        if (channel) {
            title =  [NSString stringWithFormat:@"#%@", channelTitle];
        }
        
        if ([channelTitle isEqualToString:self.groupTitle]) {
            [cell setCurrentCategory:YES];
        } else {
            [cell setCurrentCategory:NO];
        }
    }

    if (!title) {
        title = @"";
    }
    
    [((SPCategoryViewCell *)cell).title setText:title];
    return cell;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    // KP KP: TODO: remove once we have design for FB/Twitter
    if (indexPath.section == 2) {
        // FB & Twitter connect

        if ( 1 ==  indexPath.row ) {
            
            TwitterHandler *handler = [[TwitterHandler alloc] initWithViewController:self];
            [handler authenticate];
            
        }

        if (indexPath.row == 0) {
            [[FacebookHandler sharedInstance] openSession:YES];
        }
        return;
    }
    
    if (0 == indexPath.section) { // User-Specific Groups (Like, Stream, Personal Roll)
        [self launchUserGroup:indexPath.row];
    } else if ( 1 == indexPath.section) { // Category Channels and Rolls
        id category = [self.categories objectAtIndex:indexPath.row];
        [self launchCategory:category];
    }
    
    [self.model rescheduleOverlayTimer];
    
}


#pragma mark - UIGestureRecognizerDelegate methods
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    CGPoint locationInCollectionView = [gestureRecognizer locationInView:self.overlayView.categoriesCollectionView];
    if (locationInCollectionView.y >= 0) {
        return NO;
    }
    
    return YES;

}


@end
