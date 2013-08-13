//
//  StreamBrowseCellForegroundView.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 6/24/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "StreamBrowseCellForegroundView.h"
#import "DashboardEntry+Helper.h"
#import "Video+Helper.h"
#import "UIImageView+AFNetworking.h"
#import "User+Helper.h"

#define kShelbyInfoViewMargin 15
#define kShelbyCaptionMargin 4

@interface  StreamBrowseCellForegroundView() {
    NSMutableOrderedSet *_likers;
    NSMutableOrderedSet *_sharers;
    NSArray *_likerImageViews;
    NSArray *_sharerImageViews;
}
//model
@property (strong, nonatomic) DashboardEntry *dashboardEntry;
@property (strong, nonatomic) Frame *videoFrame;

// Detail View Outlets
@property (weak, nonatomic) IBOutlet UILabel *detailCaption;
@property (weak, nonatomic) IBOutlet UIView *detailCommentView;
@property (weak, nonatomic) IBOutlet UILabel *detailCreatedAt;
@property (weak, nonatomic) IBOutlet UIView *detailLikersAndSharers;
@property (weak, nonatomic) IBOutlet UIView *detailLikersSubview;
@property (weak, nonatomic) IBOutlet UIView *detailSharersSubview;
@property (weak, nonatomic) IBOutlet UILabel *detailTitle;
@property (weak, nonatomic) IBOutlet UIButton *detailTitleButton;
@property (weak, nonatomic) IBOutlet UIImageView *detailUserAvatar;
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
@property (weak, nonatomic) IBOutlet UILabel *summaryUsername;
@property (weak, nonatomic) IBOutlet UIView *summaryUserView;
@property (weak, nonatomic) IBOutlet UILabel *summaryViaNetwork;
@property (weak, nonatomic) IBOutlet UIView *summaryRecommendationView;

//overlay below everything
@property (nonatomic, strong) UIImageView *overlayImageView;

- (IBAction)playVideoInCell:(id)sender;
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

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.detailUserAvatar.layer.cornerRadius = 5;
    self.detailUserAvatar.layer.masksToBounds = YES;
    self.summaryUserAvatar.layer.cornerRadius = 5;
    self.summaryUserAvatar.layer.masksToBounds = YES;

    [self setupOverlayImageView];
    [self insertSubview:self.overlayImageView atIndex:0];

    [self setupLikersAndSharersSubviews];

    //white layer with alpha for iOS6 & 7
    //the toolbar blur hack isn't great, it's just doing a static image swaparoo
    self.detailWhiteBackground.alpha = 0.75;
    self.detailWhiteBackground.backgroundColor = [UIColor whiteColor];
}

- (void)setupLikersAndSharersSubviews
{
    NSMutableArray *likerViews = [@[] mutableCopy];
    NSMutableArray *sharerViews = [@[] mutableCopy];
    CGFloat likerX = 40.f, sharerX = 40.f;
    CGFloat likerSharerHeight = 30.f;
    UIImageView *likerImageView, *sharerImageView;
    for (int i = 0; i < 6; i++) {
        likerImageView = [[UIImageView alloc] initWithFrame:CGRectMake(likerX, 5, likerSharerHeight, likerSharerHeight)];
        [self.detailLikersSubview addSubview:likerImageView];
        likerImageView.layer.cornerRadius = 3.0f;
        likerImageView.layer.masksToBounds = YES;
        [likerViews addObject:likerImageView];
        likerX += likerSharerHeight + 10;
        sharerImageView = [[UIImageView alloc] initWithFrame:CGRectMake(sharerX, 5, likerSharerHeight, likerSharerHeight)];
        [self.detailSharersSubview addSubview:sharerImageView];
        sharerImageView.layer.cornerRadius = 3.0f;
        sharerImageView.layer.masksToBounds = YES;
        [sharerViews addObject:sharerImageView];
        sharerX += likerSharerHeight + 10;
    }

    _likerImageViews = likerViews;
    _sharerImageViews = sharerViews;
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
        self.detailUserView.frame = CGRectMake(pageWidth, 135, 320, 60);
        self.detailUsername.frame = CGRectMake(self.detailUsername.frame.origin.x, self.detailUsername.frame.origin.y, 215, self.detailUsername.frame.size.height);
        self.detailCommentView.frame = CGRectMake(xOrigin, 195, pageWidth - kShelbyInfoViewMargin * 2, 100);
        self.detailRecommendationView.frame = self.detailWhiteBackground.frame;
    }
    
    self.detailViaNetwork.frame = CGRectMake(self.detailViaNetwork.frame.origin.x, self.detailViaNetwork.frame.origin.y, self.detailUsername.frame.size.width, self.detailViaNetwork.frame.size.height);
 
    self.summaryTitleButton.frame = self.summaryTitle.frame;
    self.detailTitleButton.frame = self.detailTitle.frame;

    [self resizeViewsForContent];

    [self setupOverlayImageView];
}

- (void)setInfoForDashboardEntry:(DashboardEntry *)dashboardEntry frame:(Frame *)videoFrame
{
    _dashboardEntry = dashboardEntry;
    _videoFrame = videoFrame;

    [self updateVisualsForRecommendation];
    [self processLikersAndSharers];
    [self updateStandardVisuals];
}

- (void)updateStandardVisuals
{
    // createAt
    self.detailCreatedAt.text = _videoFrame.createdAt;

    //title
    self.summaryTitle.text = _videoFrame.video.title;
    self.detailTitle.text = _videoFrame.video.title;
    
    // Username
    self.summaryUsername.text = _videoFrame.creator.nickname;
    self.detailUsername.text = _videoFrame.creator.nickname;
    
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
    
    // Via Network
    NSString *viaNetwork = [_videoFrame originNetwork];
    if (viaNetwork) {
        viaNetwork = [NSString stringWithFormat:@"via %@", viaNetwork];
    }
    
    self.summaryViaNetwork.text = viaNetwork;
    self.detailViaNetwork.text = self.summaryViaNetwork.text;
    
    // Caption
    NSString *captionText = [NSString stringWithFormat:@"%@", [_videoFrame creatorsInitialCommentWithFallback:YES]];
    [self.detailCaption setText:captionText];
    [self resizeViewsForContent];

    // Sharers
    for (UIImageView *iv in _sharerImageViews) {
        iv.image = nil;
    }
    if ([_sharers count]) {
        self.detailSharersSubview.hidden = NO;
        for (NSUInteger i = 0; i < [_sharers count]; i++) {
            User *sharer = _sharers[i];
            [((UIImageView *)_sharerImageViews[i]) setImageWithURL:sharer.avatarURL placeholderImage:[UIImage imageNamed:@"avatar-blank"]];
        }
    } else {
        self.detailSharersSubview.hidden = YES;
    }

    // Likers
    for (UIImageView *iv in _likerImageViews) {
        iv.image = nil;
    }
    if ([_likers count]) {
        self.detailLikersSubview.hidden = NO;
        for (NSUInteger i = 0; i < [_likers count]; i++) {
            User *liker = _likers[i];
            [((UIImageView *)_likerImageViews[i]) setImageWithURL:liker.avatarURL placeholderImage:[UIImage imageNamed:@"avatar-blank"]];
        }
    } else {
        self.detailLikersSubview.hidden = YES;
    }
}

- (void)resizeViewsForContent
{
    //padding adjustments for landscape vs portrait
    CGFloat summaryUserPadding, detailTitlePadding, detailCommentPadding, detailUserPadding, detailWhiteBackgroundHeightAdjustment, detailLikersAndSharersPadding;
    NSInteger detailTitleHeight;
    if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
        summaryUserPadding = 50;
        detailTitlePadding = 70;
        detailUserPadding = 0;
        detailCommentPadding = 60;
        detailLikersAndSharersPadding = 0;
        detailWhiteBackgroundHeightAdjustment = 65;
        detailTitleHeight = 22;
    } else {
        summaryUserPadding = 70;
        detailTitlePadding = 90;
        detailUserPadding = 5;
        detailCommentPadding = 70;
        detailLikersAndSharersPadding = 10;
        detailWhiteBackgroundHeightAdjustment = 80;
        detailTitleHeight = 44;
    }


    //-----------summary page---------------
    //resize summary title
    NSString *summaryTitleText = self.summaryTitle.text;
    CGSize maxSummaryTitleSize = CGSizeMake(self.summaryTitle.frame.size.width, self.summaryTitle.frame.size.height);
    CGFloat summaryTitleDesiredHeight = [summaryTitleText sizeWithFont:self.summaryTitle.font
                                                     constrainedToSize:maxSummaryTitleSize
                                                         lineBreakMode:self.summaryTitle.lineBreakMode].height;
    self.summaryTitle.frame = CGRectMake(self.summaryTitle.frame.origin.x, self.summaryTitle.frame.origin.y, self.summaryTitle.frame.size.width, summaryTitleDesiredHeight);

    //move the user + recommendation views just below the title
    self.summaryUserView.frame = CGRectMake(self.summaryUserView.frame.origin.x, summaryTitleDesiredHeight + summaryUserPadding, self.summaryUserView.frame.size.width, self.summaryUserView.frame.size.height);
    self.summaryRecommendationView.frame = self.summaryUserView.frame;


    //-----------detail page---------------
    //resize detail title
    NSString *detailTitleText = self.detailTitle.text;
    CGSize maxDetailTitleSize = CGSizeMake(self.detailTitle.frame.size.width, detailTitleHeight);
    CGFloat detailTitleDesiredHeight = [detailTitleText sizeWithFont:self.detailTitle.font
                                                   constrainedToSize:maxDetailTitleSize
                                                       lineBreakMode:self.detailTitle.lineBreakMode].height;
    self.detailTitle.frame = CGRectMake(self.detailTitle.frame.origin.x, self.detailTitle.frame.origin.y, self.detailTitle.frame.size.width, detailTitleDesiredHeight);

    //move the detail user view, caption holder, and white background up underneath the title
    CGFloat yUnderDetailTitle = detailTitleDesiredHeight + detailTitlePadding;
    self.detailUserView.frame = CGRectMake(self.detailUserView.frame.origin.x, yUnderDetailTitle + detailUserPadding, self.detailUserView.frame.size.width, self.detailUserView.frame.size.height);
    self.detailCommentView.frame = CGRectMake(self.detailCommentView.frame.origin.x, yUnderDetailTitle + detailCommentPadding, self.detailCommentView.frame.size.width, self.detailCommentView.frame.size.height);
    self.detailWhiteBackground.frame = CGRectMake(self.detailWhiteBackground.frame.origin.x, yUnderDetailTitle, self.detailWhiteBackground.frame.size.width, self.detailWhiteBackground.frame.size.height);

    //resize detail caption
    NSString *captionText = self.detailCaption.text;
    
    CGSize maxCaptionSize = CGSizeMake(self.detailCommentView.frame.size.width - kShelbyCaptionMargin * 2, self.detailCommentView.frame.size.height - kShelbyCaptionMargin * 2);
    CGFloat textBasedHeight = [captionText sizeWithFont:[self.detailCaption font]
                                      constrainedToSize:maxCaptionSize
                                          lineBreakMode:NSLineBreakByWordWrapping].height;
    self.detailCaption.frame = CGRectMake(self.detailCaption.frame.origin.x,
                                          0,
                                          maxCaptionSize.width,
                                          textBasedHeight);

    //tighting up the height of surrounding box as well
    self.detailWhiteBackground.frame = CGRectMake(self.detailWhiteBackground.frame.origin.x, self.detailWhiteBackground.frame.origin.y, self.detailWhiteBackground.frame.size.width, textBasedHeight + detailWhiteBackgroundHeightAdjustment);

    //update likers and sharers based on the white background box
    self.detailLikersAndSharers.frame = CGRectMake(self.detailWhiteBackground.frame.origin.x, self.detailWhiteBackground.frame.origin.y + self.detailWhiteBackground.frame.size.height + detailLikersAndSharersPadding, self.detailWhiteBackground.frame.size.width, self.detailLikersAndSharers.frame.size.height);
    self.detailLikersSubview.frame = CGRectMake(0, 0, self.detailLikersAndSharers.frame.size.width/2.f, self.detailLikersAndSharers.frame.size.height);
    self.detailSharersSubview.frame = CGRectMake(self.detailLikersAndSharers.frame.size.width/2.f, 0, self.detailLikersAndSharers.frame.size.width/2.f, self.detailLikersAndSharers.frame.size.height);

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

    UIImage *overlayImage = [[UIImage imageNamed:imageName] resizableImageWithCapInsets:UIEdgeInsetsZero resizingMode:UIImageResizingModeStretch];

    if (!self.overlayImageView) {
        self.overlayImageView = [[UIImageView alloc] initWithImage:overlayImage];
    } else {
        self.overlayImageView.image = overlayImage;
    }

    self.overlayImageView.frame = CGRectMake(-400, 0, self.frame.size.width + 800, self.frame.size.height);
}

- (IBAction)playVideoInCell:(id)sender
{
    [self.delegate streamBrowseCellForegroundViewTitleWasTapped];
}

- (void)processLikersAndSharers
{
    _likers = [NSMutableOrderedSet orderedSet];
    for (User *liker in _videoFrame.upvoters) {
        [_likers addObject:liker];
    }

    _sharers = [NSMutableOrderedSet orderedSet];
    for (DashboardEntry *dupe in _dashboardEntry.duplicates) {
        Frame *dupeFrame = dupe.frame;
        if (dupeFrame) {
            [_sharers addObject:dupeFrame.creator];
            for (User *liker in dupe.frame.upvoters) {
                [_likers addObject:liker];
            }
        }
    }

    //don't double-count primary sharer
    [_sharers removeObject:_videoFrame.creator];
}

- (BOOL)updateVisualsForRecommendation
{
    if (_dashboardEntry && [_dashboardEntry typeOfEntry] == DashboardEntryTypeVideoGraphRecommendation) {
        self.detailRecommendationReasonLabel.attributedText = [self recommendationStringFor:_dashboardEntry];
        self.summaryRecommendationView.hidden = NO;
        self.detailRecommendationView.hidden = NO;
        self.summaryUserView.hidden = YES;
        self.detailUserView.hidden = YES;
        self.detailCommentView.hidden = YES;
        self.detailLikersAndSharers.hidden = YES;
        return YES;
    } else {
        self.summaryRecommendationView.hidden = YES;
        self.detailRecommendationView.hidden = YES;
        self.summaryUserView.hidden = NO;
        self.detailUserView.hidden = NO;
        self.detailCommentView.hidden = NO;
        self.detailLikersAndSharers.hidden = NO;
        return NO;
    }
}

- (NSAttributedString *)recommendationStringFor:(DashboardEntry *)dashboardEntry
{
    NSString *recoBase = @"This video is shared by people like ";
    NSString *recoUsername = dashboardEntry.sourceFrameCreatorNickname;
    NSString *recoString = [NSString stringWithFormat:@"%@%@", recoBase, recoUsername];
    NSMutableAttributedString *recoAttributed = [[NSMutableAttributedString alloc] initWithString:recoString];
    [recoAttributed setAttributes:@{NSFontAttributeName: kShelbyFontH4Medium}
                            range:[recoString rangeOfString:recoBase]];
    [recoAttributed setAttributes:@{NSFontAttributeName: kShelbyFontH4Bold}
                            range:[recoString rangeOfString:recoUsername]];
    return recoAttributed;
}

@end
