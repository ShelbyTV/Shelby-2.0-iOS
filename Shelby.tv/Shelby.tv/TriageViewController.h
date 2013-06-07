//
//  TriageViewController.h
//  Shelby.tv
//
//  Created by Keren on 6/3/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DisplayChannel.h"
#import "MCSwipeTableViewCell.h"
#import "ShelbyViewController.h"

@protocol ShelbyTriageProtocol <NSObject>
- (void)userPressedTriageChannel:(DisplayChannel *)channel atItem:(id)item;
- (void)loadMoreEntriesInChannel:(DisplayChannel *)channel sinceEntry:(NSManagedObject *)entry;
@end

@interface TriageViewController : ShelbyViewController <UITableViewDelegate, UITableViewDataSource, MCSwipeTableViewCellDelegate>

@property (readonly, strong) DisplayChannel *channel;
@property (weak, nonatomic) id<ShelbyTriageProtocol> triageDelegate;

// We only have a single channel.  So This replaces the entirety of
// our model (channel, entries, deduplicated entries).
- (void)setEntries:(NSArray *)entries
        forChannel:(DisplayChannel *)channel;
- (void)addEntries:(NSArray *)newChannelEntries
             toEnd:(BOOL)shouldAppend
         ofChannel:(DisplayChannel *)channel;

- (NSArray *)deduplicatedEntriesForChannel:(DisplayChannel *)channel;

@end
