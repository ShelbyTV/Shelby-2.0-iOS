//
//  ChannelViewCell.h
//  Shelby.tv
//
//  Created by Keren on 2/14/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ChannelViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *channelDescription;
@property (weak, nonatomic) IBOutlet UIButton *channelButton;
@property (weak, nonatomic) IBOutlet UILabel *channelName;

@end
