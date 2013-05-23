//
//  SPChannelCollectionView.h
//  Shelby.tv
//
//  Created by Keren on 4/30/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DisplayChannel.h"

@class SPChannelCell;

@interface SPChannelCollectionView : UICollectionView

@property (nonatomic, strong) DisplayChannel *channel;
@property (nonatomic, strong) UIColor *channelColor;
@property (weak, nonatomic) SPChannelCell *parentCell;

@end