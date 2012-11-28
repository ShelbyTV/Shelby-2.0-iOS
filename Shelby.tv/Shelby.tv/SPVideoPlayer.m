//
//  SPVideoPlayer.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/1/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import "SPVideoPlayer.h"
#import "SPVideoExtractor.h"

@interface SPVideoPlayer ()

@property (strong, nonatomic) Video *video;
@property (assign, nonatomic) BOOL autoPlay;
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;
@property (strong, nonatomic) UIActivityIndicatorView *indicator;

- (void)loadVideo:(NSNotification*)notification;

@end

@implementation SPVideoPlayer
@synthesize video = _video;
@synthesize autoPlay = _autoPlay;
@synthesize player = _player;
@synthesize playerLayer = _playerLayer;
@synthesize indicator = _indicator;

#pragma mark - Memory Management
- (void)dealloc
{

}

#pragma mark - Initialization Methods
- (id)initWithBounds:(CGRect)bounds forVideo:(Video*)video andAutoPlay:(BOOL)autoPlay;
{
    if ( self = [super init] ) {
        
        [self.view setFrame:bounds];
        [self setVideo:video];
        [self setAutoPlay:autoPlay];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(loadVideo:)
                                                     name:kSPVideoExtracted
                                                   object:nil];

        [[SPVideoExtractor sharedInstance] queueVideo:video];
        
    }
    
    return self;
}

#pragma mark - View Lifecycle Methods
- (void)viewDidLoad
{
    [super viewDidLoad];
}

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
- (void)play
{
    if ( 0.0 == self.player.rate ) {
        
        NSError *activationError = nil;
        NSError *setCategoryError = nil;
        [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error: &setCategoryError];
        [[AVAudioSession sharedInstance] setActive: YES error: &activationError];
        
        [self.player play];
    } 
    
}

- (void)pause
{
    [self.player pause];
}

- (void)airPlay
{

}

#pragma mark - Video Loading Methods
- (void)loadVideo:(NSNotification*)notification;
{

    if ( self.video == [notification.userInfo valueForKey:kSPCurrentVideo] ) {
        
        [[NSNotificationCenter defaultCenter] removeObserver:self];

        [self.indicator stopAnimating];
        
        self.player = [[AVPlayer alloc] initWithURL:[NSURL URLWithString:self.video.extractedURL]];
        self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
        CGRect modifiedFrame = CGRectMake(0.0f, 0.0f,self.view.frame.size.width, self.view.frame.size.height);
        self.playerLayer.frame = modifiedFrame;
        self.playerLayer.bounds = modifiedFrame;
        [self.view.layer addSublayer:self.playerLayer];
        
        if ( self.autoPlay ) {
            [self play];
        } else {
            [self pause];
        }
    }
    
}

@end