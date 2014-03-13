//
//  VideoPlayerThumbnailOverlayView.m
//  Shelby.tv
//
//  Created by Dan Spinosa on 1/31/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "VideoPlayerThumbnailOverlayView.h"
#import "AFNetworking.h"
#import "Video+Helper.h"

@interface VideoPlayerThumbnailOverlayView()
@property (weak, nonatomic) IBOutlet UIImageView *thumbnail;
@property (weak, nonatomic) IBOutlet UIImageView *playIcon;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@end

@implementation VideoPlayerThumbnailOverlayView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setVideo:(Video *)video
{
    if (_video != video) {
        _video = video;
        [self tryMaxResThumbnail];
    }
}

- (void)setImage:(UIImage *)image
{
    self.thumbnail.image = image;
    if (image == nil) {
        self.playIcon.hidden = YES;
    }
}

- (void)showSpinner:(BOOL)spinnerInsteadOfPlay
{
    if (spinnerInsteadOfPlay) {
        self.playIcon.hidden = YES;
        [self.spinner startAnimating];
    } else {
        self.playIcon.hidden = NO;
        [self.spinner stopAnimating];
    }
}

#pragma mark - Image Fetch Helpers

- (void)tryMaxResThumbnail
{
    Video *requestVideo = self.video;
    NSURLRequest *imageRequest = [NSURLRequest requestWithURL:[self.video maxResThumbnailURL]];
    [[AFImageRequestOperation imageRequestOperationWithRequest:imageRequest imageProcessingBlock:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        if (self.video == requestVideo) {
            [self setImage:image];
        }

    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        [self tryNormalThumbnail];
    }] start];
}

- (void)tryNormalThumbnail
{
    Video *requestVideo = self.video;
    NSURLRequest *imageRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:self.video.thumbnailURL]];
    [[AFImageRequestOperation imageRequestOperationWithRequest:imageRequest imageProcessingBlock:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        if (self.video == requestVideo) {
            [self setImage:image];
        }
        
    } failure:nil] start];
}

@end
