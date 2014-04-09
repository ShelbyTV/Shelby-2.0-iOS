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
#import "GPUImage.h"
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

@property (nonatomic, strong) GPUImageiOSBlurFilter *blurFilter;
@end

//configure parallax configuration
#define PARALLAX_RATIO_PORTRAIT 0.1
#define PARALLAX_BG_WIDTH_PORTRAIT (kShelbyFullscreenWidth*(1.05+PARALLAX_RATIO_LANDSCAPE))
#define PARALLAX_BG_HEIGHT_PORTRAIT kShelbyFullscreenHeight*1.15
#define PARALLAX_RATIO_LANDSCAPE 0.05
#define PARALLAX_BG_WIDTH_LANDSCAPE (kShelbyFullscreenHeight*(1.1+PARALLAX_RATIO_LANDSCAPE))
#define PARALLAX_BG_HEIGHT_LANDSCAPE kShelbyFullscreenWidth*1.4

static id<ShelbyVideoContainer> _currentlyPlayingEntity;

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

        _thumbnailBlurredView = [[UIImageView alloc] initWithFrame:bgFrame];
        _thumbnailBlurredView.contentMode = UIViewContentModeScaleAspectFill;
        [_backgroundThumbnailsView addSubview:_thumbnailBlurredView];

        _thumbnailRegularView = [[UIImageView alloc] initWithFrame:bgFrame];
        _thumbnailRegularView.contentMode = UIViewContentModeScaleAspectFill;
        _thumbnailRegularView.clipsToBounds = YES;
        [_backgroundThumbnailsView addSubview:_thumbnailRegularView];

        //parallax for foreground and background (above)
        _parallaxView = [[STVParallaxView alloc] initWithFrame:subviewFrame];
        _parallaxView.delegate = self;
        [self.contentView addSubview:_parallaxView];
        _parallaxView.foregroundContent = _foregroundView;
        _parallaxView.backgroundContent = _backgroundThumbnailsView;
        _parallaxView.parallaxRatio = PARALLAX_RATIO_PORTRAIT;
        
        //blur filter
        self.blurFilter = [[GPUImageiOSBlurFilter alloc] init];
        self.blurFilter.saturation = 0.7;
        self.blurFilter.blurRadiusInPixels = 6.f;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoPlayingChanged:) name:kShelbyPlaybackEntityDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setupPlayImageForCurrentlyPlayingEntity) name:kShelbySPVideoAirplayDidBegin object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setupPlayImageForCurrentlyPlayingEntity) name:kShelbySPVideoAirplayDidEnd object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)resizeParallaxViews
{
    CGRect bgFrame, regularThumbnailFrame, fullScreenFrame;
    if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
        bgFrame = CGRectMake(-15, -20, PARALLAX_BG_WIDTH_LANDSCAPE, PARALLAX_BG_HEIGHT_LANDSCAPE);
        regularThumbnailFrame = bgFrame;
        fullScreenFrame = CGRectMake(0, 0, kShelbyFullscreenHeight, kShelbyFullscreenWidth);
        _parallaxView.parallaxRatio = PARALLAX_RATIO_LANDSCAPE;
        _thumbnailRegularView.contentMode = UIViewContentModeScaleAspectFit;
    } else {
        bgFrame = CGRectMake(0, -20, PARALLAX_BG_WIDTH_PORTRAIT, PARALLAX_BG_HEIGHT_PORTRAIT);
        CGFloat fullWidth = PARALLAX_BG_WIDTH_PORTRAIT;
        CGFloat aspectAppropriateHeight = PARALLAX_BG_WIDTH_PORTRAIT / 1.8;
        regularThumbnailFrame = CGRectMake(0, (kShelbyFullscreenHeight / 2.0) - (aspectAppropriateHeight / 2.0) + 20, fullWidth, aspectAppropriateHeight);
        fullScreenFrame = CGRectMake(0, 0, kShelbyFullscreenWidth, kShelbyFullscreenHeight);
        _parallaxView.parallaxRatio = PARALLAX_RATIO_PORTRAIT;
        _thumbnailRegularView.contentMode = UIViewContentModeScaleAspectFill;
    }

    [self.parallaxView updateFrame:fullScreenFrame];
    //when parallax updates it's frame, it updates the content's frame and content size as well.
    //foreground is fine, but background is not...
    _backgroundThumbnailsView.frame = bgFrame;
    _thumbnailRegularView.frame = regularThumbnailFrame;
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
        [self setupPlayImageForCurrentlyPlayingEntity];
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

        //blurry background
        __block UIImage *blurred;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            blurred = [_blurFilter imageByFilteringImage:image];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.thumbnailRegularView.image == image) {
                    self.thumbnailBlurredView.image = blurred;
                } else {
                    //we've been re-used, don't set incorrect background
                }
                
            });
        });
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

- (void)setupPlayImageForCurrentlyPlayingEntity
{
    if (self.viewMode == ShelbyStreamBrowseViewForAirplay) {
        if (_currentlyPlayingEntity == self.entry) {
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
    _currentlyPlayingEntity = newEntity;
    
    [self setupPlayImageForCurrentlyPlayingEntity];
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
    [self setupPlayImageForCurrentlyPlayingEntity];
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
