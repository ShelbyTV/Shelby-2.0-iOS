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
@property (weak, nonatomic) IBOutlet SPChannelCollectionView *channelCollectionView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *refreshActivityIndicator;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadMoreActivityIndicator;

@property (strong, nonatomic) UIColor *color;
@property (strong, nonatomic) NSString *title;

// 1) increase this from 0.0 to 1.0 as user pulls toward pull-to-refresh boundary
- (void)setProximityToRefreshMode:(float)pct;
// 2) when user pull crosses the pull-to-refresh boundary, set this accordingly
@property (assign, nonatomic) BOOL willRefresh;
// 3) set this when actual data refreshing starts/ends
@property (assign, nonatomic) BOOL isRefreshing;

@end
