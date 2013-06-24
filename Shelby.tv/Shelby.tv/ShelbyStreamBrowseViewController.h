//
//  ShelbyStreamBrowseViewController.h
//  Shelby.tv
//
//  Created by Keren on 6/21/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DisplayChannel.h"

@interface ShelbyStreamBrowseViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UIScrollViewDelegate>

@property (readonly, strong) DisplayChannel *channel;

- (void)setEntries:(NSArray *)entries
        forChannel:(DisplayChannel *)channel;
- (void)addEntries:(NSArray *)newChannelEntries
             toEnd:(BOOL)shouldAppend
         ofChannel:(DisplayChannel *)channel;

- (NSArray *)deduplicatedEntriesForChannel:(DisplayChannel *)channel;

@end
