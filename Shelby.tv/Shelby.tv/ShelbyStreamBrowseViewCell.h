//
//  ShelbyStreamBrowseViewCell.h
//  Shelby.tv
//
//  Created by Keren on 6/21/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ShelbyVideoContainer.h"

@interface ShelbyStreamBrowseViewCell : UICollectionViewCell

//a Frame or DashboardEntry
@property (nonatomic, strong) id<ShelbyVideoContainer> entry;

@end
