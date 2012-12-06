//
//  SPVideoPlayer.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/1/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import "SPVideoPlayer.h"
#import "SPVideoExtractor.h"
#import "SPOverlayView.h"

@interface SPVideoPlayer ()

@property (assign, nonatomic) BOOL autoPlay;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;
@property (strong, nonatomic) UIActivityIndicatorView *indicator;
@property (strong, nonatomic) SPOverlayView *overlayView;
@property (strong, nonatomic) UIPopoverController *sharePopOverController;

- (void)loadVideo:(NSNotification*)notification;

@end

@implementation SPVideoPlayer
@synthesize videoFrame = _videoFrame;
@synthesize autoPlay = _autoPlay;
@synthesize player = _player;
@synthesize playerLayer = _playerLayer;
@synthesize indicator = _indicator;
@synthesize overlayView = _overlayView;
@synthesize sharePopOverController = _sharePopOverController;
@synthesize videoQueued = _videoQueued;

#pragma mark - Memory Management
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kSPVideoExtracted object:nil];
}

#pragma mark - Initialization Methods
- (id)initWithBounds:(CGRect)bounds
       forVideoFrame:(Frame *)videoFrame
       inOverlayView:(SPOverlayView *)overlayView
   andShouldAutoPlay:(BOOL)autoPlay
{
    if ( self = [super init] ) {
        
        [self.view setFrame:bounds];
        [self setVideoFrame:videoFrame];
        [self setAutoPlay:autoPlay];
        [self setOverlayView:overlayView];
        [self setVideoQueued:NO];
        
    }
    
    return self;
}

#pragma mark - Public Methods
- (void)queueVideo
{

    [self setVideoQueued:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadVideo:)
                                                 name:kSPVideoExtracted
                                               object:nil];
    
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_None];
    NSManagedObjectContext *context = [dataUtility context];
    Frame *tempFrame = (Frame*)[context existingObjectWithID:[_videoFrame objectID] error:nil];
    [[SPVideoExtractor sharedInstance] queueVideo:tempFrame.video];

}

#pragma mark - View Lifecycle Methods
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Add indicator
    CGRect modifiedFrame = CGRectMake(0.0f, 0.0f,self.view.frame.size.width, self.view.frame.size.height);
    self.indicator = [[UIActivityIndicatorView alloc] initWithFrame:modifiedFrame];
    self.indicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    self.indicator.hidesWhenStopped = YES;
    [self.indicator startAnimating];
    [self.view addSubview:self.indicator];
    
}

#pragma mark - Player Controls
- (void)togglePlayback
{
    if ( 0.0 == self.player.rate && _videoQueued ) { // Play
        
        [self play];
        
    } else { // Pause
            
        [self pause];
    }
}

- (void)play
{
    [self.player play];
    [self.overlayView.playButton setTitle:@"Pause" forState:UIControlStateNormal];
}

- (void)pause
{
    [self.player pause];
    [self.overlayView.playButton setTitle:@"Play" forState:UIControlStateNormal];
}

- (void)airPlay
{

}

- (void)share
{
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_None];
    NSManagedObjectContext *context = [dataUtility context];
    Frame *frame = (Frame*)[context existingObjectWithID:[self.videoFrame objectID] error:nil];
    
    NSString *shareLink = [NSString stringWithFormat:kSPVideoShareLink, frame.rollID, frame.frameID];
    NSString *shareMessage = [NSString stringWithFormat:@"Watch \"%@\" %@ /via @Shelby", frame.video.title, shareLink];
    UIActivityViewController *shareController = [[UIActivityViewController alloc] initWithActivityItems:@[shareMessage] applicationActivities:nil];
    self.sharePopOverController = [[UIPopoverController alloc] initWithContentViewController:shareController];
    [self.sharePopOverController presentPopoverFromRect:self.overlayView.shareButton.frame
                                                 inView:self.overlayView
                               permittedArrowDirections:UIPopoverArrowDirectionDown
                                               animated:YES];
}

- (CMTime)elapsedDuration
{
    AVPlayerItem *playerItem = [self.player currentItem];
	
    if (playerItem.status == AVPlayerItemStatusReadyToPlay) {
        
		return [playerItem duration] ;
	}
	
	return kCMTimeInvalid;
}

#pragma mark - Video Loading Methods
- (void)loadVideo:(NSNotification*)notification
{

    CoreDataUtility *utility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_None];
    NSManagedObjectContext *context = [utility context];
    self.videoFrame = (Frame*)[context existingObjectWithID:[self.videoFrame objectID] error:nil];
    
    Video *video = [notification.userInfo valueForKey:kSPCurrentVideo];
    
    if ( [self.videoFrame.video.providerID isEqualToString:video.providerID] ) {

        // Clear notification and indicator
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [self.indicator stopAnimating];
        
        // Instantiate AVPlayer object with extractedURL
        AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithURL:[NSURL URLWithString:_videoFrame.video.extractedURL]];
        self.player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
        self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
        CGRect modifiedFrame = CGRectMake(0.0f, 0.0f,self.view.frame.size.width, self.view.frame.size.height);
        self.playerLayer.frame = modifiedFrame;
        self.playerLayer.bounds = modifiedFrame;
        [self.view.layer addSublayer:self.playerLayer];
        
        if ( _autoPlay ) { // Start AVPlayer object in 'play' mode

            DLog(@"Loaded and Playing: %@", video.title);
            
            [self play];
            
            [UIView animateWithDuration:1.0f animations:^{
                [self.overlayView setAlpha:0.0f]; 
            }];
            
        }  else { // Start AVPlayer object in 'pause' mode

            DLog(@"Loaded and Paused: %@", video.title);
            
            [self pause];
        
        }
    }
}

@end