//
//  StreamBrowseCellForegroundView.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 6/24/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "StreamBrowseCellForegroundView.h"

@interface  StreamBrowseCellForegroundView()
@property (nonatomic, weak) IBOutlet UIImageView *summaryUserAvatar;
@property (weak, nonatomic) IBOutlet UILabel *summaryUsername;
@property (weak, nonatomic) IBOutlet UILabel *summaryViaNetwork;

@property (nonatomic, weak) IBOutlet UIImageView *detailUserAvatar;
@property (weak, nonatomic) IBOutlet UILabel *detailUsername;
@property (weak, nonatomic) IBOutlet UILabel *detailViaNetwork;
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

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
