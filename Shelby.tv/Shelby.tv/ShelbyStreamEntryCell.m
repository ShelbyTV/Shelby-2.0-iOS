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
#import "ShelbyDataMediator.h"
#import <QuartzCore/QuartzCore.h>

@interface ShelbyStreamEntryCell()
//data model
@property (nonatomic, strong) Frame *videoFrame;
@property (nonatomic, strong) DashboardEntry *dashboardEntry;

//views
@property (nonatomic, weak) IBOutlet UILabel *username;
@property (nonatomic, weak) IBOutlet UILabel *videoTitle;
@property (nonatomic, weak) IBOutlet UILabel *bodyLabel;
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
        self.bodyLabel.text = [[self class] captionTextForDashboardEntry:_dashboardEntry
                                                                andFrame:_videoFrame];
        
        NSURLRequest *thumbnailURLRequst = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:videoFrame.video.thumbnailURL]];
        NSString *noThumbImageName = [NSString stringWithFormat:@"video-no-thumb-%d", arc4random_uniform(3)];
        [self.videoThumbnail setImageWithURLRequest:thumbnailURLRequst placeholderImage:[UIImage imageNamed:noThumbImageName] success:nil failure:nil];
        
        if ([_dashboardEntry recommendedEntry]) {
            self.userAvatar.image = [UIImage imageNamed:@"recommendation-avatar"];
        } else {
            NSURLRequest *avatarURLRequst = [[NSURLRequest alloc] initWithURL:[videoFrame.creator avatarURL]];
            [self.userAvatar setImageWithURLRequest:avatarURLRequst placeholderImage:[UIImage imageNamed:@"blank-avatar-med"] success:nil failure:nil];
        }
        
        [self updateHeartViewForCurrentLikeStatus];
        
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
            viaNetwork = @"Facebook";
        } else if ([self.videoFrame.creator isNonShelbyTwitterUser]) {
            badgeImage = [UIImage imageNamed:@"avatar-badge-twitter"];
            viaNetwork = @"Twitter";
        } else {
            badgeImage = nil;
        }
        self.detailAvatarBadge.layer.cornerRadius = self.detailAvatarBadge.frame.size.height / 2;
        self.detailAvatarBadge.layer.masksToBounds = YES;
        self.detailAvatarBadge.image = badgeImage;
        
        self.detailAvatarBadge.image = badgeImage;
    
        //username
        if ([_dashboardEntry recommendedEntry]) {
            self.username.attributedText = [[NSAttributedString alloc] initWithString:@"Recommended for you"
                                                                           attributes:@{NSForegroundColorAttributeName: kShelbyColorGreen}];
            
        } else {
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
    [self processLikersAndSharers];
    [self updateLikersAndSharersVisuals];
    [self updateHeartViewForCurrentLikeStatus];
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

    User *user = [[ShelbyDataMediator sharedInstance] fetchAuthenticatedUserOnMainThreadContext];;
    [ShelbyAnalyticsClient sendLocalyticsEvent:kLocalyticsEventNameVideoShareStart
                                withAttributes:@{
                                                 kLocalyticsAttributeNameFromOrigin : kLocalyticsAttributeValueFromOriginVideoCard,
                                                 kLocalyticsAttributeNameUserType : [user userTypeStringForAnalytics]
                                                 }];
}

- (IBAction)likeVideo:(id)sender
{
    User *user = [[ShelbyDataMediator sharedInstance] fetchAuthenticatedUserOnMainThreadContext];
    [ShelbyAnalyticsClient sendLocalyticsEvent:kLocalyticsEventNameVideoLike
                                withAttributes:@{
                                                 kLocalyticsAttributeNameFromOrigin : kLocalyticsAttributeValueFromOriginVideoCard,
                                                 kLocalyticsAttributeNameUserType : [user userTypeStringForAnalytics]
                                                 }];

    [self.delegate likeFrame:self.videoFrame];
}

- (IBAction)unLikeVideo:(id)sender
{
    User *user = [[ShelbyDataMediator sharedInstance] fetchAuthenticatedUserOnMainThreadContext];
    [ShelbyAnalyticsClient sendLocalyticsEvent:kLocalyticsEventNameVideoUnlike
                                withAttributes:@{
                                                 kLocalyticsAttributeNameFromOrigin : kLocalyticsAttributeValueFromOriginVideoCard,
                                                 kLocalyticsAttributeNameUserType : [user userTypeStringForAnalytics]
                                                 }];

    [self.delegate unLikeFrame:self.videoFrame];
}

- (IBAction)openUserProfile:(id)sender
{
    if ([self.dashboardEntry recommendedEntry]) {
        //there is no profile
        return;
    }
    [self.delegate userProfileWasTapped:self.videoFrame.creator.userID];

    [ShelbyAnalyticsClient sendLocalyticsEvent:kLocalyticsEventNameUserProfileView
                                withAttributes:@{
                                                 kLocalyticsAttributeNameFromOrigin : kLocalyticsAttributeValueFromOriginVideoCardOwner,
                                                 kLocalyticsAttributeNameUsername : self.videoFrame.creator.nickname ?: @"unknown"
                                                 }];
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

#pragma mark - Helpers

- (void)updateHeartViewForCurrentLikeStatus
{
    BOOL isLiked = [self.videoFrame videoIsLikedBy:self.currentUser];
    self.fullWidthLikeButton.hidden = isLiked;
    self.fullWidthUnlikeButton.hidden = !isLiked;
    self.likeButton.hidden = isLiked;
    self.unlikeButton.hidden = !isLiked;
}

// NB: We use autolayout when actually displaying the cell.  We could use that here to get the
// height we will ultimatley be displayed at.  But that's slow.  Since only one area changes size
// (the description) we just determine the height of that area and add it to a constant to determine
// the final actual height (which will be equal to height as determined by doing a full autolayout).
+ (CGFloat)heightWithDashboardEntry:(DashboardEntry *)dashboardEntry andFrame:(Frame *)videoFrame
{
    static ShelbyStreamEntryCell *prototypeRegularShareCell;
    static CGSize maxLabelSize;
    static NSStringDrawingOptions drawingOptions;
    static dispatch_once_t onceToken;
    static NSDictionary *attrs;
    dispatch_once(&onceToken, ^{
        prototypeRegularShareCell = [[[NSBundle mainBundle] loadNibNamed:@"ShelbyStreamEntryCellView" owner:nil options:nil] firstObject];
        maxLabelSize = prototypeRegularShareCell.bodyLabel.bounds.size;
        drawingOptions = (NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingTruncatesLastVisibleLine);
        attrs = @{NSFontAttributeName: prototypeRegularShareCell.bodyLabel.font};
    });
    
    if ([videoFrame typeOfFrame] == FrameTypeLightWeight) {
        // ------ lightweight share (aka "like")  ---------
        //"thumbnailSection" height in xib: 150
        //"sharerSection" height in xib: >= 60 (sits at 60 for this type b/c there's no body text)
        //"actionSection" height in xib: 50
        //"bottom border" height in xib: 10
        return 270.f;
        
    } else {
        // ------ regular share & recommendations ---------
        //height with full text: 340
        //height of full text: 82
        //height if there was no text: (340 - 82) = 258
        NSString *bodyCopy = [[self class] captionTextForDashboardEntry:dashboardEntry andFrame:videoFrame];
        CGRect textBoundingRect = [bodyCopy boundingRectWithSize:maxLabelSize options:drawingOptions attributes:attrs context:nil];
        return 258.0f + ceil(textBoundingRect.size.height);
    }
}

+ (NSString *)captionTextForDashboardEntry:(DashboardEntry *)dbe andFrame:(Frame *)videoFrame
{
    if ([dbe recommendedEntry]) {
        if (dbe.sourceFrameCreatorNickname) {
            NSString *recoBase = @"This video is Liked by people like ";
            NSString *recoUsername = dbe.sourceFrameCreatorNickname;
            return [NSString stringWithFormat:@"%@%@", recoBase, recoUsername];
        } else if (dbe.sourceVideoTitle) {
            return [NSString stringWithFormat:@"Because you Liked \"%@\"", dbe.sourceVideoTitle];
        } else {
            return @"We thought you'd like to see this";
        }
        
    } else {
        return [videoFrame creatorsInitialCommentWithFallback:YES];
    }
}

@end
