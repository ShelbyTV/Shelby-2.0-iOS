//
//  VideoReelBackdropView.m
//  Shelby.tv
//
//  Created by Dan Spinosa on 1/16/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "VideoReelBackdropView.h"
#import "AFNetworking.h"
#import "GPUImage.h"
#import "Video+Helper.h"

@interface VideoReelBackdropView()
@property (nonatomic, strong) UIImageView *backdropOverlayImageView, *hiddenBackdropOverlayImageView;
@property (nonatomic, strong) GPUImageiOSBlurFilter *blurFilter;
@end

@implementation VideoReelBackdropView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    self.backgroundColor = [UIColor blackColor];
    
    //backdrop overlay views we swap with animation
    self.backdropOverlayImageView = [self setupBackdropOverlayImageView];
    self.hiddenBackdropOverlayImageView = [self setupBackdropOverlayImageView];
    self.hiddenBackdropOverlayImageView.alpha = 0.f;
    
    //blur filter
    self.blurFilter = [[GPUImageiOSBlurFilter alloc] init];
    self.blurFilter.saturation = 0.7;
    self.blurFilter.blurRadiusInPixels = 6.f;
    
    //represent current state, don't call setter
    _showBackdropImage = NO;
}

- (UIImageView *)setupBackdropOverlayImageView
{
    UIImageView *v = [UIImageView new];
    v.backgroundColor = [UIColor blackColor];
    v.alpha = 0.f;
    v.contentMode = UIViewContentModeScaleAspectFill;
    v.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:v];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(-100)-[v]-(-100)-|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:@{@"v":v}]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(-200)-[v]-(-200)-|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:@{@"v":v}]];
    
    return v;
}

- (void)setBackdropImageEntity:(id<ShelbyVideoContainer>)backdropImageEntity
{
    @synchronized(self){
        if (backdropImageEntity != _backdropImageEntity) {
            _backdropImageEntity = backdropImageEntity;
            [self tryMaxResThumbnailURLForEntry:_backdropImageEntity];
        }
    }
}

- (void)setShowBackdropImage:(BOOL)showBackdropImage
{
    @synchronized(self){
        if (showBackdropImage != _showBackdropImage) {
            _showBackdropImage = showBackdropImage;
            CGFloat backdropOverlayImageAlpha = _showBackdropImage ? 1.f : 0.f;
            [UIView animateWithDuration:0.5 animations:^{
                self.backdropOverlayImageView.alpha = backdropOverlayImageAlpha;
                self.hiddenBackdropOverlayImageView.alpha = 0.f;
            }];
        }
    }
}

#pragma mark - View Helpers

- (void)swapInBackdropImage:(UIImage *)image
{
    @synchronized(self){
        UIImage *blurredImage = [_blurFilter imageByFilteringImage:image];
        self.hiddenBackdropOverlayImageView.image = blurredImage;
        
        //swap views
        [UIView animateWithDuration:1.0f animations:^{
            self.hiddenBackdropOverlayImageView.alpha = _showBackdropImage ? 1.f : 0.f;
            self.backdropOverlayImageView.alpha = 0.f;
        } completion:^(BOOL finished) {
            UIImageView *nowHidden = self.backdropOverlayImageView;
            self.backdropOverlayImageView = self.hiddenBackdropOverlayImageView;
            self.hiddenBackdropOverlayImageView = nowHidden;
        }];
    }
}

#pragma mark - Get Thumbnails Helpers

- (void)tryMaxResThumbnailURLForEntry:(id<ShelbyVideoContainer>)entry
{
    NSURLRequest *imageRequest = [NSURLRequest requestWithURL:[[entry containedVideo] maxResThumbnailURL]];
    [[AFImageRequestOperation imageRequestOperationWithRequest:imageRequest imageProcessingBlock:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        if (self.backdropImageEntity == entry) {
            [self swapInBackdropImage:image];
        } else {
            //cell has been reused, do nothing
        }
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        if (self.backdropImageEntity == entry) {
            [self tryNormalThumbnailURLForEntry:entry];
        } else {
            //cell has been reused, do nothing
        }
    }] start];
}

- (void)tryNormalThumbnailURLForEntry:(id<ShelbyVideoContainer>)entry
{
    NSURLRequest *imageRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:[entry containedVideo].thumbnailURL]];
    [[AFImageRequestOperation imageRequestOperationWithRequest:imageRequest imageProcessingBlock:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        if (self.backdropImageEntity == entry) {
            [self swapInBackdropImage:image];
        } else {
            //cell has been reused, do nothing
        }
    } failure:nil] start];
}

@end
