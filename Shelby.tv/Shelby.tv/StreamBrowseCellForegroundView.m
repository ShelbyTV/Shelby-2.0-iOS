//
//  StreamBrowseCellForegroundView.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 6/24/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "StreamBrowseCellForegroundView.h"
#import "Video+Helper.h"
#import "User.h"

#define kShelbyInfoViewMargin 15
#define kShelbyCaptionMargin 2

@interface  StreamBrowseCellForegroundView()
// Detail View Outlets
@property (weak, nonatomic) IBOutlet UILabel *detailCaption;
@property (weak, nonatomic) IBOutlet UIView *detailCommentView;
@property (weak, nonatomic) IBOutlet UIView *detailNetworkShares;
@property (weak, nonatomic) IBOutlet UILabel *detailTitle;
@property (weak, nonatomic) IBOutlet UIImageView *detailUserAvatar;
@property (weak, nonatomic) IBOutlet UILabel *detailUsername;
@property (weak, nonatomic) IBOutlet UIView *detailUserView;
@property (weak, nonatomic) IBOutlet UILabel *detailViaNetwork;

// Summary View Outlets
@property (weak, nonatomic) IBOutlet UILabel *summaryTitle;
@property (nonatomic, weak) IBOutlet UIImageView *summaryUserAvatar;
@property (weak, nonatomic) IBOutlet UILabel *summaryUsername;
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
 
    NSInteger pageWidth = self.frame.size.width / 2;
//    NSInteger pageHeight = self.frame.size.height;
    NSInteger xOrigin = pageWidth + kShelbyInfoViewMargin;
  
    if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
        // Landscape
        // Summary View
        self.summaryTitle.frame = CGRectMake(20, 60, pageWidth - kShelbyInfoViewMargin * 2, 90);
        // Detail View
        self.detailTitle.frame = CGRectMake(xOrigin, 60, pageWidth - kShelbyInfoViewMargin * 2, 22);
        self.detailUserView.frame = CGRectMake(xOrigin, 105, 160, 60);
        self.detailCommentView.frame = CGRectMake(xOrigin, 170, pageWidth - kShelbyInfoViewMargin * 2, 60);
        self.detailNetworkShares.frame = CGRectMake(xOrigin + self.detailUserView.frame.size.width + kShelbyInfoViewMargin, self.detailUserView.frame.origin.y + 10, 280, 40);
    } else {
        // Portrait
        // Summary View
        self.summaryTitle.frame = CGRectMake(20, 84, 280, 120);
     
        // Detail View
        self.detailTitle.frame = CGRectMake(xOrigin, 50, 280, 44);
        self.detailUserView.frame = CGRectMake(xOrigin, 105, 160, 60);
        self.detailCommentView.frame = CGRectMake(xOrigin, 195, 280, 100);
        self.detailNetworkShares.frame = CGRectMake(xOrigin, 305, 280, 40);
    }
    
    self.detailCaption.frame = CGRectMake(2, 2, self.detailCommentView.frame.size.width - 4, self.detailCommentView.frame.size.height - 4);
    [self resizeCaptionLabel];
}


- (void)setInfoForFrame:(Frame *)videoFrame
{
    //title
    self.summaryTitle.text = videoFrame.video.title;
    self.detailTitle.text = videoFrame.video.title;
    
    // Username
    self.summaryUsername.text = videoFrame.creator.nickname;
    self.detailUsername.text = videoFrame.creator.nickname;
    
    // Via Network - TODO:
    
    // Caption
    NSString *captionText = [NSString stringWithFormat:@"%@: %@", videoFrame.creator.nickname, [videoFrame creatorsInitialCommentWithFallback:YES]];
    [self.detailCaption setText:captionText];
    [self resizeCaptionLabel];
}

- (void)resizeCaptionLabel
{
    NSString *captionText = self.detailCaption.text;
    
    CGSize maxCaptionSize = CGSizeMake(self.detailCommentView.frame.size.width - kShelbyCaptionMargin * 2, self.detailCommentView.frame.size.height - kShelbyCaptionMargin * 2);
    CGFloat textBasedHeight = [captionText sizeWithFont:[self.detailCaption font]
                                      constrainedToSize:maxCaptionSize
                                          lineBreakMode:NSLineBreakByWordWrapping].height;
    
    [self.detailCaption setFrame:CGRectMake(self.detailCaption.frame.origin.x,
                                            (self.detailCommentView.frame.size.height - textBasedHeight) / kShelbyCaptionMargin,
                                            self.detailCommentView.frame.size.width - kShelbyCaptionMargin * 2,
                                            textBasedHeight)];

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
