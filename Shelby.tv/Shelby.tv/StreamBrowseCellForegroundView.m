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
#import "User.h"

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

- (void)layoutSubviews
{
    [super layoutSubviews];
    //XXX Layout Test
//    self.detailUsername.backgroundColor = [UIColor purpleColor];
//    self.detailViaNetwork.backgroundColor = [UIColor orangeColor];
//    self.detailCaption.backgroundColor = [UIColor brownColor];
    //XXX Layout Test

    NSInteger pageWidth = self.frame.size.width / 2;
//    NSInteger pageHeight = self.frame.size.height;
    NSInteger xOrigin = pageWidth + kShelbyInfoViewMargin;
  
    if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
        // Landscape
        // Summary View
        self.summaryTitle.frame = CGRectMake(kShelbyInfoViewMargin, 60, pageWidth - kShelbyInfoViewMargin * 2, 90);
        // Detail View
        self.detailCreatedAt.frame = CGRectMake(xOrigin, 40, pageWidth - kShelbyInfoViewMargin * 2, 22);
        self.detailTitle.frame = CGRectMake(xOrigin, 60, pageWidth - kShelbyInfoViewMargin * 2, 22);
        self.detailWhiteBackground.frame = CGRectMake(xOrigin - kShelbyInfoViewMargin, 85, pageWidth, 140);
        self.detailUserView.frame = CGRectMake(xOrigin, 85, 185, 60);
        self.detailUsername.frame = CGRectMake(self.detailUsername.frame.origin.x, self.detailUsername.frame.origin.y, 100, self.detailUsername.frame.size.height);
        self.detailCommentView.frame = CGRectMake(xOrigin, 160, pageWidth - kShelbyInfoViewMargin * 2, 60);
        self.detailNetworkShares.frame = CGRectMake(xOrigin + self.detailUserView.frame.size.width + kShelbyInfoViewMargin, self.detailUserView.frame.origin.y + 10, 240, 40);
    } else {
        // Portrait
        // Summary View
        self.summaryTitle.frame = CGRectMake(kShelbyInfoViewMargin, 84, 280, 120);
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
    self.summaryUserView.frame = CGRectMake(self.summaryUserView.frame.origin.x, self.summaryTitle.frame.origin.y + self.summaryTitle.frame.size.height + 10, self.summaryTitle.frame.size.width, self.summaryUserView.frame.size.height);

    [self resizeCaptionLabel];
    
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
    NSURL *url = [NSURL URLWithString:videoFrame.creator.userImage];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPShouldHandleCookies:NO];
    [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];

    __weak StreamBrowseCellForegroundView *weakSelf = self;
    [self.summaryUserAvatar setImageWithURLRequest:request placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
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
    NSString *captionText = [NSString stringWithFormat:@"%@: %@", videoFrame.creator.nickname, [videoFrame creatorsInitialCommentWithFallback:YES]];
    [self.detailCaption setText:captionText];
    [self resizeCaptionLabel];
    
    // Shares
    NSOrderedSet *shareFrames = videoFrame.duplicates;
    if ([shareFrames count]) {
        // TODO: show share frames
    }
    
    if (videoFrame.upvoters && [videoFrame.upvoters count] > 0) {
        for (User *upvote in videoFrame.upvoters) {
            // TODO: add avatar to view
            DLog(@"Upvoted - %@", upvote.name);
        }
    }
}

- (void)resizeCaptionLabel
{
    NSString *captionText = self.detailCaption.text;
    
    CGSize maxCaptionSize = CGSizeMake(self.detailCommentView.frame.size.width - kShelbyCaptionMargin * 2, self.detailCommentView.frame.size.height - kShelbyCaptionMargin * 2);
    CGFloat textBasedHeight = [captionText sizeWithFont:[self.detailCaption font]
                                      constrainedToSize:maxCaptionSize
                                          lineBreakMode:NSLineBreakByWordWrapping].height;
    NSInteger yOrigin = (self.detailCommentView.frame.size.height - kShelbyCaptionMargin - textBasedHeight) / 2;
    self.detailCaption.frame = CGRectMake(self.detailCaption.frame.origin.x,
                                          yOrigin,
                                          maxCaptionSize.width,
                                          textBasedHeight);
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
