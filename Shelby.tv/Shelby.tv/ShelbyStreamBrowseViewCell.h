//
//  ShelbyStreamBrowseViewCell.h
//  Shelby.tv
//
//  Created by Keren on 6/21/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ShelbyVideoContainer.h"
#import "StreamBrowseCellForegroundView.h"
#import "STVParallaxView.h"

typedef NS_ENUM(NSUInteger, ShelbyStreamBrowseViewMode)
{
    ShelbyStreamBrowseViewDefault,
    ShelbyStreamBrowseViewForPlaybackWithOverlay,
    ShelbyStreamBrowseViewForPlaybackWithoutOverlay,
    ShelbyStreamBrowseViewForPlaybackPeeking,
    ShelbyStreamBrowseViewForAirplay
};

@class ShelbyStreamBrowseViewCell;

@protocol ShelbyStreamBrowseViewCellDelegate <NSObject>
- (void)browseViewCellParallaxDidChange:(ShelbyStreamBrowseViewCell *)cell;
- (void)browseViewCell:(ShelbyStreamBrowseViewCell *)cell parallaxDidChangeToPage:(NSUInteger)page;
- (void)browseViewCellTitleWasTapped:(ShelbyStreamBrowseViewCell *)cell;
- (void)inviteFacebookFriendsWasTapped:(ShelbyStreamBrowseViewCell *)cell;
- (void)userProfileWasTapped:(ShelbyStreamBrowseViewCell *)cell withUserID:(NSString *)userID;
@end

@interface ShelbyStreamBrowseViewCell : UICollectionViewCell <STVParallaxViewDelegate, StreamBrowseCellForegroundViewDelegate>

//a Frame or DashboardEntry
@property (nonatomic, strong) id<ShelbyVideoContainer> entry;

@property (nonatomic, weak) id<ShelbyStreamBrowseViewCellDelegate> delegate;

@property (nonatomic, assign) ShelbyStreamBrowseViewMode viewMode;

+ (void)cacheEntry:(id<ShelbyVideoContainer>) entry;

- (void)matchParallaxOf:(ShelbyStreamBrowseViewCell *)cell;

@end
