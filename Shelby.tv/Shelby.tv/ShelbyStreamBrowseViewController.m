//
//  ShelbyStreamBrowseViewController.m
//  Shelby.tv
//
//  Created by Keren on 6/21/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyStreamBrowseViewController.h"
#import "ShelbyStreamBrowseCollectionViewFlowLayout.h"
#import "DashboardEntry.h"
#import "DisplayChannel+Helper.h"
#import "DeduplicationUtility.h"
#import "Frame.h"
#import "Video.h"

#define REFRESH_PULL_THRESHOLD 50
#define MAX_CELLS_TO_PREFETCH (NSUInteger)2

@interface ShelbyStreamBrowseViewController (){
    UIInterfaceOrientation _currentlyPresentedInterfaceOrientation;
    BOOL _isRefreshing;
    BOOL _ignorePullToRefresh;
}
@property (nonatomic, strong) NSArray *entries;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *refreshSpinner;

//hang on to these to keep parallax in sync
@property (nonatomic, strong) NSMutableSet *streamBrowseViewCells;
@property (nonatomic, weak) ShelbyStreamBrowseViewCell *lastCellWithParallaxUpdate;

@property (nonatomic, strong) NoContentViewController *noContentVC;
@property (nonatomic, assign) BOOL hasNoContent;

@property (nonatomic) NSUInteger preRotationScrollPage;

@end

@implementation ShelbyStreamBrowseViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _currentlyPresentedInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        _streamBrowseViewCells = [[NSMutableSet set] mutableCopy];
        _viewMode = ShelbyStreamBrowseViewDefault;
        _currentPage = 0;
        _isRefreshing = NO;
        _ignorePullToRefresh = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.collectionView registerClass:[ShelbyStreamBrowseViewCell class] forCellWithReuseIdentifier:@"ShelbyStreamBrowseViewCell"];
    self.collectionView.pagingEnabled = YES;

    //a safe tap gesture recognizer for our browseViewDelegate
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(overlayTap:)];
    tap.numberOfTapsRequired = 1;
    tap.numberOfTouchesRequired = 1;
    [tap requireGestureRecognizerToFail:self.collectionView.panGestureRecognizer];
    [self.collectionView addGestureRecognizer:tap];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self updateVisibilityOfNoContentView];

    // Our parent sets our frame, which may be different than the last time we were on screen.
    // If so, need to adjust the collection view appropriately (we can reuse our willRotate logic)
    if ([[UIApplication sharedApplication] statusBarOrientation] != _currentlyPresentedInterfaceOrientation) {
        UIInterfaceOrientation oldOrientation = _currentlyPresentedInterfaceOrientation;
        [self willRotateToInterfaceOrientation:[[UIApplication sharedApplication] statusBarOrientation] duration:0];
        self.collectionView.frame = self.view.frame;
        [self didRotateFromInterfaceOrientation:oldOrientation];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [ShelbyAnalyticsClient trackScreen:[NSString stringWithFormat:@"Browse - %@", self.channel.displayTitle]];
}

// This is kinda of a hack. Maybe it's time to take this code out of the brain?
- (NSString *)noContentViewName
{
    return [self.browseManagementDelegate nameForNoContentViewForDisplayChannel:self.channel];
}

- (void)setupNoContentView:(NoContentViewController *)noContentView withTitle:(NSString *)title
{
    // No-op for this VC. Subclasses might modify this controller.
}

- (void)updateVisibilityOfNoContentView
{
    if ([self.deduplicatedEntries count] == 0) {
        NSString *noContnetViewName = [self noContentViewName];
        self.hasNoContent = YES;
        
        if (noContnetViewName && !self.noContentVC) {
            _noContentVC = [[NoContentViewController alloc] initWithNibName:noContnetViewName bundle:nil];
            [self addChildViewController:self.noContentVC];
            [self.view addSubview:self.noContentVC.view];
            [self.noContentVC didMoveToParentViewController:self];
            [self setupNoContentView:self.noContentVC withTitle:self.channel.titleOverride];
        }
    } else {
        [self.browseViewDelegate shelbyStreamBrowseViewController:self hasNoContnet:NO];
        self.hasNoContent = NO;
        if (self.noContentVC.view) {
            [self.noContentVC removeFromParentViewController];
            [self.noContentVC.view removeFromSuperview];
            self.noContentVC = nil;
        }
    }
}

- (void)setHasNoContent:(BOOL)hasNoContent
{
    _hasNoContent = hasNoContent;
    [self.browseViewDelegate shelbyStreamBrowseViewController:self hasNoContnet:hasNoContent];
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
    if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation) && UIInterfaceOrientationIsLandscape(_currentlyPresentedInterfaceOrientation)) {
        //don't need to do anything if we didn't change! (this happens b/c upside phone isn't supported)
        return;
    }

    // the cells above and below the currently visible cell don't need to pop into
    // view momentarily during the animation, so we hide them, to be made visible again
    // after the rotation
    NSArray *indexPathsForVisibleItems = self.collectionView.indexPathsForVisibleItems;
    NSLog(@"Visible items before: %lu", (unsigned long)[indexPathsForVisibleItems count]);
    if ([indexPathsForVisibleItems count]) {
        NSIndexPath *indexPathForFirstVisibleItem = [indexPathsForVisibleItems firstObject];

        ShelbyStreamBrowseCollectionViewFlowLayout *flowLayout = (ShelbyStreamBrowseCollectionViewFlowLayout *) self.collectionView.collectionViewLayout;
        flowLayout.indexPathsToBeShown = @[indexPathForFirstVisibleItem];
    }

    // Need collection view to reload our cells (b/c that's where we size them).
    // But must call this before -didRotate; -reloadData invalidates the view layout.  If we wait until
    // -didRotate, the collectionView is already resized but the cells aren't and iOS logs the glitch.
//    [self.collectionView reloadData];

    //We track how our views are currently configured so we can adjust when moving to a parent VC that may be in
    //a different orientation than we were when we were last actively part of a parent VC
    _currentlyPresentedInterfaceOrientation = toInterfaceOrientation;

    self.preRotationScrollPage = self.collectionView.contentOffset.y / self.collectionView.frame.size.height;

    [self.collectionView.collectionViewLayout invalidateLayout];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    //need to set content size (it's too small when going landscape -> portrait; contentOffset can't be set if post rotation Y > current height)
    self.collectionView.contentSize = CGSizeMake(self.collectionView.bounds.size.width, self.collectionView.bounds.size.height * [self.deduplicatedEntries count]);
    //our browseViewDelegate relies on our frame being correct when -viewDidScroll calls into it.
    //We update contentOffset in -willRotateToInterfaceOrientation: to make sure context is set up properly for delegate
    [self.collectionView setContentOffset:CGPointMake(self.collectionView.contentOffset.x, self.preRotationScrollPage * self.collectionView.bounds.size.height) animated:NO];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    ShelbyStreamBrowseCollectionViewFlowLayout *flowLayout = (ShelbyStreamBrowseCollectionViewFlowLayout *) self.collectionView.collectionViewLayout;
    flowLayout.indexPathsToBeShown = @[];

    [self.collectionView.collectionViewLayout invalidateLayout];
}

- (void)scrollToTop
{
    [self.collectionView scrollRectToVisible:CGRectMake(0, 0, 100, 100) animated:YES];
}

#pragma mark - Setters & Getters
- (void)setEntries:(NSArray *)entries
        forChannel:(DisplayChannel *)channel
{
    @synchronized(self) {
        _channel = channel;
        if (entries) {
            _entries = entries;
            _deduplicatedEntries = [DeduplicationUtility deduplicatedCopy:entries];
        } else {
            _entries = @[];
            _deduplicatedEntries = @[];
        }
        
        [self.collectionView reloadData];

        [self updateVisibilityOfNoContentView];
    }
}

- (NSArray *)entriesForChannel:(DisplayChannel *)channel
{
    @synchronized(self) {
        return self.entries;
    }
}

- (NSArray *)deduplicatedEntriesForChannel:(DisplayChannel *)channel
{
    @synchronized(self) {
        return self.deduplicatedEntries;
    }
}

- (void)addEntries:(NSArray *)newChannelEntries
             toEnd:(BOOL)shouldAppend
         ofChannel:(DisplayChannel *)channel
maintainingCurrentFocus:(BOOL)shouldMaintainCurrentFocus

{
    STVAssert(self.channel == channel, @"cannot add entries for a different channel");

    @synchronized(self) {
        NSMutableArray *indexPathsForInsert, *indexPathsForDelete, *indexPathsForReload;
        id<ShelbyVideoContainer> focusedEntityBeforeUpdates = [self entityForCurrentFocus];

        self.entries = [DeduplicationUtility combineAndSort:newChannelEntries with:self.entries];
        _deduplicatedEntries = [DeduplicationUtility deduplicatedArrayByMerging:newChannelEntries
                                                                    intoDeduped:self.deduplicatedEntries
                                                                      didInsert:&indexPathsForInsert
                                                                      didDelete:&indexPathsForDelete
                                                                      didUpdate:&indexPathsForReload
                                                                      inSection:0];

        // The index paths returned by DeduplicationUtility are relative to the original array.
        // So we group them within performBatchUpdates:
        if (shouldMaintainCurrentFocus || !_isRefreshing) {
            [self.collectionView reloadData];
            [self focusOnEntity:focusedEntityBeforeUpdates inChannel:channel animated:NO];
        } else {
            [self.collectionView performBatchUpdates:^{
                [self.collectionView insertItemsAtIndexPaths:indexPathsForInsert];
                [self.collectionView deleteItemsAtIndexPaths:indexPathsForDelete];
                [self.collectionView reloadItemsAtIndexPaths:indexPathsForReload];
            } completion:nil];
        }
        
        [self updateVisibilityOfNoContentView];
    }
}

#pragma mark - UICollectionView Datasource
- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section
{
    @synchronized(self) {
        return [self.deduplicatedEntries count];
    }
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView
{
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    @synchronized(self) {
        ShelbyStreamBrowseViewCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"ShelbyStreamBrowseViewCell" forIndexPath:indexPath];
        [self.streamBrowseViewCells addObject:cell];
        cell.delegate = self;
        cell.viewMode = self.viewMode;
        cell.entry = self.deduplicatedEntries[indexPath.row];

        [cell matchParallaxOf:self.lastCellWithParallaxUpdate];

        //load more data
        NSInteger cellsBeyond = [self.deduplicatedEntries count] - [indexPath row];
        if(cellsBeyond == kShelbyPrefetchEntriesWhenNearEnd && self.channel.canFetchRemoteEntries){
            //since id should come from raw entries, not de-duped entries
            [self.browseManagementDelegate loadMoreEntriesInChannel:self.channel
                                                         sinceEntry:[self.entries lastObject]];
        }

        //prefetch next couple of cells
        NSRange prefetchRange;
        prefetchRange.location = indexPath.row + 1;
        //length may be zero, which will result in empty array
        prefetchRange.length = MIN(MAX_CELLS_TO_PREFETCH, [self.deduplicatedEntries count] - indexPath.row - 1);
        for (id<ShelbyVideoContainer> svc in [self.deduplicatedEntries subarrayWithRange:prefetchRange]) {
            [ShelbyStreamBrowseViewCell cacheEntry:svc];
        }

        return cell;
    }
}

- (void)focusOnEntity:(id<ShelbyVideoContainer>)entity inChannel:(DisplayChannel *)channel animated:(BOOL)animated
{
    @synchronized(self) {
        STVDebugAssert(channel == self.channel, @"expected our channel");
        while ([entity respondsToSelector:@selector(duplicateOf)] && ((id<ShelbyDuplicateContainer>)entity).duplicateOf) {
            if (((id<ShelbyDuplicateContainer>)entity).duplicateOf == entity) {
                DLog(@"***avoiding infinite loop where entity is a duplicate of itself*** %@", entity);
                break;
            }
            entity = ((id<ShelbyDuplicateContainer>)entity).duplicateOf;
        }
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:[self.deduplicatedEntries indexOfObject:entity] inSection:0];
        if (indexPath.row == NSNotFound) {
            STVDebugAssert(indexPath.row != NSNotFound, @"expected to find the entity, or its dupe parent");
            return;
        }
        [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:animated];
    }
}

- (void)setViewMode:(ShelbyStreamBrowseViewMode)viewMode
{
    if (_viewMode != viewMode) {
        _viewMode = viewMode;
        for (ShelbyStreamBrowseViewCell *cell in self.streamBrowseViewCells) {
            cell.viewMode = _viewMode;
        }
    }
}

- (NSInteger)sectionForVideoCards
{
    return 0;
}

- (NSIndexPath *)indexPathForCurrentFocus
{
    @synchronized(self) {
        // if our collection view hasn't yet moved to superview -- isn't on screen -- then it will
        // return nil for -indexPathsForVisibleItems: but we expect row 0.
        NSIndexPath *idxPath = [self.collectionView indexPathForItemAtPoint:CGPointMake(self.collectionView.contentOffset.x + self.collectionView.frame.size.width/2.f, self.collectionView.contentOffset.y + self.collectionView.frame.size.height/2.f)];
        if (!idxPath && [self.deduplicatedEntries count] > 0) {
            if (self.collectionView.contentOffset.y > self.collectionView.frame.size.height) {
                return [NSIndexPath indexPathForRow:[self.deduplicatedEntries count]-1
                                          inSection:[self sectionForVideoCards]];
            } else {
                return [NSIndexPath indexPathForRow:0
                                          inSection:[self sectionForVideoCards]];
            }
        }
        return idxPath;
    }
}

- (id<ShelbyVideoContainer>)entityForCurrentFocus
{
    @synchronized(self) {
        NSIndexPath *path = [self indexPathForCurrentFocus];
        if (path) {
            return self.deduplicatedEntries[path.row];
        } else {
            return nil;
        }
    }
}

#pragma mark - UICollectionViewDelegate (actually UIScrollViewDelegate)
// The browseViewDelegate may use us as "lead view", adjusting other views programatically

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.browseViewDelegate shelbyStreamBrowseViewController:self didScrollTo:scrollView.contentOffset];

    if (scrollView.contentOffset.y < 0) {
        [self pullToRefreshForOffset:-(scrollView.contentOffset.y)];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self.browseViewDelegate shelbyStreamBrowseViewControllerDidEndDecelerating:self];
    [self pullToRefreshNoteDidEndDecelerating];
}

#pragma mark - UITapGestureRecognizer handler

- (void)overlayTap:(UITapGestureRecognizer *)gestureRecognizer
{
    [self.browseViewDelegate shelbyStreamBrowseViewController:self wasTapped:gestureRecognizer];
}

#pragma mark - UICollectionViewDelegateFlowLayout methods
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return self.view.frame.size;
}

#pragma mark - ShelbyStreamBrowseViewCellDelegate
- (void)openLikersView:(ShelbyStreamBrowseViewCell *)cell withLikers:(NSMutableOrderedSet *)likers
{
    [self.browseViewDelegate openLikersView:cell.entry withLikers:likers];
}

- (void)shareVideo:(ShelbyStreamBrowseViewCell *)cell
{
    [self.browseViewDelegate shareCurrentVideo:cell.entry];
}

- (void)browseViewCellParallaxDidChange:(ShelbyStreamBrowseViewCell *)cell
{
    // Keep all the parallax views in sync, as if user is moving the entire collection around 2D space.
    // (as opposed to moving an individual cell independently of the others)
    _lastCellWithParallaxUpdate = cell;
    // if only 1 cell is visible on screen at a time, the following line is unnecessary
    [self.streamBrowseViewCells makeObjectsPerformSelector:@selector(matchParallaxOf:) withObject:cell];

    [self.browseViewDelegate shelbyStreamBrowseViewController:self cellParallaxDidChange:cell];
}

- (void)browseViewCell:(ShelbyStreamBrowseViewCell *)cell parallaxDidChangeToPage:(NSUInteger)page
{
    self.currentPage = page;
    [self.browseViewDelegate shelbyStreamBrowseViewController:self didChangeToPage:page];
}

- (void)browseViewCellTitleWasTapped:(ShelbyStreamBrowseViewCell *)cell
{
    [self.browseViewDelegate shelbyStreamBrowseViewControllerTitleTapped:self];
}

- (void)inviteFacebookFriendsWasTapped:(ShelbyStreamBrowseViewCell *)cell
{
    [self.browseViewDelegate inviteFacebookFriendsWasTapped:self];
}

- (void)userProfileWasTapped:(ShelbyStreamBrowseViewCell *)cell withUserID:(NSString *)userID
{
    [self.browseViewDelegate userProfileWasTapped:self withUserID:userID];
}

#pragma mark Pull To Refresh Helpers

//pulled should be absolute value
- (void)pullToRefreshForOffset:(CGFloat)pulled
{
    if (_ignorePullToRefresh || !self.channel.canFetchRemoteEntries){
        return;
    }

    if (pulled > REFRESH_PULL_THRESHOLD) {
        [self pullToRefreshStartRefreshing];
    } else if (!_isRefreshing) {
        self.refreshSpinner.alpha = pulled / REFRESH_PULL_THRESHOLD;
    }
}

- (void)pullToRefreshStartRefreshing
{
    if (!_isRefreshing) {
        _ignorePullToRefresh = YES;
        _isRefreshing = YES;
        self.refreshSpinner.alpha = 1.0;
        [self.refreshSpinner startAnimating];
        [self.browseManagementDelegate loadMoreEntriesInChannel:self.channel sinceEntry:nil];
    }
}

- (void)pullToRefreshNoteDidEndDecelerating
{
    // _ignorePullToRefresh is used as a latch, so we only refresh once per pull
    _ignorePullToRefresh = NO;
}

- (void)pullToRefreshDoneRefreshing
{
    self.refreshSpinner.alpha = 0.0;
    [self.refreshSpinner stopAnimating];
    _isRefreshing = NO;
}

//we start the spinner ourselves, only care about stopping
- (void)refreshActivityIndicatorShouldAnimate:(BOOL)shouldAnimate
{
    if (!shouldAnimate) {
        [self pullToRefreshDoneRefreshing];
    }
}

@end
