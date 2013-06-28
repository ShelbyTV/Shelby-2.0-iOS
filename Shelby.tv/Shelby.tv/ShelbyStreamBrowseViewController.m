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
        _viewMode = ShelbyStreamBrowseViewDefault;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.collectionView registerClass:[ShelbyStreamBrowseViewCell class] forCellWithReuseIdentifier:@"ShelbyStreamBrowseViewCell"];

    self.collectionView.pagingEnabled = YES;

    //XXX LAYOUT TESTING
    self.view.layer.borderColor = [UIColor greenColor].CGColor;
    self.view.layer.borderWidth = 2.0;
    //XXX LAYOUT TESTING
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscape | UIInterfaceOrientationMaskPortrait;
}

-(BOOL) shouldAutorotate {
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    [self.collectionView reloadData];

    // KP KP: TODO: this is where we need to make sure that the same cell is the one visible on the screen - from before and after rotation
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
    cell.viewMode = self.viewMode;
    cell.entry = self.deduplicatedEntries[indexPath.row];

    [cell updateParallaxFrame:self.view.frame];

//load more data
//    NSInteger cellsBeyond = [dedupedEntries count] - [indexPath row];
//    if(cellsBeyond == kShelbyPrefetchEntriesWhenNearEnd && channelCollection.channel.canFetchRemoteEntries){
//        //since id should come from raw entries, not de-duped entries
//        [self.browseDelegate loadMoreEntriesInChannel:channelCollection.channel
//                                           sinceEntry:[[self entriesForChannel:channelCollection.channel] lastObject]];
//    }

    return cell;
}

- (void)focusOnEntity:(id<ShelbyVideoContainer>)entity inChannel:(DisplayChannel *)channel
{
    STVAssert(channel == self.channel, @"expected our channel");
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:[self.deduplicatedEntries indexOfObject:entity] inSection:0];
    STVAssert(indexPath.row != NSNotFound, @"expected to find the entity");
    [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:YES];
}

- (void)setViewMode:(ShelbyStreamBrowseViewMode)viewMode
{
    if (_viewMode != viewMode) {
        _viewMode = viewMode;
        //XXX this is not the proper UX logic, just helpful during dev
        for (ShelbyStreamBrowseViewCell *cell in self.streamBrowseViewCells) {
            cell.viewMode = _viewMode;
        }
    }
}

- (BOOL)isLandscapeOrientation
{
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    return UIInterfaceOrientationIsLandscape(orientation);
}

#pragma mark - UICollectionViewDelegate (actually UIScrollViewDelegate)
// The browseViewDelegate may use us as "lead view", adjusting other views programatically

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.browseViewDelegate shelbyStreamBrowseViewController:self didScrollTo:scrollView.contentOffset];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self.browseViewDelegate shelbyStreamBrowseViewControllerDidEndDecelerating:self];
}

#pragma mark - UICollectionViewDelegateFlowLayout methods
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return self.view.frame.size;
}

#pragma mark - ShelbyStreamBrowseViewCellDelegate

- (void)parallaxDidChange:(ShelbyStreamBrowseViewCell *)cell
{
    // Keep all the parallax views in sync, as if user is moving the entire collection around 2D space.
    // (as opposed to moving an individual cell independently of the others)
    _lastCellWithParallaxUpdate = cell;
    // if only 1 cell is visible on screen at a time, the following line is unnecessary
    [self.streamBrowseViewCells makeObjectsPerformSelector:@selector(matchParallaxOf:) withObject:cell];
}

- (void)playTapped:(ShelbyStreamBrowseViewCell *)cell
{
    if ([self.browseManagementDelegate respondsToSelector:@selector(userPressedChannel:atItem:)]) {
        [self.browseManagementDelegate userPressedChannel:self.channel atItem:cell.entry];
    }
}

@end
