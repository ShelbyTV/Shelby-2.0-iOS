//
//  StreamBrowseCellForegroundView.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 6/24/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "StreamBrowseCellForegroundView.h"
#import "DashboardEntry+Helper.h"
#import "DeviceUtilities.h"
#import "ShelbyHomeViewController.h"
#import "NSDate+Extension.h"
#import "Video+Helper.h"
#import "UIImageView+AFNetworking.h"
#import "User+Helper.h"
#import "ShelbyDataMediator.h"

#define kShelbyInfoViewMargin 15
#define kShelbyCaptionMargin 4

@interface  StreamBrowseCellForegroundView() {
    NSMutableOrderedSet *_likers;
    NSArray *_likerImageViews;
}
//model
@property (strong, nonatomic) DashboardEntry *dashboardEntry;
@property (strong, nonatomic) Frame *videoFrame;

// Detail View Outlets
@property (weak, nonatomic) IBOutlet UILabel *detailCaption;
@property (weak, nonatomic) IBOutlet UIView *detailCommentView;
@property (weak, nonatomic) IBOutlet UILabel *detailCreatedAt;
@property (weak, nonatomic) IBOutlet UIButton *detailInviteFacebookFriends;
@property (weak, nonatomic) IBOutlet UIButton *shareButton;
@property (strong, nonatomic) UIActivityIndicatorView *shareActivityIndicator;
@property (weak, nonatomic) IBOutlet UIView *detailLikersAndSharers;
@property (strong, nonatomic) UIView *detailLikersAndSharersTopBorder;
@property (weak, nonatomic) IBOutlet UIButton *likersButton;
@property (weak, nonatomic) IBOutlet UIView *detailLikersSubview;
@property (weak, nonatomic) IBOutlet UILabel *detailNoLikersLabel;
@property (weak, nonatomic) IBOutlet UILabel *detailTitle;
@property (weak, nonatomic) IBOutlet UIButton *detailTitleButton;
@property (weak, nonatomic) IBOutlet UIImageView *detailUserAvatar;
@property (weak, nonatomic) IBOutlet UIImageView *detailAvatarBadge;
@property (weak, nonatomic) IBOutlet UILabel *detailUsername;
@property (weak, nonatomic) IBOutlet UIView *detailUserView;
@property (weak, nonatomic) IBOutlet UILabel *detailViaNetwork;
@property (weak, nonatomic) IBOutlet UIView *detailWhiteBackground;
@property (weak, nonatomic) IBOutlet UIView *detailRecommendationView;
@property (weak, nonatomic) IBOutlet UILabel *detailRecommendationReasonLabel;

// Summary View Outlets
@property (weak, nonatomic) IBOutlet UILabel *summaryTitle;
@property (weak, nonatomic) IBOutlet UIButton *summaryTitleButton;
@property (nonatomic, weak) IBOutlet UIImageView *summaryUserAvatar;
@property (weak, nonatomic) IBOutlet UIImageView *summaryAvatarBadge;
@property (weak, nonatomic) IBOutlet UILabel *summaryUsername;
@property (weak, nonatomic) IBOutlet UIView *summaryUserView;
@property (weak, nonatomic) IBOutlet UILabel *summaryViaNetwork;
@property (weak, nonatomic) IBOutlet UIView *summaryRecommendationView;

@property (nonatomic, strong) NSString *userID;

//overlay below everything
@property (nonatomic, strong) UIImageView *overlayImageView;

- (IBAction)playVideoInCell:(id)sender;
- (IBAction)sendFacebookRequest:(id)sender;
- (IBAction)goToUserProfile:(id)sender;
- (IBAction)shareVideo:(id)sender;
- (IBAction)openLikersView:(id)sender;
@end

@implementation StreamBrowseCellForegroundView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)dealloc
{
    [self.videoFrame removeObserver:self forKeyPath:@"upvoters"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)awakeFromNib
{
    [super awakeFromNib];

    self.summaryTitle.font = kShelbyFontH2;
    self.detailTitle.font = kShelbyFontH4Bold;
    
    self.detailUserAvatar.layer.cornerRadius = CGRectGetWidth(self.detailUserAvatar.bounds)/2.f;
    self.detailUserAvatar.layer.masksToBounds = YES;
    self.detailAvatarBadge.layer.cornerRadius = CGRectGetWidth(self.detailAvatarBadge.bounds)/2.f;
    self.detailAvatarBadge.layer.masksToBounds = YES;
    self.summaryUserAvatar.layer.cornerRadius = CGRectGetWidth(self.summaryUserAvatar.bounds)/2.f;
    self.summaryUserAvatar.layer.masksToBounds = YES;
    self.summaryAvatarBadge.layer.cornerRadius = CGRectGetWidth(self.summaryAvatarBadge.bounds)/2.f;
    self.summaryAvatarBadge.layer.masksToBounds = YES;


    [self setupOverlayImageView];
    [self insertSubview:self.overlayImageView atIndex:0];

    [self setupLikersAndSharersSubviews];

    //white layer with alpha for iOS6 & 7
    //the toolbar blur hack isn't great, it's just doing a static image swaparoo
    self.detailWhiteBackground.alpha = 0.85;
    self.detailWhiteBackground.backgroundColor = [UIColor whiteColor];

    if ([DeviceUtilities isGTEiOS7]) {
        //a horizontal motion effect doesn't play very nicely w/ the parallax sliding, so we just do vertical
        UIInterpolatingMotionEffect *motionEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
        motionEffect.minimumRelativeValue = kShelbyMotionForegroundYMin;
        motionEffect.maximumRelativeValue = kShelbyMotionForegroundYMax;
        [self addMotionEffect:motionEffect];
    }
    
    self.detailLikersAndSharersTopBorder = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.detailLikersAndSharers.frame.size.width, 1)];
    self.detailLikersAndSharersTopBorder.backgroundColor = kShelbyColorLightGray;
    [self.detailLikersAndSharers addSubview:self.detailLikersAndSharersTopBorder];
    
    UIView *shareButtonLeftBorder = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, self.shareButton.frame.size.height)];
    shareButtonLeftBorder.backgroundColor = kShelbyColorLightGray;
    [self.shareButton addSubview:shareButtonLeftBorder];
    
    self.detailNoLikersLabel.hidden = YES;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    [self processLikersAndSharers];
    
    [self updateLikersAndSharersVisuals];
}

    
- (void)setupLikersAndSharersSubviews
{
    NSMutableArray *likerViews = [@[] mutableCopy];
    CGFloat likerX = 40.f;
    CGFloat likerSharerHeight = 30.f;
    UIImageView *likerImageView;
    for (int i = 0; i < 6; i++) {
        likerImageView = [[UIImageView alloc] initWithFrame:CGRectMake(likerX, 5, likerSharerHeight, likerSharerHeight)];
        [self.detailLikersSubview addSubview:likerImageView];
        likerImageView.layer.cornerRadius = CGRectGetWidth(likerImageView.bounds)/2.f;
        likerImageView.layer.masksToBounds = YES;
        [likerViews addObject:likerImageView];
        likerX += likerSharerHeight + 10;
    }

    _likerImageViews = likerViews;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    NSInteger pageWidth = self.frame.size.width / 2;
//    NSInteger pageHeight = self.frame.size.height;
    NSInteger xOrigin = pageWidth + kShelbyInfoViewMargin;
  
    if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
        // Landscape
        // Summary View
        self.summaryTitle.frame = CGRectMake(kShelbyInfoViewMargin, 50, pageWidth - kShelbyInfoViewMargin * 2, 90);
        self.summaryUserView.frame = CGRectMake(self.summaryUserView.frame.origin.x, self.summaryTitle.frame.origin.y + self.summaryTitle.frame.size.height - 10, self.summaryTitle.frame.size.width, self.summaryUserView.frame.size.height);
        self.summaryRecommendationView.frame = self.summaryUserView.frame;

        // Detail View
        self.detailCreatedAt.frame = CGRectMake(xOrigin, 45, pageWidth - kShelbyInfoViewMargin * 2, 22);
        self.detailTitle.frame = CGRectMake(xOrigin, 65, pageWidth - kShelbyInfoViewMargin * 2, 22);
        self.detailWhiteBackground.frame = CGRectMake(xOrigin - kShelbyInfoViewMargin, 90, pageWidth, 140);
        self.detailUserView.frame = CGRectMake(xOrigin - kShelbyInfoViewMargin, 95, 185, 60);
        self.detailUsername.frame = CGRectMake(self.detailUsername.frame.origin.x, self.detailUsername.frame.origin.y, 200, self.detailUsername.frame.size.height);
        self.detailCommentView.frame = CGRectMake(xOrigin, 155, pageWidth - kShelbyInfoViewMargin * 2, 60);
        self.detailRecommendationView.frame = self.detailWhiteBackground.frame;
    } else {
        // Portrait
        // Summary View
        self.summaryTitle.frame = CGRectMake(kShelbyInfoViewMargin, 64, 280, 120);
        self.summaryUserView.frame = CGRectMake(self.summaryUserView.frame.origin.x, self.summaryTitle.frame.origin.y + self.summaryTitle.frame.size.height, self.summaryTitle.frame.size.width, self.summaryUserView.frame.size.height);
        self.summaryRecommendationView.frame = self.summaryUserView.frame;

        // Detail View
        self.detailCreatedAt.frame = CGRectMake(xOrigin, 60, pageWidth - kShelbyInfoViewMargin * 2, 22);
        self.detailTitle.frame = CGRectMake(xOrigin, 80, 280, 44);
        self.detailWhiteBackground.frame = CGRectMake(xOrigin - kShelbyInfoViewMargin, 130, pageWidth, 200);
        self.detailUserView.frame = CGRectMake(pageWidth, 120, 320, 60);
        self.detailUsername.frame = CGRectMake(self.detailUsername.frame.origin.x, self.detailUsername.frame.origin.y, 215, self.detailUsername.frame.size.height);
        self.detailCommentView.frame = CGRectMake(xOrigin, 165, pageWidth - kShelbyInfoViewMargin * 2, 100);
        self.detailRecommendationView.frame = self.detailWhiteBackground.frame;
    }
    
    self.summaryPlayImageView.frame = CGRectMake(self.frame.size.width/4 - self.summaryPlayImageView.frame.size.width/2, self.frame.size.height/2 - self.summaryPlayImageView.frame.size.height/2, self.summaryPlayImageView.frame.size.width, self.summaryPlayImageView.frame.size.height);
    
    self.detailViaNetwork.frame = CGRectMake(self.detailViaNetwork.frame.origin.x, self.detailViaNetwork.frame.origin.y, self.detailUsername.frame.size.width, self.detailViaNetwork.frame.size.height);

    self.detailInviteFacebookFriends.frame = CGRectMake(self.detailViaNetwork.frame.origin.x, self.detailInviteFacebookFriends.frame.origin.y, self.detailInviteFacebookFriends.frame.size.width, self.detailInviteFacebookFriends.frame.size.height);
    self.summaryTitleButton.frame = self.summaryTitle.frame;
    self.detailTitleButton.frame = self.detailTitle.frame;

    [self resizeViewsForContent];
    self.shareButton.frame = CGRectMake(self.detailLikersAndSharers.frame.size.width - 60, 0, 50, self.detailLikersAndSharers.frame.size.height);
    
    [self setupOverlayImageView];
}

- (void)setInfoForDashboardEntry:(DashboardEntry *)dashboardEntry frame:(Frame *)videoFrame
{
    // Making sure we don't have an observer pointing at a dangling object
    [self.videoFrame removeObserver:self forKeyPath:@"upvoters"];

    // Making sure we remove observer if previous cell was in the middle of share
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.shareActivityIndicator.hidden = YES;
    self.shareButton.hidden = NO;
    [self.shareButton setImage:[UIImage imageNamed:@"share-icon"] forState:UIControlStateNormal];
    
    _dashboardEntry = dashboardEntry;
    _videoFrame = videoFrame;

    [self updateVisualsForRecommendation];
    [self processLikersAndSharers];
    [self updateStandardVisuals];
    
    [self.videoFrame addObserver:self forKeyPath:@"upvoters" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)updateStandardVisuals
{
    // createdAt
    if (_dashboardEntry) {
        self.detailCreatedAt.text = [[NSDate dateFromBSONObjectID:_dashboardEntry.shelbyID] prettyRelativeTime];
    } else {
        self.detailCreatedAt.text = [[NSDate dateFromBSONObjectID:_videoFrame.shelbyID] prettyRelativeTime];
    }

    //title
    self.summaryTitle.text = _videoFrame.video.title;
    self.detailTitle.text = _videoFrame.video.title;
    
    // Username
    NSAttributedString *usernameString = [self usernameStringFor:_videoFrame];
    self.summaryUsername.attributedText = usernameString;
    self.detailUsername.attributedText = usernameString;
    
    // User ID
    self.userID = _videoFrame.creator.userID;
    
    // User Avatar
    // Request setup was taken from UIImage+AFNetworking. As we have to set a completion block so the detail avatar will be the same as the summary one. (Otherwise, we had to make 2 seperate calls)
    NSURL *url = [_videoFrame.creator avatarURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPShouldHandleCookies:NO];
    [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];

    __weak StreamBrowseCellForegroundView *weakSelf = self;
    
    UIImage *defaultAvatar = [UIImage imageNamed:@"avatar-blank.png"];
    self.detailUserAvatar.image = defaultAvatar;
    [self.summaryUserAvatar setImageWithURLRequest:request placeholderImage:defaultAvatar success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        weakSelf.summaryUserAvatar.image = image;
        weakSelf.detailUserAvatar.image = image;
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        //ignore for now
    }];
    
    //avatar badge + via network
    UIImage *badgeImage;
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
    self.summaryAvatarBadge.image = badgeImage;
    self.detailAvatarBadge.image = badgeImage;
    
    // Via Network
    if (viaNetwork) {
        viaNetwork = [NSString stringWithFormat:@"via %@", viaNetwork];
    }
    
    self.summaryViaNetwork.text = viaNetwork;
    self.detailViaNetwork.text = self.summaryViaNetwork.text;
    
    // If the creator is not a shelby user but is a facebook user, show invite
    if ([self.videoFrame.creator isNonShelbyFacebookUser]) {
        self.detailInviteFacebookFriends.hidden = NO;
        self.detailViaNetwork.hidden = YES;
    } else {
        self.detailInviteFacebookFriends.hidden = YES;
        self.detailViaNetwork.hidden = NO;
    }
    
    // Caption
    NSString *captionText = [_videoFrame creatorsInitialCommentWithFallback:YES];
    [self.detailCaption setText:captionText];
    [self resizeViewsForContent];

    [self updateLikersAndSharersVisuals];

}

- (void)updateLikersAndSharersVisuals
{
    // Likers
    for (UIImageView *iv in _likerImageViews) {
        iv.image = nil;
    }
    if ([_likers count]) {
        self.detailNoLikersLabel.hidden = YES;
        for (NSUInteger i = 0; i < MIN([_likers count], [_likerImageViews count]); i++) {
            User *liker = _likers[i];
            [((UIImageView *)_likerImageViews[i]) setImageWithURL:liker.avatarURL placeholderImage:[UIImage imageNamed:@"avatar-blank"]];
        }
    } else if ([self.videoFrame.video.trackedLikerCount intValue]) {
        self.detailNoLikersLabel.hidden = NO;
        self.detailNoLikersLabel.text = @"See all who liked this...";
    } else {
        self.detailNoLikersLabel.hidden = NO;
        self.detailNoLikersLabel.text = @"Be the first to like this!";
    }
}

- (void)resizeViewsForContent
{
    //padding adjustments for landscape vs portrait
    CGFloat summaryUserPadding, detailTitlePadding, detailCommentPadding, detailUserPadding;
    NSInteger detailTitleHeight;
    if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
        summaryUserPadding = 50;
        detailTitlePadding = 70;
        detailUserPadding = 0;
        detailCommentPadding = 60;
        detailTitleHeight = 22;
    } else {
        summaryUserPadding = 70;
        detailTitlePadding = 90;
        detailUserPadding = 0;
        detailCommentPadding = 60;
        detailTitleHeight = 44;
    }


    //-----------summary page---------------
    //resize summary title
    NSString *summaryTitleText = self.summaryTitle.text;
    CGSize maxSummaryTitleSize = CGSizeMake(self.summaryTitle.frame.size.width, self.summaryTitle.frame.size.height);
    CGFloat summaryTitleDesiredHeight = [summaryTitleText boundingRectWithSize:maxSummaryTitleSize options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:self.summaryTitle.font} context:nil].size.height;
    self.summaryTitle.frame = CGRectMake(self.summaryTitle.frame.origin.x, self.summaryTitle.frame.origin.y, self.summaryTitle.frame.size.width, summaryTitleDesiredHeight);

    //move the user + recommendation views just below the title
    self.summaryUserView.frame = CGRectMake(self.summaryUserView.frame.origin.x, summaryTitleDesiredHeight + summaryUserPadding, self.summaryUserView.frame.size.width, self.summaryUserView.frame.size.height);
    self.summaryRecommendationView.frame = self.summaryUserView.frame;


    //-----------detail page---------------
    //resize detail title
    NSString *detailTitleText = self.detailTitle.text;
    CGSize maxDetailTitleSize = CGSizeMake(self.detailTitle.frame.size.width, detailTitleHeight);
    CGFloat detailTitleDesiredHeight = [detailTitleText boundingRectWithSize:maxDetailTitleSize options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName : self.detailTitle.font} context:nil].size.height;
    self.detailTitle.frame = CGRectMake(self.detailTitle.frame.origin.x, self.detailTitle.frame.origin.y, self.detailTitle.frame.size.width, detailTitleDesiredHeight);

    //move the detail user view, caption holder, and white background up underneath the title
    CGFloat yUnderDetailTitle = detailTitleDesiredHeight + detailTitlePadding;
    self.detailUserView.frame = CGRectMake(self.detailUserView.frame.origin.x, yUnderDetailTitle + detailUserPadding, self.detailUserView.frame.size.width, self.detailUserView.frame.size.height);
    self.detailCommentView.frame = CGRectMake(self.detailCommentView.frame.origin.x, yUnderDetailTitle + detailCommentPadding, self.detailCommentView.frame.size.width, self.detailCommentView.frame.size.height);
    self.detailWhiteBackground.frame = CGRectMake(self.detailWhiteBackground.frame.origin.x, yUnderDetailTitle, self.detailWhiteBackground.frame.size.width, self.detailWhiteBackground.frame.size.height + self.detailCommentView.frame.size.height);

    //resize detail caption
    NSString *captionText = self.detailCaption.text;
    
    CGSize maxCaptionSize = CGSizeMake(self.detailCommentView.frame.size.width - kShelbyCaptionMargin * 2, self.detailCommentView.frame.size.height - kShelbyCaptionMargin * 2);
    CGFloat textBasedHeight = [captionText boundingRectWithSize:maxCaptionSize options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName : self.detailCaption.font} context:nil].size.height;
     self.detailCaption.frame = CGRectMake(self.detailCaption.frame.origin.x,
                                          0,
                                          maxCaptionSize.width,
                                          ceil(textBasedHeight));


    NSInteger padding = 10;
    //update likers and sharers based on the white background box
    self.detailLikersAndSharers.frame = CGRectMake(self.detailWhiteBackground.frame.origin.x, self.detailCommentView.frame.origin.y + self.detailCaption.frame.size.height + padding, self.detailWhiteBackground.frame.size.width, self.detailLikersAndSharers.frame.size.height);
    self.detailLikersSubview.frame = CGRectMake(0, 5, self.detailLikersAndSharers.frame.size.width - 70, self.detailLikersAndSharers.frame.size.height);
    self.likersButton.frame = self.detailLikersSubview.frame;
    
    self.detailLikersAndSharersTopBorder.frame = CGRectMake(0, 0, self.detailLikersAndSharers.frame.size.width, 1);
    
    //tighting up the height of surrounding box as well
    self.detailWhiteBackground.frame = CGRectMake(self.detailWhiteBackground.frame.origin.x, self.detailWhiteBackground.frame.origin.y, self.detailWhiteBackground.frame.size.width, self.detailCaption.frame.size.height + self.detailUserView.frame.size.height + self.detailLikersAndSharers.frame.size.height + padding);

    //recommendation view
    self.detailRecommendationView.frame = self.detailWhiteBackground.frame;
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

    UIImage *overlayImage = [[UIImage imageNamed:imageName] resizableImageWithCapInsets:UIEdgeInsetsMake(1, 0, 1, 0)
                                                                           resizingMode:UIImageResizingModeStretch];

    if (!self.overlayImageView) {
        self.overlayImageView = [[UIImageView alloc] initWithImage:overlayImage];
    } else {
        self.overlayImageView.image = overlayImage;
    }

    //extend the overlay on top and bottom to account for motion effects
    self.overlayImageView.frame = CGRectMake(-400, [kShelbyMotionForegroundYMin floatValue], self.frame.size.width + 800, self.frame.size.height + [kShelbyMotionForegroundYMax floatValue] + (-[kShelbyMotionForegroundYMin floatValue]));
}

- (IBAction)shareVideo:(id)sender
{
    if (!self.shareActivityIndicator) {
        self.shareActivityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        self.shareActivityIndicator.frame = CGRectMake(4, 2, self.shareButton.frame.size.width - 4, self.shareButton.frame.size.height - 2);
        [self.shareButton setImage:nil forState:UIControlStateNormal];
        
        [self.shareButton addSubview:self.shareActivityIndicator];
    } else {
        self.shareActivityIndicator.hidden = NO;
    }
    [self.shareActivityIndicator startAnimating];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(resetShareButton:)
                                                 name:kShelbyShareVideoHasCompleted object:nil];
  
    [self.delegate shareVideoWasTapped];

    [ShelbyAnalyticsClient sendLocalyticsEvent:kLocalyticsEventNameVideoShareStart
                     withUserTypeAndAttributes:@{
                                                 kLocalyticsAttributeNameFromOrigin : kLocalyticsAttributeValueFromOriginVideoCard
                                                 }];
}

- (void)resetShareButton:(NSNotification *)notification
{
    // If we don't have an activity indicator or it is currently hidden, ignore notification
    if (!self.shareActivityIndicator || self.shareActivityIndicator.hidden) {
        return;
    }

    NSDictionary *userInfo = notification.userInfo;
    if ([userInfo[kShelbyShareFrameIDKey] isEqualToString:self.videoFrame.frameID]) {
        [self.shareActivityIndicator removeFromSuperview];
        self.shareActivityIndicator = nil;
        
        [self.shareButton setImage:[UIImage imageNamed:@"share-icon"] forState:UIControlStateNormal];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self name:kShelbyShareVideoHasCompleted object:nil];
    }
}

- (IBAction)openLikersView:(id)sender
{
    [ShelbyAnalyticsClient sendEventWithCategory:kAnalyticsCategoryPrimaryUX
                                          action:kAnalyticsUXTapCardLikersList
                                 nicknameAsLabel:YES];
    [ShelbyAnalyticsClient sendLocalyticsEvent:kLocalyticsTapCardLikersList];
    
    [self.delegate openLikersView:_likers];
}

- (IBAction)playVideoInCell:(id)sender
{
    [self.delegate streamBrowseCellForegroundViewTitleWasTapped];
}

- (IBAction)sendFacebookRequest:(id)sender
{
    [self.delegate inviteFacebookFriendsWasTapped];
}

- (IBAction)goToUserProfile:(id)sender
{
    [self.delegate userProfileWasTapped:self.userID];

    [ShelbyAnalyticsClient sendEventWithCategory:kAnalyticsCategoryPrimaryUX
                                          action:kAnalyticsUXTapCardSharingUser
                                 nicknameAsLabel:YES];
    [ShelbyAnalyticsClient sendLocalyticsEvent:kLocalyticsEventNameUserProfileView
                                withAttributes:@{
                                                 kLocalyticsAttributeNameFromOrigin : kLocalyticsAttributeValueFromOriginVideoCardOwner,
                                                 kLocalyticsAttributeNameUsername : self.videoFrame.creator.nickname ?: @"unknown"
                                                 }];
}

- (void)processLikersAndSharers
{
    _likers = [NSMutableOrderedSet orderedSet];
    for (User *liker in _videoFrame.upvoters) {
        [_likers addObject:liker];
    }

    for (DashboardEntry *dupe in _dashboardEntry.duplicates) {
        Frame *dupeFrame = dupe.frame;
        if (dupeFrame) {
            for (User *liker in dupe.frame.upvoters) {
                [_likers addObject:liker];
            }
        }
    }
}

- (void)updateVisualsForRecommendation
{
    if (_dashboardEntry) {
        if([_dashboardEntry recommendedEntry]) {
            //dashboard entry recommendation
            self.detailRecommendationReasonLabel.attributedText = [self recommendationStringFor:_dashboardEntry];
            self.summaryRecommendationView.hidden = NO;
            self.detailRecommendationView.hidden = NO;
            self.summaryUserView.hidden = YES;
            self.detailUserView.hidden = YES;
            self.detailCommentView.hidden = YES;
            return;
        }
    } else if (!_videoFrame.creator) {
        //frame without a creator (ie. you liked a recommended video)
        self.summaryRecommendationView.hidden = YES;
        self.detailRecommendationView.hidden = YES;
        self.summaryUserView.hidden = YES;
        self.detailUserView.hidden = YES;
        self.detailCommentView.hidden = YES;
        return;
    }

    //fall back to regular dashboard entry or frame with creator
    self.summaryRecommendationView.hidden = YES;
    self.detailRecommendationView.hidden = YES;
    self.summaryUserView.hidden = NO;
    self.detailUserView.hidden = NO;
    self.detailCommentView.hidden = NO;
    self.detailLikersAndSharers.hidden = NO;
}

- (NSAttributedString *)recommendationStringFor:(DashboardEntry *)dashboardEntry
{
    if (dashboardEntry.sourceFrameCreatorNickname) {
        NSString *recoBase = @"This video is Liked by people like ";
        NSString *recoUsername = dashboardEntry.sourceFrameCreatorNickname;
        NSString *recoString = [NSString stringWithFormat:@"%@%@", recoBase, recoUsername];
        NSMutableAttributedString *recoAttributed = [[NSMutableAttributedString alloc] initWithString:recoString];
        [recoAttributed setAttributes:@{NSFontAttributeName: kShelbyBodyFont2}
                                range:[recoString rangeOfString:recoBase]];
        [recoAttributed setAttributes:@{NSFontAttributeName: kShelbyBodyFont2Bold}
                                range:[recoString rangeOfString:recoUsername]];
        return recoAttributed;
    } else if (dashboardEntry.sourceVideoTitle) {
        NSString *recoString = [NSString stringWithFormat:@"Because you Liked \"%@\"", dashboardEntry.sourceVideoTitle];
        NSMutableAttributedString *recoAttributed = [[NSMutableAttributedString alloc] initWithString:recoString];
        [recoAttributed setAttributes:@{NSFontAttributeName: kShelbyBodyFont2}
                                range:[recoString rangeOfString:recoString]];
        return recoAttributed;
    } else {
        NSString *recoString = @"We thought you'd like to see this";
        NSMutableAttributedString *recoAttributed = [[NSMutableAttributedString alloc] initWithString:recoString];
        [recoAttributed setAttributes:@{NSFontAttributeName: kShelbyBodyFont2}
                                range:[recoString rangeOfString:recoString]];
        return recoAttributed;
    }
}

- (NSAttributedString *)usernameStringFor:(Frame *)videoFrame
{
    NSString *nick = _videoFrame.creator.nickname ? _videoFrame.creator.nickname : @"reco";
    NSString *baseString;
    if (self.videoFrame.typeOfFrame == FrameTypeLightWeight) {
        baseString = [NSString stringWithFormat:@"%@ liked this", _videoFrame.creator.nickname];
    } else {
        baseString = nick;
    }
    
    NSMutableAttributedString *usernameString = [[NSMutableAttributedString alloc] initWithString:baseString attributes:@{NSFontAttributeName: kShelbyBodyFont2}];
    [usernameString setAttributes:@{NSFontAttributeName: kShelbyBodyFont2Bold}
                            range:[baseString rangeOfString:nick]];
    
    return usernameString;
}

@end
