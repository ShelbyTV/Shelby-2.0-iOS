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
#import "StreamBrowseCellForegroundView.h"

@interface ShelbyStreamBrowseViewCell()
@property (nonatomic, strong) STVParallaxView *parallaxView;
@property (nonatomic, strong) UIView *backgroundThumbnailsView;
@property (nonatomic, strong) UIImageView *thumbnailRegularView;
@property (nonatomic, strong) UIImageView *thumbnailBlurredView;
@property (nonatomic, strong) StreamBrowseCellForegroundView *foregroundView;
@property (nonatomic, strong) UIImageView *overlayImageView;
@property (nonatomic, strong) UIButton *playButton;

//reuse context for better performance
@property (nonatomic, strong) CIContext *ciContext;
@property (nonatomic, strong) CIFilter *blurFilter;
@end

//configure parallax configuration
#define PARALLAX_RATIO 0.4
#define PARALLAX_BG_X -150
#define PARALLAX_BG_Y 0
#define PARALLAX_BG_WIDTH 650
#define PARALLAX_BG_HEIGHT kShelbyFullscreenHeight

#define BLUR_RADIUS 4.0

@implementation ShelbyStreamBrowseViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _viewMode = ShelbyStreamBrowseViewDefault;

        //CoreImage stuff to do blurring
        _ciContext = [CIContext contextWithOptions:nil];
        _blurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
        [_blurFilter setValue:@(BLUR_RADIUS) forKey:@"inputRadius"];

        //parallax foreground
        CGRect subviewFrame = CGRectMake(0, 0, frame.size.width, kShelbyFullscreenHeight);
        _foregroundView = [[NSBundle mainBundle] loadNibNamed:@"StreamBrowseCellForegroundView" owner:nil options:nil][0];
        _foregroundView.frame = CGRectMake(0, 0, _foregroundView.frame.size.width, subviewFrame.size.height);

        //parallax background - thumbnails are on top of each other in a parent view
        CGRect bgThumbsHolderFrame = CGRectMake(PARALLAX_BG_X, PARALLAX_BG_Y, PARALLAX_BG_WIDTH, PARALLAX_BG_HEIGHT);
        _backgroundThumbnailsView = [[UIView alloc] initWithFrame:bgThumbsHolderFrame];
        _thumbnailRegularView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, PARALLAX_BG_WIDTH, PARALLAX_BG_HEIGHT)];
        _thumbnailRegularView.contentMode = UIViewContentModeScaleAspectFill;
        [_backgroundThumbnailsView addSubview:_thumbnailRegularView];
        _thumbnailBlurredView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, PARALLAX_BG_WIDTH, PARALLAX_BG_HEIGHT)];
        _thumbnailBlurredView.contentMode = UIViewContentModeScaleAspectFill;
        _thumbnailBlurredView.alpha = 0.0;
        [_backgroundThumbnailsView addSubview:_thumbnailBlurredView];

        [self setupOverlayImageView];
        self.overlayImageView.frame = _thumbnailRegularView.frame;
        [_backgroundThumbnailsView addSubview:self.overlayImageView];
        
        //parallax for foreground and background (above)
        _parallaxView = [[STVParallaxView alloc] initWithFrame:subviewFrame];
        _parallaxView.delegate = self;
        [self.contentView addSubview:_parallaxView];
        _parallaxView.foregroundContent = _foregroundView;
        _parallaxView.backgroundContent = _backgroundThumbnailsView;
        _parallaxView.parallaxRatio = PARALLAX_RATIO;

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
        
        [self setAutoresizesSubviews:YES];

        //XXX LAYOUT TESTING
//        self.layer.borderColor = [UIColor yellowColor].CGColor;
//        self.layer.borderWidth = 2.0;
        //XXX LAYOUT TESTING
    }
    return self;
}

- (void)setupOverlayImageView
{
    NSString *imageName = nil;
    if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
        imageName = @"overlay-landscape.png";
    } else {
        if (kShelbyFullscreenHeight > 480) {
            imageName = @"overlay-568h.png";
        } else {
            imageName = @"overlay.png";
        }
    }

    UIImage *overlayImage = [[UIImage imageNamed:imageName] resizableImageWithCapInsets:UIEdgeInsetsZero resizingMode:UIImageResizingModeStretch];
    
    if (!self.overlayImageView) {
        self.overlayImageView = [[UIImageView alloc] initWithImage:overlayImage];
    } else {
        self.overlayImageView.image = overlayImage;
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    // Reset overlay image after rotation.
    [self setupOverlayImageView];
}

- (void)prepareForReuse
{
    self.thumbnailRegularView.image = nil;
    self.thumbnailBlurredView.image = nil;
}

- (void)setEntry:(id<ShelbyVideoContainer>)entry
{
    _entry = entry;
    
    Frame *videoFrame = nil;
    if ([entry isKindOfClass:[DashboardEntry class]]) {
        videoFrame = ((DashboardEntry *)entry).frame;
    } else if([entry isKindOfClass:[Frame class]]) {
        videoFrame = (Frame *)entry;
    } else {
        STVAssert(false, @"Expected a DashboardEntry or Frame");
    }

    if (videoFrame && videoFrame.video) {
        Video *video = videoFrame.video;
        //images
        if (video && video.thumbnailURL) {
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
                                                                   //ignoring for now
                                                               }] start];
        }

        [self.foregroundView setInfoForFrame:videoFrame];
    }
}

- (void)updateParallaxFrame:(CGRect)frame
{
    [self.parallaxView updateFrame:frame];
}

- (void)setupImagesWith:(UIImage *)image
{
    if (self.thumbnailRegularView.image != image) {
        //regular background
        self.thumbnailRegularView.image = image;
        self.thumbnailRegularView.frame = CGRectMake(0, 0, PARALLAX_BG_WIDTH, PARALLAX_BG_HEIGHT);

        //blurred background
        // The one thing that seems slow is blurring very high resolution images...
        //OPTIMIZE: No need to run on every pixel of a huge image, just to make it blurry.
        //          Run the filter over a smaller image, see how much faster that gets.
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.blurFilter setValue:[CIImage imageWithCGImage:image.CGImage] forKey:@"inputImage"];
            CIImage *result = [self.blurFilter valueForKey:@"outputImage"];
            CGImageRef cgImage = [self.ciContext createCGImage:result fromRect:[result extent]];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.thumbnailBlurredView.image = [UIImage imageWithCGImage:cgImage];
                CFRelease(cgImage);
                [self.blurFilter setValue:nil forKey:@"inputImage"];
            });
        });
    }
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
            case ShelbyStreamBrowseViewDefault:
                self.playButton.alpha = 1.0;
                [self.parallaxView getBackgroundView].alpha = 1.0;
                break;
            case ShelbyStreamBrowseViewForPlaybackWithOverlay:
                self.playButton.alpha = 0.0;
                [self.parallaxView getBackgroundView].alpha = 0.0;
                self.foregroundView.alpha = 1.0;
                break;
            case ShelbyStreamBrowseViewForPlaybackWithoutOverlay:
                self.playButton.alpha = 0.0;
                [self.parallaxView getBackgroundView].alpha = 0.0;
                self.foregroundView.alpha = 0.0;
        }
    }
}

- (void)playButtonTapped:(id)sender
{
    [self.delegate browseViewCellPlayTapped:self];
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
    CGFloat alpha = parallaxView.foregroundContentOffset.x / self.frame.size.width;
    self.thumbnailBlurredView.alpha = alpha;

    [self.delegate browseViewCellParallaxDidChange:self];
}

- (void)didScrollToPage:(NSUInteger)page
{
    [self.delegate browseViewCell:self parallaxDidChangeToPage:page];
}

@end
