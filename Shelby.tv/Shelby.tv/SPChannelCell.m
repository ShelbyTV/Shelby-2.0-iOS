//
//  SPChannelCell.m
//  Shelby.tv
//
//  Created by Keren on 4/15/13.
//  Copyright (c) 2013 Shelby TV. All rights reserved.
//

#import "SPChannelCell.h"
#import "UIColor+ColorWithHexAndAlpha.h"

@interface SPChannelCell()
@property (weak, nonatomic) IBOutlet UILabel *channelTitle;
@property (weak, nonatomic) IBOutlet UIView *channelColorView;
@end

@implementation SPChannelCell


- (void)awakeFromNib
{
    [[self selectedBackgroundView] setBackgroundColor:[UIColor clearColor]];
    [self.contentView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"channelbg.png"]]];

}

- (void)setChannelColor:(NSString *)hex andTitle:(NSString *)title
{
    [self.channelTitle setText:title];
    
    UIColor *channelColor = nil;
    if (hex) {
        channelColor = [UIColor colorWithHex:hex andAlpha:1];
    } else {
        channelColor = kShelbyColorGreen;
    }

    [self.channelColorView setBackgroundColor:channelColor];
    
    CGSize maxCaptionSize = CGSizeMake(self.frame.size.width - 10, self.channelTitle.frame.size.height);
    CGFloat titleLabelWidth = [title sizeWithFont:[self.channelTitle font]
                                            constrainedToSize:maxCaptionSize
                                                lineBreakMode:NSLineBreakByWordWrapping].width;
    [self.channelTitle setFrame:CGRectMake(self.channelTitle.frame.origin.x, self.channelTitle.frame.origin.y, titleLabelWidth + 10, self.channelTitle.frame.size.height)];
    [self.channelTitle setBackgroundColor:channelColor];
    [self.channelFrames setChannelColor:channelColor];
    self.channelFrames.backgroundColor = channelColor;
    self.loadMoreActivityIndicator.color = channelColor;
}

- (UIColor *)channelDisplayColor
{
    return [self.channelColorView backgroundColor];
}

- (NSString *)channelDisplayTitle
{
    return [self.channelTitle text];
}

@end
