//
//  StreamBrowseCellForegroundView.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 6/24/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "StreamBrowseCellForegroundView.h"
#import "Video+Helper.h"
#import "UIImageView+AFNetworking.h"
#import "User+Helper.h"

#define kShelbyInfoViewMargin 15
#define kShelbyCaptionMargin 4

@interface  StreamBrowseCellForegroundView()
// Detail View Outlets
@property (weak, nonatomic) IBOutlet UILabel *detailCaption;
@property (weak, nonatomic) IBOutlet UIView *detailCommentView;
@property (weak, nonatomic) IBOutlet UILabel *detailCreatedAt;
@property (weak, nonatomic) IBOutlet UIView *detailNetworkShares;
@property (weak, nonatomic) IBOutlet UILabel *detailTitle;
@property (weak, nonatomic) IBOutlet UIImageView *detailUserAvatar;
@property (weak, nonatomic) IBOutlet UILabel *detailUsername;
@property (weak, nonatomic) IBOutlet UIView *detailUserView;
@property (weak, nonatomic) IBOutlet UILabel *detailViaNetwork;
@property (weak, nonatomic) IBOutlet UIView *detailWhiteBackground;

// Summary View Outlets
@property (weak, nonatomic) IBOutlet UILabel *summaryTitle;
@property (nonatomic, weak) IBOutlet UIImageView *summaryUserAvatar;
@property (weak, nonatomic) IBOutlet UILabel *summaryUsername;
@property (weak, nonatomic) IBOutlet UIView *summaryUserView;
@property (weak, nonatomic) IBOutlet UILabel *summaryViaNetwork;
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

        // Detail View
        self.detailCreatedAt.frame = CGRectMake(xOrigin, 45, pageWidth - kShelbyInfoViewMargin * 2, 22);
        self.detailTitle.frame = CGRectMake(xOrigin, 65, pageWidth - kShelbyInfoViewMargin * 2, 22);
        self.detailWhiteBackground.frame = CGRectMake(xOrigin - kShelbyInfoViewMargin, 90, pageWidth, 140);
        self.detailUserView.frame = CGRectMake(xOrigin - kShelbyInfoViewMargin, 95, 185, 60);
        self.detailUsername.frame = CGRectMake(self.detailUsername.frame.origin.x, self.detailUsername.frame.origin.y, 100, self.detailUsername.frame.size.height);
        self.detailCommentView.frame = CGRectMake(xOrigin, 155, pageWidth - kShelbyInfoViewMargin * 2, 60);
        self.detailNetworkShares.frame = CGRectMake(xOrigin + self.detailUserView.frame.size.width + kShelbyInfoViewMargin, self.detailUserView.frame.origin.y + 10, 245, 40);
    } else {
        // Portrait
        // Summary View
        self.summaryTitle.frame = CGRectMake(kShelbyInfoViewMargin, 64, 280, 120);
        self.summaryUserView.frame = CGRectMake(self.summaryUserView.frame.origin.x, self.summaryTitle.frame.origin.y + self.summaryTitle.frame.size.height, self.summaryTitle.frame.size.width, self.summaryUserView.frame.size.height);

        // Detail View
        self.detailCreatedAt.frame = CGRectMake(xOrigin, 60, pageWidth - kShelbyInfoViewMargin * 2, 22);
        self.detailTitle.frame = CGRectMake(xOrigin, 80, 280, 44);
        self.detailWhiteBackground.frame = CGRectMake(xOrigin - kShelbyInfoViewMargin, 130, pageWidth, 200);
        self.detailUserView.frame = CGRectMake(pageWidth, 135, 320, 60);
        self.detailUsername.frame = CGRectMake(self.detailUsername.frame.origin.x, self.detailUsername.frame.origin.y, 215, self.detailUsername.frame.size.height);
        self.detailCommentView.frame = CGRectMake(xOrigin, 195, pageWidth - kShelbyInfoViewMargin * 2, 100);
        self.detailNetworkShares.frame = CGRectMake(xOrigin, 305, 310, 40);
    }
    
    self.detailViaNetwork.frame = CGRectMake(self.detailViaNetwork.frame.origin.x, self.detailViaNetwork.frame.origin.y, self.detailUsername.frame.size.width, self.detailViaNetwork.frame.size.height);
 
    [self resizeViewsForContent];
}


- (void)setInfoForFrame:(Frame *)videoFrame
{
    // createAt
    self.detailCreatedAt.text = videoFrame.createdAt;

    //title
    self.summaryTitle.text = videoFrame.video.title;
    self.detailTitle.text = videoFrame.video.title;
    
    // Username
    self.summaryUsername.text = videoFrame.creator.nickname;
    self.detailUsername.text = videoFrame.creator.nickname;
    
    // User Avatar
    // Request setup was taken from UIImage+AFNetworking. As we have to set a completion block so the detail avatar will be the same as the summary one. (Otherwise, we had to make 2 seperate calls)
    NSURL *url = [videoFrame.creator avatarURL];
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
        //TODO: retry?
    }];
    
    // Via Network
    NSString *viaNetwork = [videoFrame originNetwork];
    if (viaNetwork) {
        viaNetwork = [NSString stringWithFormat:@"via %@", viaNetwork];
    }
    
    self.summaryViaNetwork.text = viaNetwork;
    self.detailViaNetwork.text = self.summaryViaNetwork.text;
    
    // Caption
    NSString *captionText = [NSString stringWithFormat:@"%@", [videoFrame creatorsInitialCommentWithFallback:YES]];
    [self.detailCaption setText:captionText];
    [self resizeViewsForContent];
    
    // Shares
    NSOrderedSet *shareFrames = videoFrame.duplicates;
    if ([shareFrames count]) {
        // TODO: show share frames
    }
    
    if (videoFrame.upvoters && [videoFrame.upvoters count] > 0) {
        for (User *upvote in videoFrame.upvoters) {
            // TODO: add avatar to view
//            DLog(@"Upvoted - %@", upvote.name);
        }
    }
}

- (void)resizeViewsForContent
{
    //padding adjustments for landscape vs portrait
    CGFloat summaryUserPadding, detailTitlePadding, detailCommentPadding, detailUserPadding, detailWhiteBackgroundHeightAdjustment;
    if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
        summaryUserPadding = 50;
        detailTitlePadding = 70;
        detailUserPadding = 0;
        detailCommentPadding = 60;
        detailWhiteBackgroundHeightAdjustment = 70;
    } else {
        summaryUserPadding = 70;
        detailTitlePadding = 90;
        detailUserPadding = 5;
        detailCommentPadding = 70;
        detailWhiteBackgroundHeightAdjustment = 80;
    }


    //-----------summary page---------------
    //resize summary title
    NSString *summaryTitleText = self.summaryTitle.text;
    CGSize maxSummaryTitleSize = CGSizeMake(self.summaryTitle.frame.size.width, self.summaryTitle.frame.size.height);
    CGFloat summaryTitleDesiredHeight = [summaryTitleText sizeWithFont:self.summaryTitle.font
                                                     constrainedToSize:maxSummaryTitleSize
                                                         lineBreakMode:self.summaryTitle.lineBreakMode].height;
    self.summaryTitle.frame = CGRectMake(self.summaryTitle.frame.origin.x, self.summaryTitle.frame.origin.y, self.summaryTitle.frame.size.width, summaryTitleDesiredHeight);

    //move the user view just below the title
    self.summaryUserView.frame = CGRectMake(self.summaryUserView.frame.origin.x, summaryTitleDesiredHeight + summaryUserPadding, self.summaryUserView.frame.size.width, self.summaryUserView.frame.size.height);


    //-----------detail page---------------
    //resize detail title
    NSString *detailTitleText = self.detailTitle.text;
    CGSize maxDetailTitleSize = CGSizeMake(self.detailTitle.frame.size.width, 44);
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
}

@end
