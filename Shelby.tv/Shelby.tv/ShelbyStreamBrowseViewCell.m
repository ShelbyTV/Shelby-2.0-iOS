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

//reuse context for better performance
@property (nonatomic, strong) CIContext *ciContext;
@property (nonatomic, strong) CIFilter *blurFilter;
@end

#define BASIC_COLUMN 0
#define DETAIL_COLUMN 1
#define PLAYBACK_COLUMN 2

//configure parallax configuration
#define PARALLAX_RATIO 0.4
#define PARALLAX_BG_X -150
#define PARALLAX_BG_Y 0
#define PARALLAX_BG_WIDTH 650
#define PARALLAX_BG_HEIGHT (kShelbyFullscreenHeight - 20)

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

        //foreground
        CGRect subviewFrame = CGRectMake(0, 20, frame.size.width, kShelbyFullscreenHeight - 20);
        _foregroundView = [[NSBundle mainBundle] loadNibNamed:@"StreamBrowseCellForegroundView" owner:nil options:nil][0];
        _foregroundView.frame = CGRectMake(0, 20, _foregroundView.frame.size.width, subviewFrame.size.height);
        [_foregroundView.playButton addTarget:self action:@selector(playTapped:) forControlEvents:UIControlEventTouchUpInside];
        [_foregroundView.altPlayButton addTarget:self action:@selector(playTapped:) forControlEvents:UIControlEventTouchUpInside];


        //background - thumbnails are on top of each other in a parent view
        CGRect bgThumbsHolderFrame = CGRectMake(PARALLAX_BG_X, PARALLAX_BG_Y, PARALLAX_BG_WIDTH, PARALLAX_BG_HEIGHT);
        _backgroundThumbnailsView = [[UIView alloc] initWithFrame:bgThumbsHolderFrame];
        _thumbnailRegularView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, PARALLAX_BG_WIDTH, PARALLAX_BG_HEIGHT)];
        _thumbnailRegularView.contentMode = UIViewContentModeScaleAspectFit;
        [_backgroundThumbnailsView addSubview:_thumbnailRegularView];
        _thumbnailBlurredView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, PARALLAX_BG_WIDTH, PARALLAX_BG_HEIGHT)];
        _thumbnailBlurredView.contentMode = UIViewContentModeScaleAspectFit;
        _thumbnailBlurredView.alpha = 0.0;
        [_backgroundThumbnailsView addSubview:_thumbnailBlurredView];


        //parallax for foreground and background (above)
        _parallaxView = [[STVParallaxView alloc] initWithFrame:subviewFrame];
        _parallaxView.delegate = self;
        [self.contentView addSubview:self.parallaxView];
        _parallaxView.foregroundContent = _foregroundView;
        _parallaxView.backgroundContent = _backgroundThumbnailsView;
        _parallaxView.parallaxRatio = PARALLAX_RATIO;
        
        [self setAutoresizesSubviews:YES];
    }
    return self;
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

//        [cell.caption setText:[NSString stringWithFormat:@"%@: %@", videoFrame.creator.nickname, [videoFrame creatorsInitialCommentWithFallback:YES]]];
//don't like this magic number, but also don't think the constant belongs in BrowseViewController...
//        CGSize maxCaptionSize = CGSizeMake(cell.frame.size.width, cell.frame.size.height * 0.33);
//        CGFloat textBasedHeight = [cell.caption.text sizeWithFont:[cell.caption font]
//                                                constrainedToSize:maxCaptionSize
//                                                    lineBreakMode:NSLineBreakByWordWrapping].height;
//
//        [cell.caption setFrame:CGRectMake(cell.caption.frame.origin.x,
//                                          cell.frame.size.height - textBasedHeight,
//                                          cell.frame.size.width,
//                                          textBasedHeight)];
    }
}

- (void)setupImagesWith:(UIImage *)image
{
    if (self.thumbnailRegularView.image != image) {
        //regular background
        self.thumbnailRegularView.image = image;
        self.thumbnailRegularView.frame = CGRectMake(0, 0, PARALLAX_BG_WIDTH, PARALLAX_BG_HEIGHT);

        //blurred background
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
                [self.parallaxView getBackgroundView].hidden = NO;
                break;
            case ShelbyStreamBrowseViewForPlayback:
                [self.parallaxView getBackgroundView].hidden = YES;
        }
    }
}

#pragma mark - StreamBrowseCellForegroundView

- (void)playTapped:(id)sender
{
    [self.delegate playTapped:self];
}

#pragma mark - STVParallaxViewDelegate

- (void)parallaxDidChange:(STVParallaxView *)parallaxView
{
    //TODO: this constant won't work when we allow for rotation
    CGFloat alpha = parallaxView.foregroundContentOffset.x / 320.0;
    self.thumbnailBlurredView.alpha = alpha;

    [self.delegate parallaxDidChange:self];
}

- (void)didScrollToPage:(NSUInteger)page
{
    //this method intentionally left blank
}

@end
