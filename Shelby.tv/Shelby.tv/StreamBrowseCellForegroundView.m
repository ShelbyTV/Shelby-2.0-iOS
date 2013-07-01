//
//  StreamBrowseCellForegroundView.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 6/24/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "StreamBrowseCellForegroundView.h"

#define kShelbyInfoViewMargin 15

@interface  StreamBrowseCellForegroundView()
@property (nonatomic, weak) IBOutlet UIImageView *summaryUserAvatar;
@property (weak, nonatomic) IBOutlet UILabel *summaryUsername;
@property (weak, nonatomic) IBOutlet UILabel *summaryViaNetwork;

@property (nonatomic, weak) IBOutlet UIImageView *detailUserAvatar;
@property (weak, nonatomic) IBOutlet UILabel *detailUsername;
@property (weak, nonatomic) IBOutlet UILabel *detailViaNetwork;
@property (weak, nonatomic) IBOutlet UIView *detailUserView;
@property (weak, nonatomic) IBOutlet UIView *detailCommentView;
@property (weak, nonatomic) IBOutlet UIView *detailNetworkShares;
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
        self.detailTitle.frame = CGRectMake(xOrigin, 60, 280, 17);
        self.detailUserView.frame = CGRectMake(xOrigin, 90, 160, 60);
        self.detailCommentView.frame = CGRectMake(xOrigin, 160, pageWidth - kShelbyInfoViewMargin * 2, 60);
        self.detailNetworkShares.frame = CGRectMake(xOrigin + self.detailUserView.frame.size.width + kShelbyInfoViewMargin, 100, 280, 40);
    } else {
        // Portrait
        self.detailTitle.frame = CGRectMake(xOrigin, 60, 280, 17);
        self.detailUserView.frame = CGRectMake(xOrigin, 90, 160, 60);
        self.detailCommentView.frame = CGRectMake(xOrigin, 160, 280, 100);
        self.detailNetworkShares.frame = CGRectMake(xOrigin, 270, 280, 40);
    }
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
