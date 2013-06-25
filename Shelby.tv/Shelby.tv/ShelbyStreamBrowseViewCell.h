//
//  ShelbyStreamBrowseViewCell.h
//  Shelby.tv
//
//  Created by Keren on 6/21/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ShelbyVideoContainer.h"
#import "STVParallaxView.h"

@interface ShelbyStreamBrowseViewCell : UICollectionViewCell <STVParallaxViewDelegate>

//a Frame or DashboardEntry
@property (nonatomic, strong) id<ShelbyVideoContainer> entry;

@property (nonatomic, weak) id<STVParallaxViewDelegate> parallaxDelegate;

- (void)matchParallaxOf:(STVParallaxView *)parallaxView;

@end
