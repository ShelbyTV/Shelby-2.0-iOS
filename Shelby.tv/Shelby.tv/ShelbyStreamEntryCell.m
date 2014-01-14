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

@interface ShelbyStreamEntryCell()
@property (nonatomic, weak) IBOutlet UILabel *videoTitle;
@property (nonatomic, weak) IBOutlet UIImageView *videoThumbnail;
@property (nonatomic, weak) IBOutlet UIImageView *userAvatar;
@property (nonatomic, weak) IBOutlet UILabel *description;
@property (nonatomic, weak) IBOutlet UIView *likersView;
@property (nonatomic, strong) NSMutableArray *likerImageViews;
@property (nonatomic, strong) NSMutableOrderedSet *likers;

- (IBAction)shareVideo:(id)sender;
- (IBAction)toggleLike:(id)sender;
- (IBAction)openUserProfile:(id)sender;
@end

@implementation ShelbyStreamEntryCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
    }
    return self;
}


- (void)prepareForReuse
{
    NSMutableArray *likerViews = [@[] mutableCopy];
    CGFloat likerX = 0.f;
    CGFloat likerSharerHeight = 30.f;
    UIImageView *likerImageView;
    for (int i = 0; i < 6; i++) {
        likerImageView = [[UIImageView alloc] initWithFrame:CGRectMake(likerX, 5, likerSharerHeight, likerSharerHeight)];
        [self.likersView addSubview:likerImageView];
        likerImageView.layer.cornerRadius = 3.0f;
        likerImageView.layer.masksToBounds = YES;
        [likerViews addObject:likerImageView];
        likerX += likerSharerHeight + 10;
    }
    
    self.likerImageViews = likerViews;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setVideoFrame:(Frame *)videoFrame
{
    _videoFrame = videoFrame;

    // KP KP - need to fetch upvoters from backend like we do on iphone
    // KP KP TODO- add/remove observer
//    [self.videoFrame addObserver:self forKeyPath:@"upvoters" options:NSKeyValueObservingOptionNew context:nil];
    if ([self.videoFrame.upvoters count]) {
        [self processLikersAndSharers];
        
        [self updateLikersAndSharersVisuals];
    }
    
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
    [self.userAvatar setImageWithURLRequest:avatarURLRequst placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        weakSelf.userAvatar.image = image;
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        
    }];
}

//- (void)observeValueForKeyPath:(NSString *)keyPath
//                      ofObject:(id)object
//                        change:(NSDictionary *)change
//                       context:(void *)context
//{
//    [self processLikersAndSharers];
//    
//    [self updateLikersAndSharersVisuals];
//}

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
        //        self.detailNoLikersLabel.hidden = YES;
        for (NSUInteger i = 0; i < MIN([self.likers count], [self.likerImageViews count]); i++) {
            User *liker = self.likers[i];
            [((UIImageView *)self.likerImageViews[i]) setImageWithURL:liker.avatarURL placeholderImage:[UIImage imageNamed:@"avatar-blank"]];
        }
    } else if ([self.videoFrame.video.trackedLikerCount intValue]) {
        //        self.detailNoLikersLabel.hidden = NO;
        //        self.detailNoLikersLabel.text = @"See all who liked this...";
    } else {
        //        self.detailNoLikersLabel.hidden = NO;
        //        self.detailNoLikersLabel.text = @"Be the first to like this!";
    }

}

- (IBAction)shareVideo:(id)sender
{
    [self.delegate shareVideoWasTappedForFrame:self.videoFrame];
}

- (IBAction)toggleLike:(id)sender
{
    [self.delegate toggleLikeForFrame:self.videoFrame];
}

- (IBAction)openUserProfile:(id)sender
{
    [self.delegate userProfileWasTapped:self.videoFrame.creator.userID];
}


@end
