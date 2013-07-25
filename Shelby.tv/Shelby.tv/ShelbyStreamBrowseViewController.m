//
//  ShelbyStreamBrowseViewController.m
//  Shelby.tv
//
//  Created by Keren on 6/21/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyStreamBrowseViewController.h"
#import "DashboardEntry.h"
#import "DisplayChannel+Helper.h"
#import "DeduplicationUtility.h"
#import "Frame.h"
#import "NoContentViewController.h"
#import "Video.h"

#define REFRESH_PULL_THRESHOLD 50
#define MAX_CELLS_TO_PREFETCH (NSUInteger)2

@interface ShelbyStreamBrowseViewController (){
    UIInterfaceOrientation _currentlyPresentedInterfaceOrientation;
    BOOL _isRefreshing;
    BOOL _ignorePullToRefresh;
}
@property (nonatomic, strong) NSArray *entries;
@property (nonatomic, strong) NSArray *deduplicatedEntries;

@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *refreshSpinner;

//hang on to these to keep parallax in sync
@property (nonatomic, strong) NSMutableSet *streamBrowseViewCells;
@property (nonatomic, weak) ShelbyStreamBrowseViewCell *lastCellWithParallaxUpdate;

@property (nonatomic, strong) NoContentViewController *noContentVC;
@property (nonatomic, assign) BOOL hasNoContent;
@end

@implementation ShelbyStreamBrowseViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _currentlyPresentedInterfaceOrientation = UIInterfaceOrientationPortrait;
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

    //XXX LAYOUT TESTING
//    self.view.layer.borderColor = [UIColor greenColor].CGColor;
//    self.view.layer.borderWidth = 2.0;
    //XXX LAYOUT TESTING
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self updateVisibilityOfNoContentView];
}

- (void)updateVisibilityOfNoContentView
{
    if ([self.deduplicatedEntries count] == 0) {
        NSString *noContnetViewName = [self.browseManagementDelegate nameForNoContentViewForDisplayChannel:self.channel];
        self.hasNoContent = YES;
        
        if (noContnetViewName && !self.noContentVC) {
            _noContentVC = [[NoContentViewController alloc] initWithNibName:noContnetViewName bundle:nil];
            [self addChildViewController:self.noContentVC];
            [self.view addSubview:self.noContentVC.view];
            [self.noContentVC didMoveToParentViewController:self];
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
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];

    // Need collection view to reload our cells (b/c that's where we size them).
    // But must call this before -didRotate; -reloadData invalidates the view layout.  If we wait until
    // -didRotate, the collectionView is already resized but the cells aren't and iOS logs the glitch.
    [self.collectionView reloadData];

    //We track how our views are currently configured so we can adjust when moving to a parent VC that may be in
    //a different orientation than we were when we were last actively part of a parent VC
    _currentlyPresentedInterfaceOrientation = toInterfaceOrientation;
    
    if ([self isLandscapeOrientation] && UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
        //don't need to do anything if we didn't change! (this happens b/c upside phone isn't supported)
        return;
    }

    CGPoint preRotationContentOffset = self.collectionView.contentOffset;
    NSUInteger preRotationScrollPage = preRotationContentOffset.y / self.view.frame.size.height;
    NSUInteger postRotationContentOffsetY = preRotationScrollPage * self.view.frame.size.width;

    //our browseViewDelegate relies on our frame being correct when -viewDidScroll calls into it
    //so we update contentOffset in -didRotateFromInterfaceOrientation: to make sure context is set up properly for delegate
    [self.collectionView setContentOffset:CGPointMake(self.collectionView.contentOffset.x, postRotationContentOffsetY)];
}

- (void)willMoveToParentViewController:(UIViewController *)parent
{
    //if my orientation is different from my parents, adjust myself
    //NB: Assuming our frame was set correctly before this is called
    if ([[UIApplication sharedApplication] statusBarOrientation] != _currentlyPresentedInterfaceOrientation) {
        UIInterfaceOrientation oldOrientation = _currentlyPresentedInterfaceOrientation;
        [self willRotateToInterfaceOrientation:[[UIApplication sharedApplication] statusBarOrientation] duration:0];
        [self didRotateFromInterfaceOrientation:oldOrientation];
    }
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

    [self updateVisibilityOfNoContentView];
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
    
    [self updateVisibilityOfNoContentView];
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

- (NSIndexPath *)indexPathForCurrentFocus
{
    // if our collection view hasn't yet moved to superview -- isn't on screen -- then it will
    // return nil for -indexPahtsForVisibleItems: but we expect row 0.
    NSIndexPath *idxPath = [[self.collectionView indexPathsForVisibleItems] lastObject];
    if (!idxPath && [self.deduplicatedEntries count] > 0) {
        return [NSIndexPath indexPathForRow:0 inSection:0];
    }
    return idxPath;
}

- (id<ShelbyVideoContainer>)entityForCurrentFocus
{
    NSIndexPath *path = [self indexPathForCurrentFocus];
    if (path) {
        return self.deduplicatedEntries[path.row];
    } else {
        return nil;
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

- (void)browseViewCellParallaxDidChange:(ShelbyStreamBrowseViewCell *)cell
{
    // Keep all the parallax views in sync, as if user is moving the entire collection around 2D space.
    // (as opposed to moving an individual cell independently of the others)
    _lastCellWithParallaxUpdate = cell;
    // if only 1 cell is visible on screen at a time, the following line is unnecessary
    [self.streamBrowseViewCells makeObjectsPerformSelector:@selector(matchParallaxOf:) withObject:cell];
}

- (void)browseViewCellPlayTapped:(ShelbyStreamBrowseViewCell *)cell
{
    if ([self.browseManagementDelegate respondsToSelector:@selector(userPressedChannel:atItem:)]) {
        [self.browseManagementDelegate userPressedChannel:self.channel atItem:cell.entry];
    }
}

- (void)browseViewCell:(ShelbyStreamBrowseViewCell *)cell parallaxDidChangeToPage:(NSUInteger)page
{
    self.currentPage = page;
    [self.browseViewDelegate shelbyStreamBrowseViewController:self didChangeToPage:page];
}

#pragma mark Pull To Refresh Helpers

//pulled should be absolute value
- (void)pullToRefreshForOffset:(CGFloat)pulled
{
    if (_ignorePullToRefresh){ return; }

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
