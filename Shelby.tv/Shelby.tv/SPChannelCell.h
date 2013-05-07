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

- (UIColor *)channelDisplayColor;
- (NSString *)channelDisplayTitle;
- (void)setChannelColor:(NSString *)hex andTitle:(NSString *)title;
@end
