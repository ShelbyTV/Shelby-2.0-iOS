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

@protocol ShelbyStreamBrowseProtocol <NSObject>

- (void)userPressedChannel:(DisplayChannel *)channel atItem:(id)item;
//- (void)loadMoreEntriesInChannel:(DisplayChannel *)channel sinceEntry:(NSManagedObject *)entry;
//- (ShelbyBrowseTutorialMode)browseTutorialMode;
//- (void)userDidCompleteTutorial;
@end

@interface ShelbyStreamBrowseViewController : ShelbyViewController <UICollectionViewDataSource, UICollectionViewDelegate, ShelbyStreamBrowseViewCellDelegate>

@property (readonly, strong) DisplayChannel *channel;
@property (nonatomic, assign) id<ShelbyStreamBrowseProtocol>browseDelegate;

- (void)setEntries:(NSArray *)entries
        forChannel:(DisplayChannel *)channel;
- (void)addEntries:(NSArray *)newChannelEntries
             toEnd:(BOOL)shouldAppend
         ofChannel:(DisplayChannel *)channel;
- (NSArray *)entriesForChannel:(DisplayChannel *)channel;
- (NSArray *)deduplicatedEntriesForChannel:(DisplayChannel *)channel;

- (void)focusOnEntity:(id<ShelbyVideoContainer>)entity inChannel:(DisplayChannel *)channel;

@end
