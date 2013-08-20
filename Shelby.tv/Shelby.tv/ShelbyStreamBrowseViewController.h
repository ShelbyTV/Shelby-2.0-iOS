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
- (void)loadMoreEntriesInChannel:(DisplayChannel *)channel sinceEntry:(NSManagedObject *)entry;
- (NSString *)nameForNoContentViewForDisplayChannel:(DisplayChannel *)channel;
//- (ShelbyBrowseTutorialMode)browseTutorialMode;
//- (void)userDidCompleteTutorial;
@end

// For view-specific updates
@protocol ShelbyStreamBrowseViewDelegate <NSObject>
- (void)shelbyStreamBrowseViewController:(ShelbyStreamBrowseViewController *)vc didScrollTo:(CGPoint)contentOffset;
- (void)shelbyStreamBrowseViewControllerDidEndDecelerating:(ShelbyStreamBrowseViewController *)vc;
//indicates a single, 1 touch tap that waits for all panning to fail
- (void)shelbyStreamBrowseViewController:(ShelbyStreamBrowseViewController *)vc wasTapped:(UITapGestureRecognizer *)tapGestureRecognizer;
- (void)shelbyStreamBrowseViewController:(ShelbyStreamBrowseViewController *)vc cellParallaxDidChange:(ShelbyStreamBrowseViewCell *)cell;
- (void)shelbyStreamBrowseViewController:(ShelbyStreamBrowseViewController *)vc didChangeToPage:(NSUInteger)page;
- (void)shelbyStreamBrowseViewController:(ShelbyStreamBrowseViewController *)vc hasNoContnet:(BOOL)noContent;
- (void)shelbyStreamBrowseViewControllerTitleTapped:(ShelbyStreamBrowseViewController *)vc;
@end

@interface ShelbyStreamBrowseViewController : ShelbyViewController <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, ShelbyStreamBrowseViewCellDelegate>

@property (readonly, strong) NSArray *deduplicatedEntries;
@property (readonly, strong) DisplayChannel *channel;
// For interaction and data-model related stuff.
@property (nonatomic, assign) id<ShelbyStreamBrowseManagementDelegate>browseManagementDelegate;
// For view-specific updates (ie. to let us be the "lead" view and programatically update other views)
@property (nonatomic, assign) id<ShelbyStreamBrowseViewDelegate>browseViewDelegate;

//changes the view mode for all children appropriately
@property (nonatomic, assign) ShelbyStreamBrowseViewMode viewMode;

- (void)setEntries:(NSArray *)entries
        forChannel:(DisplayChannel *)channel;
//when appending entries, the collection view will be scrolled down accordingly
//if you don't want that behavior, you can request that we maintain the current
//focus.  This will have the effect of resetting our focus after
//inserting the new cells.
- (void)addEntries:(NSArray *)newChannelEntries
             toEnd:(BOOL)shouldAppend
         ofChannel:(DisplayChannel *)channel
maintainingCurrentFocus:(BOOL)shouldMaintainCurrentFocus;
- (NSArray *)entriesForChannel:(DisplayChannel *)channel;
- (NSArray *)deduplicatedEntriesForChannel:(DisplayChannel *)channel;

- (void)focusOnEntity:(id<ShelbyVideoContainer>)entity inChannel:(DisplayChannel *)channel;

- (void)scrollToTop;

- (void)refreshActivityIndicatorShouldAnimate:(BOOL)shouldAnimate;

- (NSIndexPath *)indexPathForCurrentFocus;
- (id<ShelbyVideoContainer>)entityForCurrentFocus;

//which page (of the parallax of the cells) is currently showing
@property (nonatomic, assign) NSUInteger currentPage;

// To allow our superview to adjust visual stylings
@property (readonly) UICollectionView *collectionView;
@property (nonatomic, readonly) BOOL hasNoContent;

@end
