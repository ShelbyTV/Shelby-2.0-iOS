//
//  ShelbyStreamEntryCell.m
//  Shelby.tv
//
//  Created by Keren on 1/9/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyStreamEntryCell.h"
#import "DashboardEntry+Helper.h"
#import "Frame+Helper.h"
#import "ShelbyAnalyticsClient.h"
#import "UIImageView+AFNetworking.h"
#import "User+Helper.h"
#import "Video.h"
#import <QuartzCore/QuartzCore.h>

#define kShelbyStreamEntryCaptionMargin 0
#define kShelbyStreamEntryCaptionWidth 227

@interface ShelbyStreamEntryCell()
//data model
@property (nonatomic, strong) Frame *videoFrame;
@property (nonatomic, strong) DashboardEntry *dashboardEntry;

//views
@property (nonatomic, weak) IBOutlet UILabel *username;
@property (nonatomic, weak) IBOutlet UILabel *videoTitle;
@property (nonatomic, weak) IBOutlet UIImageView *currentlyOn;
@property (nonatomic, weak) IBOutlet UIImageView *videoThumbnail;
@property (nonatomic, weak) IBOutlet UIImageView *detailAvatarBadge;
@property (nonatomic, weak) IBOutlet UIImageView *userAvatar;
@property (nonatomic, weak) IBOutlet UILabel *detailNoLikersLabel;
@property (nonatomic, weak) IBOutlet UIView *likersView;
@property (nonatomic, weak) IBOutlet UIView *unLikersView;
@property (nonatomic, weak) IBOutlet UIView *bordersView;
@property (nonatomic, weak) IBOutlet UIView *leftVerticalBorder;
@property (nonatomic, weak) IBOutlet UIView *centerVerticalBorder;
@property (nonatomic, weak) IBOutlet UIView *rightVerticalBorder;
@property (nonatomic, weak) IBOutlet UIButton *likeButton;
@property (nonatomic, weak) IBOutlet UIButton *unlikeButton;
@property (nonatomic, weak) IBOutlet UIButton *fullWidthLikeButton;
@property (nonatomic, weak) IBOutlet UIButton *fullWidthUnlikeButton;
@property (nonatomic, weak) IBOutlet UIButton *fullWidthShareButton;
@property (nonatomic, weak) IBOutlet UIView *fullWidthButtonsContainer;
@property (nonatomic, weak) IBOutlet UIView *borderView;
@property (nonatomic, weak) IBOutlet UIView *imageBlockerView;
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
    
    //liker views
    NSMutableArray *likerViews = [@[] mutableCopy];
    CGFloat likerX = 0.f;
    CGFloat likerSharerHeight = 26.f;
    UIImageView *likerImageView;
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
    self.likerImageViews = likerViews;
}

- (void)dealloc
{
    [_videoFrame removeObserver:self forKeyPath:kFramePathClientLikedAt];
    [_videoFrame removeObserver:self forKeyPath:kFramePathUpvoters];
}

- (void)prepareForReuse
{
    [self deselectStreamEntry];
}

- (void)setDashboardEntry:(DashboardEntry *)dashboardEntry andFrame:(Frame *)videoFrame
{
    if (_videoFrame != videoFrame) {
        if (_videoFrame) {
            [_videoFrame removeObserver:self forKeyPath:kFramePathClientLikedAt];
            [_videoFrame removeObserver:self forKeyPath:kFramePathUpvoters];
        }
        _videoFrame = videoFrame;
        _dashboardEntry = dashboardEntry;
        [_videoFrame addObserver:self forKeyPath:kFramePathClientLikedAt options:NSKeyValueObservingOptionNew context:nil];
        [_videoFrame addObserver:self forKeyPath:kFramePathUpvoters options:NSKeyValueObservingOptionNew context:nil];
        
        [self processLikersAndSharers];
        [self updateLikersAndSharersVisuals];
        
        self.videoTitle.text = self.videoFrame.video.title;
        NSString *captionText = [videoFrame creatorsInitialCommentWithFallback:YES];
        self.description.text = captionText;
        NSURLRequest *thumbnailURLRequst = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:videoFrame.video.thumbnailURL]];
        
        NSInteger rand = arc4random() % 3;
        NSString *noThumbImageName = [NSString stringWithFormat:@"video-no-thumb-%d", rand];
        __weak ShelbyStreamEntryCell *weakSelf = self;
        [self.videoThumbnail setImageWithURLRequest:thumbnailURLRequst placeholderImage:[UIImage imageNamed:noThumbImageName] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
            weakSelf.videoThumbnail.image = image;
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
            
        }];
        
        NSURLRequest *avatarURLRequst = [[NSURLRequest alloc] initWithURL:[videoFrame.creator avatarURL]];
        [self.userAvatar setImageWithURLRequest:avatarURLRequst placeholderImage:[UIImage imageNamed:@"blank-avatar-med"] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
            weakSelf.userAvatar.image = image;
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
            
        }];
        
        [self updateViewForCurrentLikeStatus];
        
        NSString *nickname = nil;
        NSString *suppotingText = nil;
        if (videoFrame.typeOfFrame == FrameTypeLightWeight) {
            suppotingText = @"liked this";
        }
        
        nickname = videoFrame.creator.nickname;
        
        //avatar badge + via network
        UIImage *badgeImage = nil;
        NSString *viaNetwork = nil;
        if ([self.videoFrame typeOfFrame] == FrameTypeLightWeight) {
            badgeImage = [UIImage imageNamed:@"avatar-badge-heart"];
        } else if ([self.videoFrame.creator isNonShelbyFacebookUser]) {
            badgeImage = [UIImage imageNamed:@"avatar-badge-facebook"];
            viaNetwork = @"facebook";
        } else if ([self.videoFrame.creator isNonShelbyTwitterUser]) {
            badgeImage = [UIImage imageNamed:@"avatar-badge-twitter"];
            viaNetwork = @"twitter";
        } else {
            badgeImage = nil;
        }
        self.detailAvatarBadge.layer.cornerRadius = self.detailAvatarBadge.frame.size.height / 2;
        self.detailAvatarBadge.layer.masksToBounds = YES;
        self.detailAvatarBadge.image = badgeImage;
        
        self.detailAvatarBadge.image = badgeImage;
    
        // Via Network
        if (viaNetwork) {
            suppotingText = [NSString stringWithFormat:@"via %@", viaNetwork];
        }
        
        if (suppotingText) {
            self.username.attributedText = [self nicknameAttributedString:nickname withText:suppotingText];
        } else {
            self.username.text = nickname;
        }
    }
}

- (void)resizeCellAccordingToCaption
{
    NSInteger originalHeight = self.description.frame.size.height;
    NSString *captionText = [self.videoFrame creatorsInitialCommentWithFallback:YES];
    
    CGSize resizedCaption = [ShelbyStreamEntryCell sizeForCaptionWithText:captionText];
    
    NSInteger delta = resizedCaption.height - originalHeight;
    if (delta < 0) {
        self.description.frame = CGRectMake(self.description.frame.origin.x, self.description.frame.origin.y, self.description.frame.size.width, originalHeight + delta);
        self.bordersView.frame = CGRectMake(self.bordersView.frame.origin.x, self.bordersView.frame.origin.y + delta, self.bordersView.frame.size.width, self.bordersView.frame.size.height);
        self.likersView.frame = CGRectMake(self.likersView.frame.origin.x, self.likersView.frame.origin.y + delta, self.likersView.frame.size.width, self.likersView.frame.size.height);
        self.fullWidthButtonsContainer.frame = CGRectMake(self.fullWidthButtonsContainer.frame.origin.x, self.fullWidthButtonsContainer.frame.origin.y + delta, self.fullWidthButtonsContainer.frame.size.width, self.fullWidthButtonsContainer.frame.size.height);
        self.unLikersView.frame = CGRectMake(self.unLikersView.frame.origin.x, self.unLikersView.frame.origin.y + delta, self.unLikersView.frame.size.width, self.unLikersView.frame.size.height);
        self.borderView.frame = CGRectMake(self.borderView.frame.origin.x, self.borderView.frame.origin.y, self.borderView.frame.size.width, self.borderView.frame.size.height + delta);
        self.imageBlockerView.frame = CGRectMake(self.imageBlockerView.frame.origin.x, self.imageBlockerView.frame.origin.y, self.imageBlockerView.frame.size.width, self.imageBlockerView.frame.size.height + delta);
    }
}

+ (CGSize)sizeForCaptionWithText:(NSString *)captionText
{
    CGSize maxCaptionSize = CGSizeMake(kShelbyStreamEntryCaptionWidth - kShelbyStreamEntryCaptionMargin * 2, kShelbyStreamEntryCaptionHeight - kShelbyStreamEntryCaptionMargin * 2);
    CGFloat textBasedHeight = [captionText boundingRectWithSize:maxCaptionSize options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName : kShelbyBodyFont2} context:nil].size.height;
    
    return CGSizeMake(maxCaptionSize.width, ceil(textBasedHeight));
}

- (NSAttributedString *)nicknameAttributedString:(NSString *)username withText:(NSString *)text
{
    NSString *recoString = [NSString stringWithFormat:@"%@ %@", username, text];
    NSMutableAttributedString *recoAttributed = [[NSMutableAttributedString alloc] initWithString:recoString];
    [recoAttributed setAttributes:@{NSFontAttributeName: kShelbyBodyFont2Bold}
                            range:[recoString rangeOfString:username]];
    [recoAttributed setAttributes:@{NSFontAttributeName: kShelbyBodyFont2}
                            range:[recoString rangeOfString:text]];
    
    return recoAttributed;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (object == self.videoFrame) {
        [self updateViewForCurrentLikeStatus];
    }
    
    [self processLikersAndSharers];
    [self updateLikersAndSharersVisuals];
}

- (void)processLikersAndSharers
{
    self.likers = [NSMutableOrderedSet orderedSet];
    for (User *liker in self.videoFrame.upvoters) {
        [self.likers addObject:liker];
    }
    
    for (DashboardEntry *dupe in self.dashboardEntry.duplicates) {
        Frame *dupeFrame = dupe.frame;
        if (dupeFrame) {
            for (User *liker in dupe.frame.upvoters) {
                [_likers addObject:liker];
            }
        }
    }
}

- (void)updateLikersAndSharersVisuals
{
    for (UIImageView *iv in self.likerImageViews) {
        iv.image = nil;
    }
    
    if ([self.likers count]) {
        self.detailNoLikersLabel.hidden = YES;
        self.likersView.hidden = NO;
        self.leftVerticalBorder.hidden = NO;
        self.centerVerticalBorder.hidden = YES;
        self.rightVerticalBorder.hidden = NO;
        for (NSUInteger i = 0; i < MIN([self.likers count], [self.likerImageViews count]); i++) {
            User *liker = self.likers[i];
            [((UIImageView *)self.likerImageViews[i]) setImageWithURL:liker.avatarURL placeholderImage:[UIImage imageNamed:@"blank-avatar-small"]];
        }
        self.fullWidthButtonsContainer.hidden = YES;
    } else if ([self.videoFrame.video.trackedLikerCount intValue]) {
        self.detailNoLikersLabel.hidden = NO;
        self.likersView.hidden = NO;
        self.leftVerticalBorder.hidden = NO;
        self.centerVerticalBorder.hidden = YES;
        self.rightVerticalBorder.hidden = NO;
        self.detailNoLikersLabel.text = @"See all who liked this...";
        self.fullWidthButtonsContainer.hidden = YES;
    } else {
        self.leftVerticalBorder.hidden = YES;
        self.centerVerticalBorder.hidden = NO;
        self.rightVerticalBorder.hidden = YES;
        self.likersView.hidden = YES;
        self.detailNoLikersLabel.hidden = YES;
        self.fullWidthButtonsContainer.hidden = NO;
    }
}

- (IBAction)shareVideo:(id)sender
{
    [self.delegate shareVideoWasTappedForFrame:self.videoFrame];
}

- (IBAction)likeVideo:(id)sender
{
    [ShelbyAnalyticsClient sendLocalyticsEvent:kLocalyticsTapCardLike];
    [self.delegate likeFrame:self.videoFrame];
    [self updateViewForCurrentLikeStatus];
}

- (IBAction)unLikeVideo:(id)sender
{
    [ShelbyAnalyticsClient sendLocalyticsEvent:kLocalyticsTapCardUnlike];
    [self.delegate unLikeFrame:self.videoFrame];
    [self updateViewForCurrentLikeStatus];
}

- (IBAction)openUserProfile:(id)sender
{
    [ShelbyAnalyticsClient sendLocalyticsEvent:kLocalyticsTapCardSharingUser];
    [self.delegate userProfileWasTapped:self.videoFrame.creator.userID];
}

- (IBAction)openLikersView:(id)sender
{
    [ShelbyAnalyticsClient sendLocalyticsEvent:kLocalyticsTapCardLikersList];
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
    self.fullWidthLikeButton.hidden = isLiked;
    self.fullWidthUnlikeButton.hidden = !isLiked;
    self.likeButton.hidden = isLiked;
    self.unlikeButton.hidden = !isLiked;
}

@end
