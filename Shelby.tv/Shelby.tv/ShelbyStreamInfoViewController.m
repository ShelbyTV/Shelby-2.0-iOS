//
//  ShelbyStreamInfoViewController.m
//  Shelby.tv
//
//  Created by Keren on 1/8/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyStreamInfoViewController.h"
#import "DashboardEntry.h"
#import "DeduplicationUtility.h"
#import "Frame.h"
#import "ShelbyBrain.h"
#import "ShelbyModelArrayUtility.h"
#import "SPShareController.h"
#import "SPVideoExtractor.h"

#define LOAD_MORE_ACTIVATION_HEIGHT 200
#define NOT_LOADING_MORE -1
#define LOAD_MORE_SPINNER_AREA_HEIGHT 100

NSString * const kShelbyStreamEntryCell = @"StreamEntry";

@interface ShelbyStreamInfoViewController ()
@property (nonatomic, strong) NSArray *channelEntries;
@property (nonatomic, strong) NSArray *deduplicatedEntries;
@property (nonatomic, weak) IBOutlet UITableView *entriesTable;
//refresh and load more
@property (nonatomic, strong) UITableViewController *entriesTableVC;
@property (nonatomic, strong) UIActivityIndicatorView *loadMoreSpinner;
@property (nonatomic, assign) BOOL moreEntriesMayBeAvailable;
@property (nonatomic, assign) CGFloat activationPointOfCurrentLoadMoreRequest;
//sharing
@property (nonatomic, strong) SPShareController *shareController;

@property (nonatomic, strong) NSIndexPath *selectedRowIndexPath;
@end

@implementation ShelbyStreamInfoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.selectedRowIndexPath = nil;
    self.channelEntries = @[];
    //refresh (need a UITableViewController to use the standard ios refresh control)
    self.entriesTableVC = [[UITableViewController alloc] init];
    [self.entriesTableVC willMoveToParentViewController:self];
    self.entriesTableVC.tableView = self.entriesTable;
    [self addChildViewController:self.entriesTableVC];
    self.entriesTableVC.refreshControl = ({
        UIRefreshControl *rc = [[UIRefreshControl alloc] init];
        [rc addTarget:self action:@selector(refreshEntries) forControlEvents:UIControlEventValueChanged];
        rc;
    });
    //load more
    self.loadMoreSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.activationPointOfCurrentLoadMoreRequest = NOT_LOADING_MORE;
    self.moreEntriesMayBeAvailable = NO; // <-- set to yes once we do initial load
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(fetchEntriesDidCompleteForChannelNotification:)
                                                 name:kShelbyBrainFetchEntriesDidCompleteForChannelNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(fetchEntriesDidCompleteForChannelWithErrorNotification:)
                                                 name:kShelbyBrainFetchEntriesDidCompleteForChannelWithErrorNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playbackEntityDidChangeNotification:)
                                                 name:kShelbyVideoReelDidChangePlaybackEntityNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)viewWillAppear:(BOOL)animated
{
    [self.userEducationVC referenceViewWillAppear:self.view.frame animated:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.userEducationVC referenceViewWillDisappear:animated];
}

#pragma mark - public API

- (void)setDisplayChannel:(DisplayChannel *)displayChannel
{
    if (self.displayChannel == nil) {
        _displayChannel = displayChannel;
        if (self.singleVideoEntry) {
            return;
        }
        [[ShelbyDataMediator sharedInstance] fetchEntriesInChannel:displayChannel sinceEntry:nil];
    } else {
        STVDebugAssert(NO, @"changing display channel not implemented");
    }
}

#pragma mark - Notification Handling
- (void)playbackEntityDidChangeNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    DisplayChannel *channel = userInfo[kShelbyVideoReelChannelKey];
    if (channel != self.displayChannel) {
        self.selectedRowIndexPath = nil;
        [self visualizeSelectedCell:nil];
        return;
    }

    id currentEntity = userInfo[kShelbyVideoReelEntityKey];
    NSInteger row = [self.deduplicatedEntries indexOfObject:currentEntity];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
    
    self.selectedRowIndexPath = indexPath;

    [self visualizeSelectedRow:indexPath];
    
    //playing a video == "user educated"
    [self.userEducationVC userHasBeenEducatedAndViewShouldHide:YES];
}

- (void)visualizeSelectedRow:(NSIndexPath *)indexPath
{
    ShelbyStreamEntryCell *cell = (ShelbyStreamEntryCell *)[self.entriesTable cellForRowAtIndexPath:indexPath];
    
    [self visualizeSelectedCell:cell];
}

- (void)visualizeSelectedCell:(ShelbyStreamEntryCell *)cell
{
    NSArray *visibleCells = [self.entriesTable visibleCells];
    [visibleCells makeObjectsPerformSelector:@selector(deselectStreamEntry)];
    
    [cell selectStreamEntry];
}

- (void)fetchEntriesDidCompleteForChannelNotification:(NSNotification *)notification
{
    if (self.singleVideoEntry) {
        return; // should only have one video
    }
    
    NSDictionary *userInfo = notification.userInfo;
    DisplayChannel *channel = userInfo[kShelbyBrainChannelKey];
    if (channel != self.displayChannel) {
        return;
    }
    NSArray *receivedChannelEntries = userInfo[kShelbyBrainChannelEntriesKey];
    BOOL cached = [((NSNumber *)userInfo[kShelbyBrainCachedKey]) boolValue];
    
    if(_channelEntries && [_channelEntries count] && [receivedChannelEntries count]){
        [self mergeCurrentChannelEntriesWithAdditionalChannelEntries:receivedChannelEntries];
    } else {
        // Don't update entries if we have zero entries in cache
        if ([receivedChannelEntries count] != 0 || !cached) {
            [self setEntries:receivedChannelEntries];
        }
        
        if ([receivedChannelEntries count]) {
            [[SPVideoExtractor sharedInstance] warmCacheForVideoContainer:receivedChannelEntries[0]];
        }
    }
    
    //API returns the element represented by the sinceID (therefore we need count > 1)
    [self fetchEntriesWasSuccessful:YES hadEntries:[receivedChannelEntries count] > 1];
}

- (void)fetchEntriesDidCompleteForChannelWithErrorNotification:(NSNotification *)notification
{
    // TODO iPad - simple standard notice of fetch error?
    
    [self fetchEntriesWasSuccessful:NO hadEntries:NO];
}

#pragma mark - UITableDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.deduplicatedEntries count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ShelbyStreamEntryCell *cell = [tableView dequeueReusableCellWithIdentifier:kShelbyStreamEntryCell forIndexPath:indexPath];
    id streamEntry = self.deduplicatedEntries[indexPath.row];
    Frame *videoFrame = nil;
    if ([streamEntry isKindOfClass:[DashboardEntry class]]) {
        videoFrame = ((DashboardEntry *)streamEntry).frame;
    } else if ([streamEntry isKindOfClass:[Frame class]]) {
        videoFrame = (Frame *)streamEntry;
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.videoFrame = videoFrame;
    cell.delegate = self;
    
    if (self.selectedRowIndexPath && self.selectedRowIndexPath.row == indexPath.row) {
        [self visualizeSelectedCell:cell];
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedRowIndexPath = indexPath;
    [self visualizeSelectedRow:indexPath];
    
    [self.videoReelVC playChannel:self.displayChannel
          withDeduplicatedEntries:self.deduplicatedEntries
                          atIndex:indexPath.row];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 360.0;
}

#pragma mark - UIScrollViewDelegate

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    STVAssert(scrollView == self.entriesTable);
    
    if (self.moreEntriesMayBeAvailable &&
        self.activationPointOfCurrentLoadMoreRequest == NOT_LOADING_MORE &&
        scrollView.contentOffset.y + scrollView.bounds.size.height + LOAD_MORE_ACTIVATION_HEIGHT > scrollView.contentSize.height) {
        
        self.activationPointOfCurrentLoadMoreRequest = scrollView.contentOffset.y;
        [self loadMoreEntries];
    }
}

#pragma mark - ShelbyStreamEntryProtocol

- (void)shareVideoWasTappedForFrame:(Frame *)videoFrame
{
    self.shareController = [[SPShareController alloc] initWithVideoFrame:videoFrame
                                                      fromViewController:self
                                                                  atRect:CGRectZero];
    [self.shareController shareWithCompletionHandler:^(BOOL completed) {
        self.shareController = nil;
    }];
}

- (void)likeFrame:(Frame *)videoFrame
{
    [videoFrame doLike];
    //view updates handled via KVO
}

- (void)unLikeFrame:(Frame *)videoFrame
{
    [videoFrame doUnlike];
    //view updates handled via KVO
}

- (void)userProfileWasTapped:(NSString *)userID
{
    [self.delegate userProfileWasTapped:userID];
}

- (void)openLikersViewForVideo:(Video *)video withLikers:(NSMutableOrderedSet *)likers
{
    [self.delegate openLikersViewForVideo:video withLikers:likers];
}

#pragma mark - ShelbyVideoContentBrowsingViewControllerProtocol

- (void)scrollCurrentlyPlayingIntoView
{
    [self.entriesTable scrollToRowAtIndexPath:self.selectedRowIndexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

#pragma mark - Load More & Refresh Helpers

- (void)loadMoreEntries
{
    [[ShelbyDataMediator sharedInstance] fetchEntriesInChannel:self.displayChannel
                                                    sinceEntry:[self.channelEntries lastObject]];
    //show spinner in bottom offset
    self.entriesTable.contentInset = UIEdgeInsetsMake(self.entriesTable.contentInset.top,
                                                      self.entriesTable.contentInset.left,
                                                      self.entriesTable.contentInset.bottom + LOAD_MORE_SPINNER_AREA_HEIGHT,
                                                      self.entriesTable.contentInset.right);
    [self.entriesTable addSubview:self.loadMoreSpinner];
    self.loadMoreSpinner.center = CGPointMake(self.entriesTable.bounds.size.width/2.0f - (self.loadMoreSpinner.bounds.size.width/2.f),
                                              self.entriesTable.contentSize.height + LOAD_MORE_SPINNER_AREA_HEIGHT/2.f);
    self.loadMoreSpinner.hidden = NO;
    [self.loadMoreSpinner startAnimating];
}

- (void)refreshEntries
{
    [[ShelbyDataMediator sharedInstance] fetchEntriesInChannel:self.displayChannel
                                                    sinceEntry:nil];
}

- (void)fetchEntriesWasSuccessful:(BOOL)loadSuccess hadEntries:(BOOL)fetchReturnedEntries
{
    if (self.activationPointOfCurrentLoadMoreRequest != NOT_LOADING_MORE) {
        //LOAD MORE was the request
        if (loadSuccess && !fetchReturnedEntries) {
            self.moreEntriesMayBeAvailable = NO;
        }
        self.activationPointOfCurrentLoadMoreRequest = NOT_LOADING_MORE;
        
        //remove spinner
        [self.loadMoreSpinner stopAnimating];
        [self.loadMoreSpinner removeFromSuperview];
        self.entriesTable.contentInset = UIEdgeInsetsMake(self.entriesTable.contentInset.top,
                                                          self.entriesTable.contentInset.left,
                                                          self.entriesTable.contentInset.bottom - LOAD_MORE_SPINNER_AREA_HEIGHT,
                                                          self.entriesTable.contentInset.right);
        
    } else if (self.entriesTableVC.refreshControl.refreshing) {
        //REFRESH was the request
        [self.entriesTableVC.refreshControl endRefreshing];
        
    } else {
        //fetch requested via non-user mechanism (ie. -[setDisplayChannel:])
    }
}

- (void)setSingleVideoEntry:(NSArray *)singleVideoEntry
{
    _singleVideoEntry = singleVideoEntry;
    self.deduplicatedEntries = self.singleVideoEntry;
}

#pragma mark - Entries Helpers (set & merge entries)

- (void)setEntries:(NSArray *)rawEntries
{
    if (rawEntries == nil) {
        rawEntries = @[];
    }
    
    if (_channelEntries != rawEntries) {
        _channelEntries = [rawEntries copy];
        self.deduplicatedEntries = [DeduplicationUtility deduplicatedCopy:_channelEntries];
        
        [self.videoReelVC setDeduplicatedEntries:self.deduplicatedEntries
                                      forChannel:self.displayChannel];
        [self.entriesTable reloadData];
        
        self.moreEntriesMayBeAvailable = YES;
    }
}

//returns YES if a merge happened
- (BOOL)mergeCurrentChannelEntriesWithAdditionalChannelEntries:(NSArray *)additionalChannelEntries
{
    if (!_channelEntries) {
        _channelEntries = @[];
    }
    
    ShelbyModelArrayUtility *mergeUtil = [ShelbyModelArrayUtility determineHowToMergePossiblyNew:additionalChannelEntries intoExisting:_channelEntries];
    if ([mergeUtil.actuallyNewEntities count]) {
        //update our entries
        _channelEntries = [DeduplicationUtility combineAndSort:mergeUtil.actuallyNewEntities with:_channelEntries];
        self.deduplicatedEntries = [DeduplicationUtility deduplicatedArrayByMerging:mergeUtil.actuallyNewEntities
                                                                        intoDeduped:self.deduplicatedEntries
                                                                          didInsert:nil
                                                                          didDelete:nil
                                                                          didUpdate:nil];
        //update video reel's entries (ignored if we're not current channel)
        [self.videoReelVC setDeduplicatedEntries:self.deduplicatedEntries
                                      forChannel:self.displayChannel];
        //update our view
        [self.entriesTable reloadData];
        
        if (!mergeUtil.actuallyNewEntitiesShouldBeAppended) {
            [[SPVideoExtractor sharedInstance] warmCacheForVideoContainer:mergeUtil.actuallyNewEntities[0]];
            
            //if there's a gap between prepended entities and existing entities, fetch again to fill that gap
            if (mergeUtil.gapAfterNewEntitiesBeforeExistingEntities) {
                [[ShelbyDataMediator sharedInstance] fetchEntriesInChannel:self.displayChannel
                                                                sinceEntry:[mergeUtil.actuallyNewEntities lastObject]];
            }
            return YES;
        }
    } else {
        //full subset, nothing to add
        return NO;
    }
    
    return NO;
}

@end
