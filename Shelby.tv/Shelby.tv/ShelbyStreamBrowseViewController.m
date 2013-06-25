//
//  ShelbyStreamBrowseViewController.m
//  Shelby.tv
//
//  Created by Keren on 6/21/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyStreamBrowseViewController.h"
#import "DashboardEntry.h"
#import "DeduplicationUtility.h"
#import "Frame.h"
#import "Video.h"

@interface ShelbyStreamBrowseViewController ()
@property (nonatomic, strong) NSArray *entries;
@property (nonatomic, strong) NSArray *deduplicatedEntries;

@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;

//hang on to these to keep parallax in sync
@property (nonatomic, strong) NSMutableSet *streamBrowseViewCells;
@property (nonatomic, weak) ShelbyStreamBrowseViewCell *lastCellWithParallaxUpdate;
@end

@implementation ShelbyStreamBrowseViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _streamBrowseViewCells = [[NSMutableSet set] mutableCopy];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.collectionView registerClass:[ShelbyStreamBrowseViewCell class] forCellWithReuseIdentifier:@"ShelbyStreamBrowseViewCell"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Setters & Getters
- (void)setEntries:(NSArray *)entries
        forChannel:(DisplayChannel *)channel
{
    _channel = channel;
    if (entries) {
        _entries = entries;
        _deduplicatedEntries = [DeduplicationUtility deduplicatedCopy:entries];
    } else {
        _entries = @[];
        _deduplicatedEntries = @[];
    }
    
    [self.collectionView reloadData];

}

- (NSArray *)entriesForChannel:(DisplayChannel *)channel
{
    return self.entries;
}

- (NSArray *)deduplicatedEntriesForChannel:(DisplayChannel *)channel
{
    return self.deduplicatedEntries;
}

- (void)addEntries:(NSArray *)newChannelEntries
             toEnd:(BOOL)shouldAppend
         ofChannel:(DisplayChannel *)channel

{
    STVAssert(self.channel == channel, @"cannot add entries for a different channel");
    
    NSMutableArray *indexPathsForInsert, *indexPathsForDelete, *indexPathsForReload;

    if(shouldAppend){
        self.entries = [self.entries arrayByAddingObjectsFromArray:newChannelEntries];
        self.deduplicatedEntries = [DeduplicationUtility deduplicatedArrayByAppending:newChannelEntries
                                                                       toDedupedArray:self.deduplicatedEntries
                                                                            didInsert:&indexPathsForInsert
                                                                            didDelete:&indexPathsForDelete
                                                                            didUpdate:&indexPathsForReload];
    } else {
        self.entries = [newChannelEntries arrayByAddingObjectsFromArray:self.entries];
        self.deduplicatedEntries = [DeduplicationUtility deduplicatedArrayByPrepending:newChannelEntries
                                                                        toDedupedArray:self.deduplicatedEntries
                                                                             didInsert:&indexPathsForInsert
                                                                             didDelete:&indexPathsForDelete
                                                                             didUpdate:&indexPathsForReload];
    }
    
    // The index paths returned by DeduplicationUtility are relative to the original array.
    // So we group them within beginUpdates ... endUpdates
    [self.collectionView performBatchUpdates:^{
        [self.collectionView insertItemsAtIndexPaths:indexPathsForInsert];
        [self.collectionView deleteItemsAtIndexPaths:indexPathsForDelete];
        [self.collectionView reloadItemsAtIndexPaths:indexPathsForReload];
    } completion:^(BOOL finished) {
        //nothing
    }];
}

#pragma mark - UICollectionView Datasource
- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section
{
    return [self.deduplicatedEntries count];
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView
{
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ShelbyStreamBrowseViewCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"ShelbyStreamBrowseViewCell" forIndexPath:indexPath];
    [self.streamBrowseViewCells addObject:cell];
    cell.delegate = self;
    [cell matchParallaxOf:self.lastCellWithParallaxUpdate];
    cell.entry = self.deduplicatedEntries[indexPath.row];

//load more data
//    NSInteger cellsBeyond = [dedupedEntries count] - [indexPath row];
//    if(cellsBeyond == kShelbyPrefetchEntriesWhenNearEnd && channelCollection.channel.canFetchRemoteEntries){
//        //since id should come from raw entries, not de-duped entries
//        [self.browseDelegate loadMoreEntriesInChannel:channelCollection.channel
//                                           sinceEntry:[[self entriesForChannel:channelCollection.channel] lastObject]];
//    }

    return cell;
}


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.browseDelegate respondsToSelector:@selector(userPressedChannel:atItem:)]) {
        id entry = nil;
        if (indexPath.row > 0 && (unsigned)indexPath.row < [self.deduplicatedEntries count]) {
            entry = self.deduplicatedEntries[indexPath.row];
        }
        
        [self.browseDelegate userPressedChannel:self.channel atItem:entry];
//            SPVideoItemViewCell *cell = (SPVideoItemViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
//            [cell unHighlightItem];
//        }
    }
}

#pragma mark - UICollectionViewDelegate

#pragma mark - ShelbyStreamBrowseViewCellDelegate

- (void)parallaxDidChange:(ShelbyStreamBrowseViewCell *)cell
{
    // Keep all the parallax views in sync, as if user is moving the entire collection around 2D space.
    // (as opposed to moving an individual cell independently of the others)
    _lastCellWithParallaxUpdate = cell;
    // if only 1 cell is visible on screen at a time, the following line is unnecessary
    [self.streamBrowseViewCells makeObjectsPerformSelector:@selector(matchParallaxOf:) withObject:cell];
}

- (void)didScrollForPlayback:(ShelbyStreamBrowseViewCell *)cell
{
    if ([self.browseDelegate respondsToSelector:@selector(userPressedChannel:atItem:)]) {
        [self.browseDelegate userPressedChannel:self.channel atItem:cell.entry];
    }
}

@end
