//
//  SPChannelCell.h
//  Shelby.tv
//
//  Created by Keren on 4/15/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SPChannelCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UICollectionView *categoryFrames;

- (UIColor *)channelDisplayColor;
- (NSString *)channelDisplayTitle;
- (void)setChannelColor:(NSString *)hex andTitle:(NSString *)title;
@end
