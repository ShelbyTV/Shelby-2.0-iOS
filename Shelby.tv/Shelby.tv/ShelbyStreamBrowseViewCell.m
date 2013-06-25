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
@property (nonatomic, strong) UIImageView *backgroundThumbnailView;
@property (nonatomic, strong) StreamBrowseCellForegroundView *foregroundView;
@end

@implementation ShelbyStreamBrowseViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        CGRect subviewFrame = CGRectMake(0, 0, frame.size.width, frame.size.height);
        _foregroundView = [[NSBundle mainBundle] loadNibNamed:@"StreamBrowseCellForegroundView" owner:nil options:nil][0];

        _backgroundThumbnailView = [[UIImageView alloc] initWithFrame:subviewFrame];

        _parallaxView = [[STVParallaxView alloc] initWithFrame:subviewFrame];
        _parallaxView.delegate = self;
        [self addSubview:self.parallaxView];
        _parallaxView.foregroundContent = _foregroundView;
        //DS XXX TESTING
        _parallaxView.parallaxRatio = 0.5;
    }
    return self;
}

- (void)prepareForReuse
{
    self.backgroundThumbnailView.image = nil;
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
                                                                       self.backgroundThumbnailView.image = image;
                                                                       [self.backgroundThumbnailView sizeToFit];
                                                                       //DS XXX TESTING
                                                                       self.backgroundThumbnailView.frame = CGRectMake(0, 0, image.size.width * 2, image.size.height * 2);
                                                                       self.parallaxView.backgroundContent = self.backgroundThumbnailView;
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

- (void)matchParallaxOf:(STVParallaxView *)parallaxView
{
    if (parallaxView && parallaxView != self.parallaxView) {
        [self.parallaxView matchParallaxOf:parallaxView];
    }
}

#pragma mark - STVParallaxViewDelegate

- (void)parallaxDidChange:(STVParallaxView *)parallaxView
{
    [self.parallaxDelegate parallaxDidChange:parallaxView];
}

@end
