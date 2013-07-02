//
//  ShelbyStreamBrowseViewController.h
//  Shelby.tv
//
//  Created by Keren on 6/21/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DisplayChannel.h"
#import "ShelbyStreamBrowseViewCell.h"
#import "ShelbyViewController.h"

@class ShelbyStreamBrowseViewController;

// For interaction and data-model related stuff.
@protocol ShelbyStreamBrowseManagementDelegate <NSObject>
- (void)userPressedChannel:(DisplayChannel *)channel atItem:(id)item;
//- (void)loadMoreEntriesInChannel:(DisplayChannel *)channel sinceEntry:(NSManagedObject *)entry;
//- (ShelbyBrowseTutorialMode)browseTutorialMode;
//- (void)userDidCompleteTutorial;
@end

// For view-specific updates
@protocol ShelbyStreamBrowseViewDelegate <NSObject>
- (void)shelbyStreamBrowseViewController:(ShelbyStreamBrowseViewController *)vc didScrollTo:(CGPoint)contentOffset;
- (void)shelbyStreamBrowseViewControllerDidEndDecelerating:(ShelbyStreamBrowseViewController *)vc;
@end

@interface ShelbyStreamBrowseViewController : ShelbyViewController <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, ShelbyStreamBrowseViewCellDelegate>

@property (readonly, strong) DisplayChannel *channel;
// For interaction and data-model related stuff.
@property (nonatomic, assign) id<ShelbyStreamBrowseManagementDelegate>browseManagementDelegate;
// For view-specific updates (ie. to let us be the "lead" view and programatically update other views)
@property (nonatomic, assign) id<ShelbyStreamBrowseViewDelegate>browseViewDelegate;

//changes the view mode for all children appropriately
@property (nonatomic, assign) ShelbyStreamBrowseViewMode viewMode;

- (void)setEntries:(NSArray *)entries
        forChannel:(DisplayChannel *)channel;
- (void)addEntries:(NSArray *)newChannelEntries
             toEnd:(BOOL)shouldAppend
         ofChannel:(DisplayChannel *)channel;
- (NSArray *)entriesForChannel:(DisplayChannel *)channel;
- (NSArray *)deduplicatedEntriesForChannel:(DisplayChannel *)channel;

- (void)focusOnEntity:(id<ShelbyVideoContainer>)entity inChannel:(DisplayChannel *)channel;

- (NSIndexPath *)indexPathForCurrentFocus;

@end
