//
//  ShelbyStreamEntryCell.m
//  Shelby.tv
//
//  Created by Keren on 1/9/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyStreamEntryCell.h"
#import "Frame+Helper.h"
#import "UIImageView+AFNetworking.h"
#import "User+Helper.h"
#import "Video.h"
#import <QuartzCore/QuartzCore.h>

@interface ShelbyStreamEntryCell()
@property (nonatomic, weak) IBOutlet UILabel *username;
@property (nonatomic, weak) IBOutlet UILabel *videoTitle;
@property (nonatomic, weak) IBOutlet UIImageView *currentlyOn;
@property (nonatomic, weak) IBOutlet UIImageView *videoThumbnail;
@property (nonatomic, weak) IBOutlet UIImageView *userAvatar;
@property (nonatomic, weak) IBOutlet UILabel *description;
@property (nonatomic, weak) IBOutlet UILabel *detailNoLikersLabel;
@property (nonatomic, weak) IBOutlet UIView *likersView;
@property (nonatomic, weak) IBOutlet UIButton *likeButton;
@property (nonatomic, weak) IBOutlet UIButton *unlikeButton;
@property (nonatomic, weak) IBOutlet UIView *borderView;
@property (nonatomic, strong) NSMutableArray *likerImageViews;
@property (nonatomic, strong) NSMutableOrderedSet *likers;

- (IBAction)shareVideo:(id)sender;
- (IBAction)likeVideo:(id)sender;
- (IBAction)unLikeVideo:(id)sender;
- (IBAction)openUserProfile:(id)sender;
- (IBAction)openLikersView:(id)sender;
@end

@implementation ShelbyStreamEntryCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
    }
    return self;
}

- (void)awakeFromNib
{
    self.userAvatar.layer.cornerRadius = self.userAvatar.frame.size.height / 2;
    self.userAvatar.layer.masksToBounds = YES;
}

- (void)dealloc
{
    [_videoFrame removeObserver:self forKeyPath:kFramePathClientLikedAt];
}

- (void)prepareForReuse
{
    NSMutableArray *likerViews = [@[] mutableCopy];
    CGFloat likerX = 0.f;
    CGFloat likerSharerHeight = 26.f;
    UIImageView *likerImageView;
    //XXX TODO: the views should only be created once, not on each resuse
    for (int i = 0; i < 6; i++) {
        likerImageView = [[UIImageView alloc] initWithFrame:CGRectMake(likerX, 7, likerSharerHeight, likerSharerHeight)];
        [self.likersView addSubview:likerImageView];
        likerImageView.layer.cornerRadius = 3.0f;
        likerImageView.layer.masksToBounds = YES;
        [likerViews addObject:likerImageView];
        likerX += likerSharerHeight + 10;
        likerImageView.layer.cornerRadius = likerImageView.frame.size.height / 2;
        likerImageView.layer.masksToBounds = YES;
    }
    
    [self deselectStreamEntry];
    
    self.likerImageViews = likerViews;
}


- (void)setVideoFrame:(Frame *)videoFrame
{
    if (_videoFrame != videoFrame) {
        if (_videoFrame) {
            [_videoFrame removeObserver:self forKeyPath:kFramePathClientLikedAt];
        }
        _videoFrame = videoFrame;
        [_videoFrame addObserver:self forKeyPath:kFramePathClientLikedAt options:NSKeyValueObservingOptionNew context:nil];
        
        // KP KP - need to fetch upvoters from backend like we do on iphone
        // KP KP TODO- add/remove observer
        //    [self.videoFrame addObserver:self forKeyPath:@"upvoters" options:NSKeyValueObservingOptionNew context:nil];
        if ([self.videoFrame.upvoters count]) {
            [self processLikersAndSharers];
        }
        [self updateLikersAndSharersVisuals];
        
        NSString *nickname = nil;
        if (videoFrame.typeOfFrame == FrameTypeLightWeight) {
            nickname= [NSString stringWithFormat:@"%@ liked this", videoFrame.creator.nickname];
        } else {
            nickname = videoFrame.creator.nickname;
        }

        self.username.text = nickname;
        self.videoTitle.text = self.videoFrame.video.title;
        NSString *captionText = [videoFrame creatorsInitialCommentWithFallback:YES];
        self.description.text = captionText;
        NSURLRequest *thumbnailURLRequst = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:videoFrame.video.thumbnailURL]];
        
        __weak ShelbyStreamEntryCell *weakSelf = self;
        [self.videoThumbnail setImageWithURLRequest:thumbnailURLRequst placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
            weakSelf.videoThumbnail.image = image;
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
            
        }];
        
        NSURLRequest *avatarURLRequst = [[NSURLRequest alloc] initWithURL:[videoFrame.creator avatarURL]];
        [self.userAvatar setImageWithURLRequest:avatarURLRequst placeholderImage:[UIImage imageNamed:@"blank-avarar-med"] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
            weakSelf.userAvatar.image = image;
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
            
        }];
        
        [self updateViewForCurrentLikeStatus];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (object == self.videoFrame) {
        [self updateViewForCurrentLikeStatus];
    }
    
    //TODO: bring these back, I imagine...
    //XXX Be sure to remove observer in setVideoFrame: AND dealloc
//    [self processLikersAndSharers];
//    [self updateLikersAndSharersVisuals];
}

- (void)processLikersAndSharers
{
    if (!self.likers) {
        self.likers = [NSMutableOrderedSet new];
    } else {
        [self.likers removeAllObjects];
    }
    
    for (User *liker in self.videoFrame.upvoters) {
        [self.likers addObject:liker];
    }
}

- (void)updateLikersAndSharersVisuals
{
    for (UIImageView *iv in self.likerImageViews) {
        iv.image = nil;
    }
    
    if ([self.likers count]) {
        self.detailNoLikersLabel.hidden = YES;
        for (NSUInteger i = 0; i < MIN([self.likers count], [self.likerImageViews count]); i++) {
            User *liker = self.likers[i];
            [((UIImageView *)self.likerImageViews[i]) setImageWithURL:liker.avatarURL placeholderImage:[UIImage imageNamed:@"avatar-blank-small"]];
        }
    } else if ([self.videoFrame.video.trackedLikerCount intValue]) {
        self.detailNoLikersLabel.hidden = NO;
        self.detailNoLikersLabel.text = @"See all who liked this...";
    } else {
        self.detailNoLikersLabel.hidden = NO;
        self.detailNoLikersLabel.text = @"Be the first to like this!";
    }
}

- (IBAction)shareVideo:(id)sender
{
    [self.delegate shareVideoWasTappedForFrame:self.videoFrame];
}

- (IBAction)likeVideo:(id)sender
{
    [self.delegate likeFrame:self.videoFrame];
    [self updateViewForCurrentLikeStatus];
}

- (IBAction)unLikeVideo:(id)sender
{
    [self.delegate unLikeFrame:self.videoFrame];
    [self updateViewForCurrentLikeStatus];
}

- (IBAction)openUserProfile:(id)sender
{
    [self.delegate userProfileWasTapped:self.videoFrame.creator.userID];
}

- (IBAction)openLikersView:(id)sender
{
    [self.delegate openLikersViewForVideo:self.videoFrame.video withLikers:self.likers];
}

- (void)selectStreamEntry
{
    self.borderView.layer.borderColor = kShelbyColorGreen.CGColor;
    self.borderView.layer.borderWidth = 5;
    self.currentlyOn.hidden = NO;
}

- (void)deselectStreamEntry
{
    self.borderView.layer.borderWidth = 0;
    self.currentlyOn.hidden = YES;
}

#pragma mark - View Helpers

- (void)updateViewForCurrentLikeStatus
{
    BOOL isLiked = [self.videoFrame videoIsLiked];
    self.likeButton.hidden = isLiked;
    self.unlikeButton.hidden = !isLiked;
}

@end
