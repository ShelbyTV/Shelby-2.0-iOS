//
//  ShelbyVideoReelCollectionViewCell.h
//  Shelby.tv
//
//  Created by Dan Spinosa on 3/6/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const kShelbyVideoReelCollectionViewCellReuseId;

@class SPVideoPlayer;

@interface ShelbyVideoReelCollectionViewCell : UICollectionViewCell
@property (weak, nonatomic) SPVideoPlayer *player;

@end
