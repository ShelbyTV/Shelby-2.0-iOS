//
//  ViewController.m
//  ShelbyPlayer
//
//  Created by Arthur Ariel Sabintsev on 11/1/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import "SPVideoReel.h"
#import "SPVideoPlayer.h"

@interface SPVideoReel ()

@property (strong, nonatomic) AppDelegate *appDelegate;
@property (strong, nonatomic) NSMutableArray *arrayOfVideoFrames;
@property (strong, nonatomic) NSMutableArray *arrayOfVideoPlayers;
@property (assign, nonatomic) NSUInteger currentVideo;

- (void)setup;
- (void)populateScrollView;

@end

@implementation SPVideoReel
@synthesize appDelegate = _appDelegate;
@synthesize arrayOfVideoFrames = _arrayOfVideoFrames;
@synthesize arrayOfVideoPlayers = _arrayOfVideoPlayers;
@synthesize scrollView = _scrollView;
@synthesize currentVideo = _currentVideo;

#pragma mark - Memory Management
- (void)dealloc
{
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Initialization
- (id)initWithVideoFrames:(NSArray *)videoFrames
{
    if ( self == [super init] ) {
        
        self.arrayOfVideoFrames = [[NSMutableArray alloc] initWithArray:videoFrames];
        
    }
    
    return self;
}

#pragma mark - View Lifecycle Methods
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setup];
    
    [self populateScrollView];

}

#pragma mark - Private Methods
- (void)setup
{
    self.appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    self.view.frame = CGRectMake(0.0f, 0.0f, 1024.0f, 768.0f);
    self.view.backgroundColor = [UIColor blackColor];
    self.arrayOfVideoPlayers = [NSMutableArray array];
}

- (void)populateScrollView
{
    
    // Local Variables
    NSUInteger numberOfVideos = [self.arrayOfVideoFrames count];
    
    // Configure ScrollView
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
    self.scrollView.contentSize = CGSizeMake(1024.0f*numberOfVideos, 768.0f);
    self.scrollView.delegate = self;
    self.scrollView.pagingEnabled = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.scrollsToTop = NO;

    [self.view addSubview:self.scrollView];
    
    // Initialize Video Players
    for ( NSUInteger i = 0; i < numberOfVideos; i++ ) {
        
        Frame *videoFrame = [self.arrayOfVideoFrames objectAtIndex:i];
        
        BOOL autoPlay;
        if ( 0 == i ) {
            autoPlay = YES;
            self.currentVideo = i;
        } else {
            autoPlay = NO;
        }
        
        CGRect viewframe = self.scrollView.frame;
        viewframe.origin.x = viewframe.size.width * i;
        viewframe.origin.y = 0.0f;
        SPVideoPlayer *player = [[SPVideoPlayer alloc] initWithBounds:viewframe forVideo:videoFrame.video andAutoPlay:autoPlay];
        [self.arrayOfVideoPlayers addObject:player];
        [self.scrollView addSubview:player.view];
    
    }
    
}

#pragma mark - UIScrollViewDelegate Methods
- (void)scrollViewDidScroll:(UIScrollView *)sender
{
    // Switch the indicator when more than 50% of the previous/next page is visible
    CGFloat pageWidth = self.scrollView.frame.size.width;
    CGFloat scrollAmount = (self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth;
    int page = floor(scrollAmount) + 1;
    
    
    if ( page != self.currentVideo ) {
        SPVideoPlayer *oldPlayer = [self.arrayOfVideoPlayers objectAtIndex:self.currentVideo];
        [oldPlayer pause];
        SPVideoPlayer *newPlayer = [self.arrayOfVideoPlayers objectAtIndex:page];
        [newPlayer play];
        self.currentVideo = page;
    }
    
}

@end