//
//  ShelbyStreamInfoViewController.m
//  Shelby.tv
//
//  Created by Keren on 1/8/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyStreamInfoViewController.h"
#import "BrowseChannelsTableViewController.h"
#import "DashboardEntry+Helper.h"
#import "DeduplicationUtility.h"
#import "Frame+Helper.h"
#import "NoContentView.h"
#import "Roll.h"
#import "ShelbyBrain.h"
#import "ShelbyModelArrayUtility.h"
#import "SPShareController.h"
#import "SPVideoExtractor.h"
#import "User+Helper.h"

#define LOAD_MORE_ACTIVATION_HEIGHT 200
#define NOT_LOADING_MORE -1
#define LOAD_MORE_SPINNER_AREA_HEIGHT 100

#define SECTION_COUNT 4
#define SECTION_FOR_ADD_CHANNELS 0
#define SECTION_FOR_CONNECT_SOCIAL 1
#define SECTION_FOR_NO_CONTENT 2
#define SECTION_FOR_PLAYBACK_ENTITIES 3

NSString * const kShelbyStreamEntryCell = @"StreamEntry";
NSString * const kShelbyStreamEntryRecommendedCell = @"StreamEntryRecommended";
NSString * const kShelbyStreamEntryLikeCell = @"ShelbyStreamEntryLike";
NSString * const kShelbyStreamEntryAddChannelsCell = @"AddChannels";
NSString * const kShelbyStreamEntryAddChannelsCollapsedCell = @"AddChannelsCollapsed";
NSString * const kShelbyStreamConnectFacebookCell = @"StreamConnectFB";

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

//for user education "bonus" sections
@property (nonatomic, assign) NSInteger followCount;
@property (nonatomic, assign) BOOL currentUserHasFacebookConnected;
@property (nonatomic, assign) BOOL showNoContentView;
@end

@implementation ShelbyStreamInfoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)awakeFromNib
{
    [self commonInit];
}

- (void)commonInit
{
    _mayShowFollowChannels = NO;
    _followCount = 0;
    _mayShowConnectSocial = NO;
    _currentUserHasFacebookConnected = NO;
    _showNoContentView = NO;
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
                                             selector:@selector(removeFrameNotification:)
                                                 name:kShelbyBrainRemoveFrameNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playbackEntityDidChangeNotification:)
                                                 name:kShelbyVideoReelDidChangePlaybackEntityNotification object:nil];
    
    if (self.mayShowConnectSocial) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshSpecialCellStatus) name:kShelbyNotificationFacebookConnectCompleted object:nil];
    }

    [self.entriesTable registerNib:[UINib nibWithNibName:@"ShelbyStreamEntryRecommendedCellView" bundle:nil] forCellReuseIdentifier:kShelbyStreamEntryRecommendedCell];
    [self.entriesTable registerNib:[UINib nibWithNibName:@"ShelbyStreamEntryCellView" bundle:nil] forCellReuseIdentifier:kShelbyStreamEntryCell];
    [self.entriesTable registerNib:[UINib nibWithNibName:@"ShelbyStreamEntryLikeCellView" bundle:nil] forCellReuseIdentifier:kShelbyStreamEntryLikeCell];
    [self.entriesTable registerNib:[UINib nibWithNibName:@"ShelbyChannelsCellView" bundle:nil] forCellReuseIdentifier:kShelbyStreamEntryAddChannelsCell];
    [self.entriesTable registerNib:[UINib nibWithNibName:@"ShelbyChannelsCollapsedCellView" bundle:nil] forCellReuseIdentifier:kShelbyStreamEntryAddChannelsCollapsedCell];
    [self.entriesTable registerNib:[UINib nibWithNibName:@"StreamConnectFacebookCellView" bundle:nil] forCellReuseIdentifier:kShelbyStreamConnectFacebookCell];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.userEducationVC referenceView:self.view willAppearAnimated:animated];
}

- (void)refreshSpecialCellStatus
{
    if (self.mayShowFollowChannels || self.mayShowConnectSocial) {
        User *currentUser = [User currentAuthenticatedUserInContext:[[ShelbyDataMediator sharedInstance] mainThreadContext]];
        self.followCount = currentUser ? [currentUser rollFollowingCountIgnoringOwnRolls:YES] : 0;
        self.currentUserHasFacebookConnected = [currentUser isFacebookConnected];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
 
    [self refreshSpecialCellStatus];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.userEducationVC referenceViewWillDisappear:animated];
}

#pragma mark - Accessors

- (void)setFollowCount:(NSInteger)followCount
{
    if (_followCount != followCount) {
        _followCount = followCount;
        [self.entriesTable reloadSections:[NSIndexSet indexSetWithIndex:SECTION_FOR_ADD_CHANNELS] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)setCurrentUserHasFacebookConnected:(BOOL)currentUserHasFacebookConnected
{
    if (_currentUserHasFacebookConnected != currentUserHasFacebookConnected) {
        _currentUserHasFacebookConnected = currentUserHasFacebookConnected;
        [self.entriesTable reloadSections:[NSIndexSet indexSetWithIndex:SECTION_FOR_CONNECT_SOCIAL] withRowAnimation:UITableViewRowAnimationFade];
    }
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
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:SECTION_FOR_PLAYBACK_ENTITIES];
    
    self.selectedRowIndexPath = indexPath;

    [self visualizeSelectedRow:indexPath];
}

- (void)visualizeSelectedRow:(NSIndexPath *)indexPath
{
    ShelbyStreamEntryCell *cell = (ShelbyStreamEntryCell *)[self.entriesTable cellForRowAtIndexPath:indexPath];
    
    [self visualizeSelectedCell:cell];
}

- (void)visualizeSelectedCell:(ShelbyStreamEntryCell *)cell
{
    NSArray *visibleIndexPaths = [self.entriesTable indexPathsForVisibleRows];
    if (visibleIndexPaths) {
        for (NSIndexPath *indexPath in visibleIndexPaths) {
            if (indexPath.section == SECTION_FOR_PLAYBACK_ENTITIES) {
                [(id)[self.entriesTable cellForRowAtIndexPath:indexPath] deselectStreamEntry];
            }
        }
    }
    
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
    
    self.showNoContentView = ([self.channelEntries count] == 0);
    if (self.showNoContentView) {
        [self.entriesTable reloadData];
    }
    
    //API returns the element represented by the sinceID (therefore we need count > 1)
    [self fetchEntriesWasSuccessful:YES hadEntries:[receivedChannelEntries count] > 1];
}

- (void)fetchEntriesDidCompleteForChannelWithErrorNotification:(NSNotification *)notification
{
    // TODO iPad - simple standard notice of fetch error?
    
    [self fetchEntriesWasSuccessful:NO hadEntries:NO];
}

- (void)removeFrameNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    DisplayChannel *channel = userInfo[kShelbyBrainChannelKey];
    if (channel != self.displayChannel) {
        return;
    }
    Frame *frameToRemove = userInfo[kShelbyBrainFrameKey];
    
    NSMutableArray *entriesCopy = [self.channelEntries mutableCopy];
    [entriesCopy removeObject:frameToRemove];
    if ([entriesCopy count] != [self.channelEntries count]) {
        [self setEntries:entriesCopy];
        if (self.videoReelVC.currentChannel == self.displayChannel) {
            [self.videoReelVC playChannel:channel
                  withDeduplicatedEntries:self.deduplicatedEntries
                                  atIndex:self.videoReelVC.currentlyPlayingIndexInChannel];
        }
    }
}

#pragma mark - UITableDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return SECTION_COUNT;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == SECTION_FOR_ADD_CHANNELS) {
        return self.mayShowFollowChannels ? 1 : 0;
        
    } else if (section == SECTION_FOR_CONNECT_SOCIAL) {
        return (self.mayShowConnectSocial && !self.currentUserHasFacebookConnected) ? 1 : 0;
        
    } else if (section == SECTION_FOR_NO_CONTENT) {
        return self.showNoContentView ? 1 : 0;
    
    } else if (section == SECTION_FOR_PLAYBACK_ENTITIES) {
        return [self.deduplicatedEntries count];
        
    } else {
        STVAssert(NO, @"unhandled section");
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == SECTION_FOR_ADD_CHANNELS) {
        NSString *cellIdentifier = self.followCount > 2 ? kShelbyStreamEntryAddChannelsCollapsedCell : kShelbyStreamEntryAddChannelsCell;
        return [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
        
    } else if (indexPath.section == SECTION_FOR_CONNECT_SOCIAL) {
        return [tableView dequeueReusableCellWithIdentifier:kShelbyStreamConnectFacebookCell forIndexPath:indexPath];
        
    } else if (indexPath.section == SECTION_FOR_NO_CONTENT) {
        return [NoContentView noActivityView];

    } else if (indexPath.section == SECTION_FOR_PLAYBACK_ENTITIES) {
    
        id streamEntry = self.deduplicatedEntries[indexPath.row];
        NSString *cellIdentifier = nil;
        BOOL recommendedEntry = NO;
        if ([streamEntry isKindOfClass:[DashboardEntry class]]) {
            DashboardEntry *dashboardEntry = (DashboardEntry *)streamEntry;
            if ([dashboardEntry recommendedEntry]) {
                cellIdentifier = kShelbyStreamEntryRecommendedCell;
                recommendedEntry = YES;
            }
        } else if ([streamEntry isKindOfClass:[Frame class]]) {
            Frame *frameEntry = (Frame *)streamEntry;
            if ([frameEntry typeOfFrame] == FrameTypeLightWeight) {
                cellIdentifier = kShelbyStreamEntryLikeCell;
            }
        }
        
        if (!cellIdentifier) {
            cellIdentifier = kShelbyStreamEntryCell;
        }
        
        ShelbyStreamEntryCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
        Frame *videoFrame = nil;
        if ([streamEntry isKindOfClass:[DashboardEntry class]]) {
            videoFrame = ((DashboardEntry *)streamEntry).frame;
        } else if ([streamEntry isKindOfClass:[Frame class]]) {
            videoFrame = (Frame *)streamEntry;
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.videoFrame = videoFrame;
        
        // Overwrite description in case of a recommended entry
        if (recommendedEntry) {
            DashboardEntry *dashboardEntry = (DashboardEntry *)streamEntry;
            if (dashboardEntry.sourceFrameCreatorNickname) {
                NSString *recoBase = @"This video is Liked by people like ";
                NSString *recoUsername = dashboardEntry.sourceFrameCreatorNickname;
                cell.description.text = [NSString stringWithFormat:@"%@%@", recoBase, recoUsername];
            } else if (dashboardEntry.sourceVideoTitle) {
                cell.description.text = [NSString stringWithFormat:@"Because you Liked \"%@\"", dashboardEntry.sourceVideoTitle];
            } else {
                cell.description.text = @"We thought you'd like to see this";
            }
        }
        cell.delegate = self;
        
        if (self.selectedRowIndexPath && self.selectedRowIndexPath.row == indexPath.row) {
            [self visualizeSelectedCell:cell];
        }
        
        return cell;
        
    } else {
        STVAssert(NO, @"unaccounted for section");
        return nil;
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == SECTION_FOR_ADD_CHANNELS) {
        [ShelbyAnalyticsClient sendLocalyticsEvent:kLocalyticsTapAddChannelsInStream];
        BrowseChannelsTableViewController *channelsVC = [[UIStoryboard storyboardWithName:@"BrowseChannels" bundle:nil] instantiateInitialViewController];
        [self.navigationController pushViewController:channelsVC animated:YES];
        channelsVC.userEducationVC = [ShelbyUserEducationViewController newChannelsUserEducationViewController];
        return;
        
    } else if (indexPath.section == SECTION_FOR_CONNECT_SOCIAL) {
        [ShelbyAnalyticsClient sendLocalyticsEvent:kLocalyticsTapConnectFacebookInStream];
        [self.socialConnectDelegate connectToFacebook];
        [tableView cellForRowAtIndexPath:indexPath].selected = NO;
    
    } else if (indexPath.section == SECTION_FOR_PLAYBACK_ENTITIES) {
        [ShelbyAnalyticsClient sendLocalyticsEvent:kLocalyticsTapVideoInStream];
        
        self.selectedRowIndexPath = indexPath;
        [self visualizeSelectedRow:indexPath];
        
        [self.videoReelVC playChannel:self.displayChannel
              withDeduplicatedEntries:self.deduplicatedEntries
                              atIndex:indexPath.row];
        
        [self.userEducationVC userHasBeenEducatedAndViewShouldHide:YES];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == SECTION_FOR_ADD_CHANNELS) {
        return self.followCount > 2 ? 110.0 : 210.0;
        
    } else if (indexPath.section == SECTION_FOR_CONNECT_SOCIAL) {
        return 110.f;
        
    } else if (indexPath.section == SECTION_FOR_NO_CONTENT) {
        return [NoContentView noActivityCellHeight];
    
    } else if (indexPath.section == SECTION_FOR_PLAYBACK_ENTITIES) {
        id streamEntry = self.deduplicatedEntries[indexPath.row];
        if ([streamEntry isKindOfClass:[DashboardEntry class]]) {
            DashboardEntry *dashboardEntry = (DashboardEntry *)streamEntry;
            if ([dashboardEntry recommendedEntry]) {
                return 311.0;
            }
        } else if ([streamEntry isKindOfClass:[Frame class]]) {
            Frame *frameEntry = (Frame *)streamEntry;
            if ([frameEntry typeOfFrame] == FrameTypeLightWeight) {
                return 271.0;
            }
        }
        //what is this for?
        return 341.0;
            
    } else {
        STVAssert(NO, @"unaccoutned for section");
        return 0;
    }
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
        [self.entriesTable reloadData];
        self.moreEntriesMayBeAvailable = YES;
        
        [self.videoReelVC setDeduplicatedEntries:self.deduplicatedEntries
                                      forChannel:self.displayChannel];
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
