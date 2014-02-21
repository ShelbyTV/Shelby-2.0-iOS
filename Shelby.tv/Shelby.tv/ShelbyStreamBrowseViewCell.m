//
//  ShelbyStreamBrowseViewCell.m
//  Shelby.tv
//
//  Created by Keren on 6/21/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyStreamBrowseViewCell.h"
#import "AFNetworking.h"
#import "DashboardEntry+Helper.h"
#import "Frame+Helper.h"
#import "ShelbyViewController.h"
#import "SPVideoPlayer.h"
#import "Video+Helper.h"

@interface ShelbyStreamBrowseViewCell(){
    UIImage *_placeholderThumbnail;
}
@property (nonatomic, strong) STVParallaxView *parallaxView;
@property (nonatomic, strong) UIView *backgroundThumbnailsView;
@property (nonatomic, strong) UIImageView *thumbnailRegularView;
@property (nonatomic, strong) UIImageView *thumbnailBlurredView;
@property (nonatomic, strong) StreamBrowseCellForegroundView *foregroundView;
@property (nonatomic, strong) UIButton *playButton;
@end

//configure parallax configuration
#define PARALLAX_RATIO_PORTRAIT 0.75
#define PARALLAX_BG_WIDTH_PORTRAIT kShelbyFullscreenWidth*0.8
#define PARALLAX_BG_HEIGHT_PORTRAIT kShelbyFullscreenHeight*1.2
#define PARALLAX_RATIO_LANDSCAPE 0.1
#define PARALLAX_BG_WIDTH_LANDSCAPE (kShelbyFullscreenHeight*(1+PARALLAX_RATIO_LANDSCAPE))
#define PARALLAX_BG_HEIGHT_LANDSCAPE kShelbyFullscreenWidth

@implementation ShelbyStreamBrowseViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _viewMode = ShelbyStreamBrowseViewDefault;

        //parallax foreground
        CGRect subviewFrame = CGRectMake(0, 0, frame.size.width, kShelbyFullscreenHeight);
        _foregroundView = [[NSBundle mainBundle] loadNibNamed:@"StreamBrowseCellForegroundView" owner:nil options:nil][0];
        _foregroundView.frame = CGRectMake(0, 0, _foregroundView.frame.size.width, subviewFrame.size.height);
        _foregroundView.delegate = self;

        //parallax background - thumbnails are on top of each other in a parent view
        CGRect bgFrame = CGRectMake(0, 0, PARALLAX_BG_WIDTH_PORTRAIT, PARALLAX_BG_HEIGHT_PORTRAIT);
        _backgroundThumbnailsView = [[UIView alloc] initWithFrame:bgFrame];
        _thumbnailRegularView = [[UIImageView alloc] initWithFrame:bgFrame];
        _thumbnailRegularView.contentMode = UIViewContentModeScaleAspectFill;
        [_backgroundThumbnailsView addSubview:_thumbnailRegularView];
        _thumbnailBlurredView = [[UIImageView alloc] initWithFrame:bgFrame];
        _thumbnailBlurredView.contentMode = UIViewContentModeScaleAspectFill;
        _thumbnailBlurredView.alpha = 0.0;
        [_backgroundThumbnailsView addSubview:_thumbnailBlurredView];

        //parallax for foreground and background (above)
        _parallaxView = [[STVParallaxView alloc] initWithFrame:subviewFrame];
        _parallaxView.delegate = self;
        [self.contentView addSubview:_parallaxView];
        _parallaxView.foregroundContent = _foregroundView;
        _parallaxView.backgroundContent = _backgroundThumbnailsView;
        _parallaxView.parallaxRatio = PARALLAX_RATIO_PORTRAIT;

        // KP: For now, moving the play button to the VideoControlsView.
        //a big play button on top of the parallax view (shown when video controls aren't)
//        _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
//        _playButton.titleLabel.font = kShelbyFontH5Bold;
//        [_playButton setTitleColor:kShelbyColorGreen forState:UIControlStateNormal];
//        [_playButton addTarget:self action:@selector(playButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
//        [_playButton setTitle:@"PLAY" forState:UIControlStateNormal];
//        
//        [self.contentView insertSubview:_playButton aboveSubview:_parallaxView];
//        _playButton.translatesAutoresizingMaskIntoConstraints = NO;
//        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-13-[play(100)]"
//                                                                                 options:0
//                                                                                 metrics:nil
//                                                                                   views:@{@"play":_playButton}]];
//        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[play]-40-|"
//                                                                                 options:0
//                                                                                 metrics:nil
//                                                                                   views:@{@"play":_playButton}]];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoPlayingChanged:) name:kShelbyPlaybackEntityDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setupPlayImageForVideo) name:kShelbySPVideoAirplayDidBegin object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setupPlayImageForVideo) name:kShelbySPVideoAirplayDidEnd object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)resizeParallaxViews
{
    CGRect bgFrame, fullScreenFrame;
    if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
        bgFrame = CGRectMake(0, 0, PARALLAX_BG_WIDTH_LANDSCAPE, PARALLAX_BG_HEIGHT_LANDSCAPE);
        fullScreenFrame = CGRectMake(0, 0, kShelbyFullscreenHeight, kShelbyFullscreenWidth);
        _parallaxView.parallaxRatio = PARALLAX_RATIO_LANDSCAPE;
    } else {
        bgFrame = CGRectMake(0, -20, PARALLAX_BG_WIDTH_PORTRAIT, PARALLAX_BG_HEIGHT_PORTRAIT);
        fullScreenFrame = CGRectMake(0, 0, kShelbyFullscreenWidth, kShelbyFullscreenHeight);
        _parallaxView.parallaxRatio = PARALLAX_RATIO_PORTRAIT;
    }

    [self.parallaxView updateFrame:fullScreenFrame];
    //when parallax updates it's frame, it updates the content's frame and content size as well.
    //foreground is fine, but background is not...
    _backgroundThumbnailsView.frame = bgFrame;
    _thumbnailRegularView.frame = bgFrame;
    _thumbnailBlurredView.frame = bgFrame;
    _parallaxView.backgroundContent = _backgroundThumbnailsView;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    [self resizeParallaxViews];
}

- (void)prepareForReuse
{
    self.thumbnailRegularView.image = nil;
    self.thumbnailBlurredView.image = nil;

    //we may be in a new orientation...
    [self resizeParallaxViews];
}

- (void)setEntry:(id<ShelbyVideoContainer>)entry
{
    _entry = entry;
    
    Frame *videoFrame = nil;
    DashboardEntry *dashboardEntry = nil;
    if ([entry isKindOfClass:[DashboardEntry class]]) {
        dashboardEntry = (DashboardEntry *)entry;
        videoFrame = dashboardEntry.frame;
    } else if([entry isKindOfClass:[Frame class]]) {
        videoFrame = (Frame *)entry;
    } else {
        STVAssert(NO, @"Expected a DashboardEntry or Frame");
    }

    if (videoFrame && videoFrame.video) {
        Video *video = videoFrame.video;
        //images
        if (video && video.thumbnailURL) {
            [self tryMaxResThumbnailURLForEntry:entry withVideo:video];
        } else {
            [self displayPlaceholderThumbnails];
        }

        [self.foregroundView setInfoForDashboardEntry:dashboardEntry frame:videoFrame];
        [self setupPlayImageForEntity:entry];
    }
}

- (void)tryMaxResThumbnailURLForEntry:(id<ShelbyVideoContainer>)entry withVideo:(Video *)video
{
    NSURLRequest *imageRequest = [NSURLRequest requestWithURL:[video maxResThumbnailURL]];
    [[AFImageRequestOperation imageRequestOperationWithRequest:imageRequest
                                          imageProcessingBlock:nil
                                                       success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                                           if (self.entry == entry) {
                                                               [self setupImagesWith:image];
                                                           } else {
                                                               //cell has been reused, do nothing
                                                           }
                                                       }
                                                       failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                                           if (self.entry == entry) {
                                                               [self tryNormalThumbnailURLForEntry:entry withVideo:video];
                                                           } else {
                                                               //cell has been reused, do nothing
                                                           }
                                                       }] start];
}

- (void)tryNormalThumbnailURLForEntry:(id<ShelbyVideoContainer>)entry withVideo:(Video *)video
{
    NSURLRequest *imageRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:video.thumbnailURL]];
    [[AFImageRequestOperation imageRequestOperationWithRequest:imageRequest
                                          imageProcessingBlock:nil
                                                       success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                                           if (self.entry == entry) {
                                                               [self setupImagesWith:image];
                                                           } else {
                                                               //cell has been reused, do nothing
                                                           }
                                                       }
                                                       failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                                           if (self.entry == entry) {
                                                               [self displayPlaceholderThumbnails];
                                                           } else {
                                                               //cell has been reused, do nothing
                                                           }
                                                       }] start];
}

- (void)setupImagesWith:(UIImage *)image
{
    if (self.thumbnailRegularView.image != image) {
        //regular background
        self.thumbnailRegularView.image = image;

        //No longer using blurred (or any) background in iOS6 or 7
    }
}

- (void)displayPlaceholderThumbnails
{
    self.thumbnailRegularView.image = _placeholderThumbnail;
}

- (void)matchParallaxOf:(ShelbyStreamBrowseViewCell *)cell
{
    if (cell && cell != self) {
        [self.parallaxView matchParallaxOf:cell.parallaxView];
    }
}

- (void)setViewMode:(ShelbyStreamBrowseViewMode)viewMode
{
    if (_viewMode != viewMode) {
        _viewMode = viewMode;
        switch (_viewMode) {
            case ShelbyStreamBrowseViewForAirplay:
            case ShelbyStreamBrowseViewDefault:
                self.playButton.alpha = 1.0;
                [self.parallaxView getBackgroundView].alpha = 1.0;
                self.foregroundView.alpha = 1.0;
                self.foregroundView.summaryPlayImageView.hidden = NO;
                break;
            case ShelbyStreamBrowseViewForPlaybackWithOverlay:
                self.playButton.alpha = 0.0;
                [self.parallaxView getBackgroundView].alpha = 0.0;
                self.foregroundView.alpha = 1.0;
                self.foregroundView.summaryPlayImageView.hidden = YES;
                break;
            case ShelbyStreamBrowseViewForPlaybackWithoutOverlay:
                self.playButton.alpha = 0.0;
                [self.parallaxView getBackgroundView].alpha = 0.0;
                self.foregroundView.alpha = 0.0;
                self.foregroundView.summaryPlayImageView.hidden = YES;
                break;
            case ShelbyStreamBrowseViewForPlaybackPeeking:
                self.playButton.alpha = 0.0;
                [self.parallaxView getBackgroundView].alpha = 0.0;
                self.foregroundView.alpha = 1.0;
                self.foregroundView.summaryPlayImageView.hidden = YES;
                break;
        }
    }
}


- (void)setupPlayImageForEntity:(id<ShelbyVideoContainer>)newEntity
{
    if (self.viewMode == ShelbyStreamBrowseViewForAirplay) {
        if (newEntity == self.entry) {
            self.foregroundView.summaryPlayImageView.image = [UIImage imageNamed:@"play-current.png"];
        } else {
            self.foregroundView.summaryPlayImageView.image = [UIImage imageNamed:@"play-airplay.png"];
        }
    } else {
        self.foregroundView.summaryPlayImageView.image = [UIImage imageNamed:@"play-all.png"];
    }
}

- (void)videoPlayingChanged:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    id<ShelbyVideoContainer> newEntity = userInfo[kShelbyPlaybackCurrentEntityKey];
    
    [self setupPlayImageForEntity:newEntity];
}

+ (void)cacheEntry:(id<ShelbyVideoContainer>)entry
{
    /* Networking code will cache requests for us, so all we have to do is make the request.
     *
     * Seems premature to do blurring and cache that image, but I DO think we need to optimize
     * the blurring code (no need to run on huge images)
     */
    Video *v = [entry containedVideo];
    if (v && v.thumbnailURL) {
        NSURLRequest *imageRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:v.thumbnailURL]];
        [[AFImageRequestOperation imageRequestOperationWithRequest:imageRequest
                                              imageProcessingBlock:nil
                                                           success:nil
                                                           failure:nil] start];
    }
}

#pragma mark - STVParallaxViewDelegate

- (void)parallaxDidChange:(STVParallaxView *)parallaxView
{
    [self.delegate browseViewCellParallaxDidChange:self];
}

- (void)didScrollToPage:(NSUInteger)page
{
    [ShelbyViewController sendEventWithCategory:kAnalyticsCategoryPrimaryUX
                                     withAction:kAnalyticsUXSwipeCardParallax
                            withNicknameAsLabel:YES];
    [self.delegate browseViewCell:self parallaxDidChangeToPage:page];
}

- (void)parallaxViewWillBeginDragging
{
    //do nothing
}

#pragma mark - StreamBrowseCellForegroundDelegate
- (void)streamBrowseCellForegroundViewTitleWasTapped
{
    [self.delegate browseViewCellTitleWasTapped:self];
    [self setupPlayImageForEntity:self.entry];
}

- (void)shareVideoWasTapped
{
    [self.delegate shareVideo:self];
}

- (void)inviteFacebookFriendsWasTapped
{
    [self.delegate inviteFacebookFriendsWasTapped:self];
}

- (void)userProfileWasTapped:(NSString *)userID
{
    [self.delegate userProfileWasTapped:self withUserID:userID];
}

- (void)openLikersView:(NSMutableOrderedSet *)likers
{
    [self.delegate openLikersView:self withLikers:likers];
}
@end
