//
//  ShelbyStreamBrowseViewController.m
//  Shelby.tv
//
//  Created by Keren on 6/21/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyStreamBrowseViewController.h"
#import "DashboardEntry.h"
#import "Frame.h"
#import "ShelbyStreamBrowseViewCell.h"
#import "Video.h"

@interface ShelbyStreamBrowseViewController ()
@property (nonatomic, strong) NSArray *entries;
@property (nonatomic, strong) NSArray *deduplicatedEntries;

@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;

//hang on to these to keep parallax in sync
@property (nonatomic, strong) NSMutableSet *streamBrowseViewCells;
@property (nonatomic, weak) STVParallaxView *lastUpdatedParallaxView;
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
//        _deduplicatedEntries = [DeduplicationUtility deduplicatedCopy:entries];
    } else {
        _entries = @[];
        _deduplicatedEntries = @[];
    }
    
    [self.collectionView reloadData];

}

- (NSArray *)entriesForChannel:(DisplayChannel *)channel
{
//    NSDictionary *chMetadata = self.channelMetadataByObjectID[channel.objectID];
//    return chMetadata ? chMetadata[kShelbyChannelMetadataEntriesKey] : nil;

    return self.entries;
}


- (void)addEntries:(NSArray *)newChannelEntries
             toEnd:(BOOL)shouldAppend
         ofChannel:(DisplayChannel *)channel

{
    STVAssert(self.channel == channel, @"cannot add entries for a different channel");
    
//    NSMutableArray *indexPathsForInsert, *indexPathsForDelete, *indexPathsForReload;
    
    if(shouldAppend){
        self.entries = [self.entries arrayByAddingObjectsFromArray:newChannelEntries];
//        self.deduplicatedEntries = [DeduplicationUtility deduplicatedArrayByAppending:newChannelEntries
//                                                                       toDedupedArray:self.deduplicatedEntries
//                                                                            didInsert:&indexPathsForInsert
//                                                                            didDelete:&indexPathsForDelete
//                                                                            didUpdate:&indexPathsForReload];
    } else {
        self.entries = [newChannelEntries arrayByAddingObjectsFromArray:self.entries];
//        self.deduplicatedEntries = [DeduplicationUtility deduplicatedArrayByPrepending:newChannelEntries
//                                                                        toDedupedArray:self.deduplicatedEntries
//                                                                             didInsert:&indexPathsForInsert
//                                                                             didDelete:&indexPathsForDelete
//                                                                             didUpdate:&indexPathsForReload];
    }
    
    // The index paths returned by DeduplicationUtility are relative to the original array.
    // So we group them within beginUpdates ... endUpdates
//    [self.collectionView beginUpdates];
//    [self.collectionView insertRowsAtIndexPaths:indexPathsForInsert withRowAnimation:(shouldAppend ? UIColl : UITableViewRowAnimationTop)];
//    [self.collectionView deleteRowsAtIndexPaths:indexPathsForDelete withRowAnimation:UITableViewRowAnimationFade];
//    [self.collectionView reloadRowsAtIndexPaths:indexPathsForReload withRowAnimation:UITableViewRowAnimationAutomatic];
//    [self.collectionView endUpdates];
}

- (NSArray *)deduplicatedEntriesForChannel:(DisplayChannel *)channel
{
    return self.entries; //KP KP: TODO: until we implement dedups
//    return self.deduplicatedEntries;
}


#pragma mark - UICollectionView Datasource
- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section
{
    return [self.entries count];
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView
{
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ShelbyStreamBrowseViewCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"ShelbyStreamBrowseViewCell" forIndexPath:indexPath];
    [self.streamBrowseViewCells addObject:cell];
    cell.parallaxDelegate = self;
    [cell matchParallaxOf:self.lastUpdatedParallaxView];
    cell.entry = self.entries[indexPath.row];

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
    // KP KP: TODO: deal with dedups
    if ([self.browseDelegate respondsToSelector:@selector(userPressedChannel:atItem:)]) {
//            NSArray *dedupedEntries = [self deduplicatedEntriesForChannel:channelCollectionView.channel];
        id entry = nil;
//        if (indexPath.row > 0 && (unsigned)indexPath.row < [dedupedEntries count]) {
        if (indexPath.row > 0 && (unsigned)indexPath.row < [self.entries count]) {
//            entry = dedupedEntries[indexPath.row];
            entry = self.entries[indexPath.row];
        }
        
        [self.browseDelegate userPressedChannel:self.channel atItem:entry];
//            SPVideoItemViewCell *cell = (SPVideoItemViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
//            [cell unHighlightItem];
//        }
    }
}

#pragma mark - UICollectionViewDelegate

#pragma mark - STVParallaxViewDelegate

- (void)parallaxDidChange:(STVParallaxView *)parallaxView
{
    // Keep all the parallax views in sync, as if user is moving the entire collection around 2D space.
    // (as opposed to moving an individual cell independently of the others)
    _lastUpdatedParallaxView = parallaxView;
    // if only 1 cell is visible on screen at a time, the following line is unnecessary
    [self.streamBrowseViewCells makeObjectsPerformSelector:@selector(matchParallaxOf:) withObject:parallaxView];
}



@end
