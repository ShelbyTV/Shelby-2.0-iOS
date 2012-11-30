//
//  ViewController.m
//  ShelbyPlayer
//
//  Created by Arthur Ariel Sabintsev on 11/1/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import "SPVideoReel.h"
#import "SPVideoPlayer.h"
#import "SPOverlayView.h"
#import "SPVideoExtractor.h"

@interface SPVideoReel ()

@property (strong, nonatomic) AppDelegate *appDelegate;
@property (strong, nonatomic) NSMutableArray *videoFrames;
@property (strong, nonatomic) NSMutableArray *videoPlayers;
@property (strong, nonatomic) UIScrollView *videoScrollView;
@property (strong, nonatomic) SPOverlayView *overlayView;
@property (strong, nonatomic) SPVideoPlayer *currentVideoPlayer;
@property (assign, nonatomic) NSUInteger currentVideo;
@property (assign, nonatomic) NSUInteger numberOfVideos;
@property (copy, nonatomic) NSString *categoryTitle;

- (void)setupVariables;
- (void)setupVideoScrollView;
- (void)setupOverlayView;
- (void)setupVideoPlayers;
- (void)extractVideoForVideoPlayer:(NSUInteger)videoPlayerNumber;
- (void)toggleOverlay;

@end

@implementation SPVideoReel
@synthesize appDelegate = _appDelegate;
@synthesize videoFrames = _videoFrames;
@synthesize videoPlayers = _videoPlayers;
@synthesize videoScrollView = _videoScrollView;
@synthesize overlayView = _overlayView;
@synthesize currentVideoPlayer = _currentVideoPlayer;
@synthesize currentVideo = _currentVideo;
@synthesize numberOfVideos = _numberOfVideos;
@synthesize categoryTitle = _categoryTitle;

#pragma mark - Memory Management
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Initialization
- (id)initWithVideoFrames:(NSArray *)videoFrames andCategoryTitle:(NSString *)title
{
    self = [super init];
    
    if ( self ) {
        
        self.videoFrames = [[NSMutableArray alloc] initWithArray:videoFrames];
        self.categoryTitle = title;
    }
    
    return self;
}

#pragma mark - View Lifecycle Methods
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.frame = CGRectMake(0.0f, 0.0f, 1024.0f, 768.0f);
    self.view.backgroundColor = [UIColor blackColor];
    
    [self setupVariables];
    [self setupVideoScrollView];
    [self setupOverlayView];
    [self setupVideoPlayers];
    
}

#pragma mark - Public Methods
- (IBAction)homeButtonAction:(id)sender
{

    DLog(@"BEFORE: %@", self.videoPlayers);
    
    // Stops residual video playback
    for ( SPVideoPlayer *player in _videoPlayers ) {
        
        [player.player pause];
        
    }
    
    [[SPVideoExtractor sharedInstance] cancelRemainingExtractions];
    [self.videoPlayers removeAllObjects];
    [self.videoFrames removeAllObjects];
    
    NSError *activationError = nil;
    NSError *setCategoryError = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&setCategoryError];
    [[AVAudioSession sharedInstance] setActive:NO error:&activationError];
    
    DLog(@"AFTER: %@", self.videoPlayers);
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)playButtonAction:(id)sender
{
    [self.currentVideoPlayer play];
}

- (IBAction)airplayButtonAction:(id)sender
{
    [self.currentVideoPlayer airPlay];
}

- (IBAction)shareButtonAction:(id)sender
{
    [self.currentVideoPlayer share];
}

#pragma mark - Private Methods
- (void)setupVariables
{
    self.appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    self.videoPlayers = [[NSMutableArray alloc] init];
    self.numberOfVideos = [self.videoFrames count];
}

- (void)setupVideoScrollView
{
    self.videoScrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
    self.videoScrollView.contentSize = CGSizeMake(1024.0f*_numberOfVideos, 768.0f);
    self.videoScrollView.delegate = self;
    self.videoScrollView.pagingEnabled = YES;
    self.videoScrollView.showsHorizontalScrollIndicator = NO;
    self.videoScrollView.showsVerticalScrollIndicator = NO;
    self.videoScrollView.scrollsToTop = NO;
    [self.view addSubview:self.videoScrollView];
}

- (void)setupOverlayView
{
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SPOverlayView" owner:self options:nil];
    self.overlayView = [nib objectAtIndex:0];
    [_overlayView.titleLabel setText:self.categoryTitle];
    [self.view addSubview:_overlayView];
    
    UITapGestureRecognizer *toggleOverlayGesuture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleOverlay)];
    [toggleOverlayGesuture setNumberOfTapsRequired:1];
    [self.view addGestureRecognizer:toggleOverlayGesuture];
    
}

- (void)setupVideoPlayers
{
    for ( NSUInteger i = 0; i < _numberOfVideos; i++ ) {
        
        Frame *videoFrame = [self.videoFrames objectAtIndex:i];
        
        BOOL autoPlay;
        if ( 0 == i ) {
            autoPlay = YES;
            self.currentVideo = i;
        } else {
            autoPlay = NO;
        }
        
        CGRect viewframe = self.videoScrollView.frame;
        viewframe.origin.x = viewframe.size.width * i;
        viewframe.origin.y = 0.0f;
        SPVideoPlayer *player = [[SPVideoPlayer alloc] initWithBounds:viewframe
                                                        forVideoFrame:videoFrame
                                                        inOverlayView:_overlayView
                                                    andShouldAutoPlay:autoPlay];
        [self.videoPlayers addObject:player];
        [self.videoScrollView addSubview:player.view];
        
        // Extracting video for the first two SPVideoPlayer objects
        if ( 0 == i ) {
            
            [self extractVideoForVideoPlayer:i];
            self.currentVideoPlayer = [self.videoPlayers objectAtIndex:0];
        
        } else if ( 1 == i ) {
            
            [self extractVideoForVideoPlayer:i];
        }

    }
}
- (void)extractVideoForVideoPlayer:(NSUInteger)videoPlayerNumber;
{
    
    SPVideoPlayer *player = [self.videoPlayers objectAtIndex:videoPlayerNumber];
    
    if ( (videoPlayerNumber > _numberOfVideos) || [player videoQueued] ) {
        return;
    } else {
       [player queueVideo];
    }

}

- (void)toggleOverlay
{
    if ( self.overlayView.alpha < 1.0f ) {
        
        [UIView animateWithDuration:0.5f animations:^{
            [self.overlayView setAlpha:1.0f];
        }];
        
    } else {
        
        [UIView animateWithDuration:0.5f animations:^{
            [self.overlayView setAlpha:0.0f];
        }];
        
    }
}

#pragma mark - UIScrollViewDelegate Methods
- (void)scrollViewDidScroll:(UIScrollView *)sender
{
    // Switch the indicator when more than 50% of the previous/next page is visible
    CGFloat pageWidth = self.videoScrollView.frame.size.width;
    CGFloat scrollAmount = (self.videoScrollView.contentOffset.x - pageWidth / 2) / pageWidth;
    int page = floor(scrollAmount) + 1;

    // Toggle playback on old and new SPVideoPlayer objects
    if ( page != self.currentVideo ) {
        
        SPVideoPlayer *oldPlayer = [self.videoPlayers objectAtIndex:self.currentVideo];
        [oldPlayer.player pause];
        
        SPVideoPlayer *newPlayer = [self.videoPlayers objectAtIndex:page];
        [newPlayer play];
        
        self.currentVideo = page;
    }
    
    // Load video for newly visible SPVideoPlayer object, and SPVideoPlayer objects flanking the currently visible player.
    if ( page > 0 ) [self extractVideoForVideoPlayer:page-1];
    [self extractVideoForVideoPlayer:page];
    if ( page < _numberOfVideos-1 ) [self extractVideoForVideoPlayer:page+1];
    
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    // Reset currentVideoPlayer reference after scrolling has finished
    self.currentVideoPlayer = [self.videoPlayers objectAtIndex:_currentVideo];
}

@end