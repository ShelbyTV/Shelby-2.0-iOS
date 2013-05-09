//
//  SPChannelCell.h
//  Shelby.tv
//
//  Created by Keren on 4/15/13.
//  Copyright (c) 2013 Shelby TV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SPChannelCollectionView.h"

@interface SPChannelCell : UITableViewCell
@property (weak, nonatomic) IBOutlet SPChannelCollectionView *channelFrames;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *refreshActivityIndicator;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadMoreActivityIndicator;

- (UIColor *)channelDisplayColor;
- (NSString *)channelDisplayTitle;
- (void)setChannelColor:(UIColor *)color andTitle:(NSString *)title;
@end
