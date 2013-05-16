//
//  BrowseViewController.m
//  Shelby.tv
//
//  Created by Keren on 2/13/13.
//  Copyright (c) 2013 Shelby TV. All rights reserved.
//

#import "BrowseViewController.h"

#import "AFNetworking.h"
#import "DeduplicationUtility.h"
#import "DisplayChannel+Helper.h"
#import "Frame+Helper.h"
#import "ImageUtilities.h"
#import "ShelbyBrowseTutorialView.h"
#import "ShelbyAlertView.h"
#import "ShelbyDataMediator.h"
#import "SPChannelCell.h"
#import "SPChannelCollectionView.h"
#import "SPChannelDisplay.h"
#import "SPVideoItemViewCell.h"
#import "SPVideoItemViewCellLabel.h"
#import "User+Helper.h"

#define kShelbyTutorialMode @"kShelbyTutorialMode"

NSString *const kShelbyChannelMetadataEntriesKey                = @"kShelbyChEntr";
NSString *const kShelbyChannelMetadataDeduplicatedEntriesKey    = @"kShelbyChDDEntr";

@interface BrowseViewController ()

@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (weak, nonatomic) IBOutlet UITableView *channelsTableView;

//internal data model for entries:
// { channelObjectID: { entries:[/*array of DashboardEntry or Frame*/],
//          deduplicatedEntries:[/*array of DashboardEntry or Frame*/]}, ... }
@property (nonatomic, strong) NSMutableDictionary *channelMetadataByObjectID;

@property (assign, nonatomic) SecretMode secretMode;

@property (assign, nonatomic) NSUInteger activeChannelIndex;
@property (assign, nonatomic) SPVideoReel *activeVideoReel;

@property (assign, nonatomic) BOOL animationInProgress;

@property (nonatomic) UIView *tutorialView;
@property (nonatomic, assign) ShelbyBrowseTutorialMode tutorialMode;

@property (nonatomic, strong) SPVideoItemViewCell *lastHighlightedCell;

//- (void)fetchUser;

// Helper methods
- (SPChannelCell *)loadCell:(NSInteger)row withDirection:(BOOL)up animated:(BOOL)animated;

/// Version Label
- (void)resetVersionLabel;

///Tutorial
- (IBAction)tutorialDismissed:(id)sender;

@end

@implementation BrowseViewController

#pragma mark - View Lifecycle Methods
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarStyleBlackTranslucent];
    
    [self setAnimationInProgress:NO];
    
    [self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"background"]]];
    
    [self setTrackedViewName:@"Browse"];
    
    [self resetVersionLabel];
    
//    [self fetchUser];
    
    self.channelMetadataByObjectID = [@{} mutableCopy];
    
    [self setSecretMode:SecretMode_None];
    
    // Register Cell Nibs
    [self.channelsTableView registerNib:[UINib nibWithNibName:@"SPChannelCell" bundle:nil] forCellReuseIdentifier:@"SPChannelCell"];
    //djs this shouldn't ever fetch channels
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // If viewWillAppear is called when SPVideoReel modalVC is removed...
    if ( [[UIApplication sharedApplication] isStatusBarHidden] ) {
        // ... re-display status bar
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarStyleBlackTranslucent];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self openEndTutorial];
}

- (void)setChannels:(NSArray *)channels
{
    _channels = channels;
    [self.channelsTableView reloadData];
    
    if (self.channels && [self.channels count]) {
        [self openFirstTimeTutorial];
    }
}

- (void)setEntries:(NSArray *)channelEntries forChannel:(DisplayChannel *)channel
{
    STVAssert([self.channels indexOfObject:channel] != NSNotFound, @"channel must be set before its entries");
    
    NSMutableDictionary *chMetadata = self.channelMetadataByObjectID[channel.objectID];
    if(!chMetadata){
        chMetadata = [@{} mutableCopy];
        self.channelMetadataByObjectID[channel.objectID] = chMetadata;
    }
    chMetadata[kShelbyChannelMetadataEntriesKey] = channelEntries;
    chMetadata[kShelbyChannelMetadataDeduplicatedEntriesKey] = [DeduplicationUtility deduplicatedCopy:channelEntries];
    
    [self.channelsTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForItem:[self.channels indexOfObject:channel] inSection:0]]
                                  withRowAnimation:NO];
}

- (void)addEntries:(NSArray *)newChannelEntries toEnd:(BOOL)shouldAppend ofChannel:(DisplayChannel *)channel
{
    NSMutableDictionary *chMetadata = self.channelMetadataByObjectID[channel.objectID];
    STVAssert(chMetadata, @"channel must be set before adding entries");
    NSArray *curEntries = chMetadata[kShelbyChannelMetadataEntriesKey];
    NSArray *curDedupedEntries = chMetadata[kShelbyChannelMetadataDeduplicatedEntriesKey];
    
    SPChannelCell *cell = [self cellForChannel:channel];
    NSMutableArray *indexPathsForInsert, *indexPathsForDelete, *indexPathsForReload;
    
    if(shouldAppend){
        chMetadata[kShelbyChannelMetadataEntriesKey] = [curEntries arrayByAddingObjectsFromArray:newChannelEntries];
        chMetadata[kShelbyChannelMetadataDeduplicatedEntriesKey] = [DeduplicationUtility deduplicatedArrayByAppending:newChannelEntries
                                                                                                       toDedupedArray:curDedupedEntries
                                                                                                            didInsert:&indexPathsForInsert
                                                                                                            didDelete:&indexPathsForDelete
                                                                                                            didUpdate:&indexPathsForReload];
    } else {
        chMetadata[kShelbyChannelMetadataEntriesKey] = [newChannelEntries arrayByAddingObjectsFromArray:curEntries];
        chMetadata[kShelbyChannelMetadataDeduplicatedEntriesKey] = [DeduplicationUtility deduplicatedArrayByPrepending:newChannelEntries
                                                                                                        toDedupedArray:curDedupedEntries
                                                                                                             didInsert:&indexPathsForInsert
                                                                                                             didDelete:&indexPathsForDelete
                                                                                                             didUpdate:&indexPathsForReload];
    }
    
    // The index paths returned by DeduplicationUtility are relative to the original array.
    // Because of performBatchUpdates:completion: semantics per documentation...
    /* When you group operations to insert, delete, reload, or move sections inside a single batch job, all operations are performed based on the current indexes of the collection view. This is unlike modifying a mutable array where the insertion or deletion of items affects the indexes of successive operations. Therefore, you do not have to remember which items or sections were inserted, deleted, or moved and adjust the indexes of all other operations accordingly.
     */
    [cell.channelCollectionView performBatchUpdates:^{
        [cell.channelCollectionView insertItemsAtIndexPaths:indexPathsForInsert];
        [cell.channelCollectionView deleteItemsAtIndexPaths:indexPathsForDelete];
        [cell.channelCollectionView reloadItemsAtIndexPaths:indexPathsForReload];
    } completion:^(BOOL finished) {
        //nothing
    }];
}

- (void)fetchDidCompleteForChannel:(DisplayChannel *)channel
{
    SPChannelCell *cell = [self cellForChannel:channel];
    cell.isRefreshing = NO;
}

- (NSArray *)entriesForChannel:(DisplayChannel *)channel
{
    NSDictionary *chMetadata = self.channelMetadataByObjectID[channel.objectID];
    return chMetadata ? chMetadata[kShelbyChannelMetadataEntriesKey] : nil;
}

- (NSArray *)deduplicatedEntriesForChannel:(DisplayChannel *)channel
{
    NSDictionary *chMetadata = self.channelMetadataByObjectID[channel.objectID];
    return chMetadata ? chMetadata[kShelbyChannelMetadataDeduplicatedEntriesKey] : nil;
}

- (void)refreshActivityIndicatorForChannel:(DisplayChannel *)channel shouldAnimate:(BOOL)shouldAnimate
{
    SPChannelCell *cell = [self cellForChannel:channel];
    if(shouldAnimate){
        [cell.refreshActivityIndicator startAnimating];
    } else {
        [cell.refreshActivityIndicator stopAnimating];
    }
}

- (void)loadMoreActivityIndicatorForChannel:(DisplayChannel *)channel shouldAnimate:(BOOL)shouldAnimate
{
    SPChannelCell *cell = [self cellForChannel:channel];
    if(shouldAnimate){
        [cell.loadMoreActivityIndicator startAnimating];
    } else {
        [cell.loadMoreActivityIndicator stopAnimating];
    }
}

- (void)openTutorialForFirstTime:(BOOL)firstTime
{
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"ShelbyBrowseTutorialView" owner:self options:nil];
    if ([nib isKindOfClass:[NSArray class]] && [nib count] != 0 && [nib[0] isKindOfClass:[UIView class]]) {
        ShelbyBrowseTutorialView *tutorial = nib[0];
        [tutorial setAlpha:0.95];
        [tutorial setFrame:CGRectMake(self.view.frame.size.width/2 - tutorial.frame.size.width/2, self.view.frame.size.height/2 - tutorial.frame.size.height/2, tutorial.frame.size.width, tutorial.frame.size.height)];
        UIView *mask = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
        [self.view addSubview:mask];
        [self.view bringSubviewToFront:mask];
        [mask setAlpha:0.5];
        [mask setBackgroundColor:[UIColor blackColor]];
        [self setTutorialView:mask];
        [self.view addSubview:tutorial];
        [self.view bringSubviewToFront:tutorial];
    
        if (firstTime) {
            [tutorial setupWithTitle:@"Welcome to Shelby TV" message:@"first, a quick gesture" andCloseButtonText:@"Play Channel 0"];
        } else {
            [tutorial setupWithTitle:@"You're Done!" message:@"Good job!" andCloseButtonText:@"Yay"];
        }
    }
}

- (void)openFirstTimeTutorial
{
    if ([self.browseDelegate conformsToProtocol:@protocol(ShelbyBrowseProtocol)] && [self.browseDelegate respondsToSelector:@selector(browseTutorialMode)]) {
        self.tutorialMode = [self.browseDelegate browseTutorialMode];
        if (self.tutorialMode != ShelbyBrowseTutorialModeShow) {
            return;
        }

        [self openTutorialForFirstTime:YES];
    }
}


- (void)openEndTutorial
{
    if ([self.browseDelegate conformsToProtocol:@protocol(ShelbyBrowseProtocol)] && [self.browseDelegate respondsToSelector:@selector(browseTutorialMode)]) {
        self.tutorialMode = [self.browseDelegate browseTutorialMode];
        if (self.tutorialMode != ShelbyBrowseTutorialModeEnd) {
            return;
        }
        
        [self openTutorialForFirstTime:NO];
    }
}

#pragma mark - Private Methods

//TODO: FIXME
- (SPChannelCell *)cellForChannel:(DisplayChannel *)channel
{
    //djs XXX this is going to break once we have non-channels in the view... can't use channel.order
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:[channel.order integerValue] inSection:0];
    SPChannelCell *cell = (SPChannelCell *)[self.channelsTableView cellForRowAtIndexPath:indexPath];
    return cell;
}

//- (void)fetchUser
//{
//    if ([self isLoggedIn]) {
//        //djs proper way to get current user
//        User *user = [User currentAuthenticatedUserInContext:[[ShelbyDataMediator sharedInstance] mainThreadContext]];
////        CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
////        User *user = [dataUtility fetchUser];
//        [self setUserNickname:[user nickname]];
//        [self setUserID:[user userID]];
//        [self setUserImage:[user userImage]];
//    }
//}

- (SPChannelCell *)loadCell:(NSInteger)row withDirection:(BOOL)up animated:(BOOL)animated
{
    SPChannelCell *channelCell = (SPChannelCell *)[self.channelsTableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:row inSection:0]];
    if (!channelCell && [self.channelsTableView numberOfRowsInSection:0] > row) {
        UITableViewScrollPosition position = up ? UITableViewScrollPositionTop : UITableViewScrollPositionBottom;
        NSIndexPath *nextIndexPath = [NSIndexPath indexPathForItem:row inSection:0];
        [self.channelsTableView scrollToRowAtIndexPath:nextIndexPath atScrollPosition:position animated:animated];
        [self.channelsTableView reloadRowsAtIndexPaths:@[nextIndexPath] withRowAnimation:UITableViewRowAnimationNone];
        channelCell = (SPChannelCell *)[self.channelsTableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:row inSection:0]];
    }
    
    return channelCell;
}


- (void)resetVersionLabel
{
    [self.versionLabel setFont:[UIFont fontWithName:@"Ubuntu-Bold" size:_versionLabel.font.pointSize]];
    [self.versionLabel setText:[NSString stringWithFormat:@"Shelby.tv for iPad v%@", kShelbyCurrentVersion]];
    [self.versionLabel setTextColor:kShelbyColorBlack];
}

- (IBAction)tutorialDismissed:(id)sender
{
    UIButton *button = sender;
    UIView *parent = [button superview];
    [UIView animateWithDuration:0.4 animations:^{
        [parent setAlpha:0];
        [self.tutorialView setAlpha:0];
    } completion:^(BOOL finished) {
        [parent removeFromSuperview];
        [self.tutorialView removeFromSuperview];
        [self setTutorialView:nil];
    }];
    

    if (self.tutorialMode == ShelbyBrowseTutorialModeShow) {
        UIButton *button = sender;
        UIView *messageView = [button superview];
        [self openChannelZeroWithView:messageView];
    } else if ([self.browseDelegate conformsToProtocol:@protocol(ShelbyBrowseProtocol)] && [self.browseDelegate respondsToSelector:@selector(userDidCompleteTutorial)]) {
            [self.browseDelegate userDidCompleteTutorial];
    }
}

- (void)openChannelZeroWithView:(UIView *)messageView
{
    SPChannelCell *channelZero = [self loadCell:0 withDirection:YES animated:NO];
    DisplayChannel *channelZeroDisplayChannel = channelZero.channelCollectionView.channel;
    
    [self.browseDelegate userPressedChannel:channelZeroDisplayChannel atItem:0];
}

#pragma mark - UITableViewDataSource Methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.channels count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SPChannelCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SPChannelCell" forIndexPath:indexPath];
    
    SPChannelCollectionView *channelCollectionView = [cell channelCollectionView];
    [channelCollectionView registerNib:[UINib nibWithNibName:@"SPVideoItemViewCell" bundle:nil] forCellWithReuseIdentifier:@"SPVideoItemViewCell"];
    [channelCollectionView setDelegate:self];
    [channelCollectionView setDataSource:self];
    [channelCollectionView reloadData];
    
    channelCollectionView.delegate = self;
    
    DisplayChannel *channel = (DisplayChannel *)self.channels[indexPath.row];

    channelCollectionView.channel = channel;
    cell.color = channel.displayColor;
    cell.title = channel.displayTitle;
    return cell;
}


- (void)highlightFrame:(Frame *)frame atChannel:(DisplayChannel *)channel
{
    // Find the channel
    NSInteger row = [self.channels indexOfObject:channel];
    
    SPChannelCell *cell = [self loadCell:row withDirection:YES animated:NO];
    SPChannelCollectionView *collectionView = cell.channelCollectionView;
    
    NSArray *dedupedEntries = [self deduplicatedEntriesForChannel:channel];
    
    NSInteger highlightIndex = 0;
    BOOL frameFound = NO;
    for (id entry in dedupedEntries) {
        if ([entry isKindOfClass:[DashboardEntry class]]) {
            if (((DashboardEntry *)entry).frame == frame) {
                frameFound = YES;
                break;
            }
        } else if ([entry isKindOfClass:[Frame class]] && ((Frame *)entry) == frame) {
            frameFound = YES;
            break;
        }
        highlightIndex++;
    }
    
    // Frame not found in channel, nothing to select.
    if (!frameFound) {
        return;
    }

    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:highlightIndex inSection:0];
 
    SPVideoItemViewCell *collectionCell = (SPVideoItemViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    
    // If frame is off screen - scroll and reload item.
    if (!collectionCell) {
        [collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
         [collectionView reloadItemsAtIndexPaths:@[indexPath]];
        collectionCell = (SPVideoItemViewCell *)[collectionView cellForItemAtIndexPath:indexPath];    
    }

    // Make sure old cell is de-highlighted
    [self.lastHighlightedCell unHighlightItem];
    
    self.lastHighlightedCell = collectionCell;
    [collectionCell highlightItemWithColor:collectionView.channel.displayColor];
}

#pragma mark - UIScrollViewDelegate Methods

#define PULL_TO_REFRESH_DISTANCE -150.0

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView
                     withVelocity:(CGPoint)velocity
              targetContentOffset:(inout CGPoint *)targetContentOffset
{
    if(scrollView.contentOffset.x < PULL_TO_REFRESH_DISTANCE){
        SPChannelCollectionView *channelCollectionView = (SPChannelCollectionView *)scrollView;
        if(channelCollectionView.channel.canFetchRemoteEntries){
            SPChannelCell *cell = channelCollectionView.parentCell;
            cell.isRefreshing = YES;
            [self.browseDelegate loadMoreEntriesInChannel:channelCollectionView.channel sinceEntry:nil];
        }
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    //NB: this could get triggered with enough velocity.
    // we may be okay with that, but could use other callbacks to maintain state and prevent that
    if(scrollView.contentOffset.x < 0){
        SPChannelCollectionView *channelCollectionView = (SPChannelCollectionView *)scrollView;
        if(channelCollectionView.channel.canFetchRemoteEntries){
            SPChannelCell *cell = channelCollectionView.parentCell;
            [cell setProximityToRefreshMode:(scrollView.contentOffset.x/PULL_TO_REFRESH_DISTANCE)];
            if(scrollView.contentOffset.x < PULL_TO_REFRESH_DISTANCE){
                cell.willRefresh = YES;
            } else {
                cell.willRefresh = NO;
            }
        }
    }
}

#pragma mark - UITableViewDelegate Methods
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

// TODO: factor the data source delegete methods to a model class.
#pragma mark - UICollectionView Datasource
- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section
{
    SPChannelCollectionView *channelCollection = (SPChannelCollectionView *)view;
    if ([channelCollection isKindOfClass:[SPChannelCollectionView class]]) {
        NSArray *dedupedEntries = [self deduplicatedEntriesForChannel:channelCollection.channel];
        if (dedupedEntries) {
             return [dedupedEntries count];
        }
    }
    
    return 0;
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView
{
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    SPVideoItemViewCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"SPVideoItemViewCell" forIndexPath:indexPath];
    
    SPChannelCollectionView *channelCollection = (SPChannelCollectionView *)cv;
    STVAssert([channelCollection isKindOfClass:[SPChannelCollectionView class]], @"expecting a different class!");
    NSArray *dedupedEntries = [self deduplicatedEntriesForChannel:channelCollection.channel];
    STVAssert(indexPath.row < [dedupedEntries count], @"expected a valid index path row");
    id entry = dedupedEntries[indexPath.row];
    
    cell.thumbnailImageView.backgroundColor = channelCollection.channel.displayColor;
    
    Frame *videoFrame = nil;
    if ([entry isKindOfClass:[DashboardEntry class]]) {
        videoFrame = ((DashboardEntry *)entry).frame;
    } else if([entry isKindOfClass:[Frame class]]) {
        videoFrame = entry;
    } else {
        STVAssert(false, @"Expected a DashboardEntry or Frame");
    }
    if (videoFrame && videoFrame.video) {
        cell.shelbyFrame = videoFrame;
        Video *video = videoFrame.video;
        if (video && video.thumbnailURL) {
            NSURLRequest *imageRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:video.thumbnailURL]];
            [[AFImageRequestOperation imageRequestOperationWithRequest:imageRequest
                                                 imageProcessingBlock:nil
                                                              success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                                                  if (cell.shelbyFrame == videoFrame && cell.thumbnailImageView.image == nil) {
                                                                      cell.thumbnailImageView.image = image;
                                                                  } else {
                                                                      //cell has been reused, do nothing
                                                                  }
                                                              }
                                                              failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                                                  //ignoring for now
                                                              }] start];
        }

        [cell.caption setText:[NSString stringWithFormat:@"%@: %@", videoFrame.creator.nickname, [videoFrame creatorsInitialCommentWithFallback:YES]]];
        //don't like this magic number, but also don't think the constant belongs in BrowseViewController...
        CGSize maxCaptionSize = CGSizeMake(cell.frame.size.width, cell.frame.size.height * 0.33);
        CGFloat textBasedHeight = [cell.caption.text sizeWithFont:[cell.caption font]
                                                constrainedToSize:maxCaptionSize
                                                    lineBreakMode:NSLineBreakByWordWrapping].height;
        
        [cell.caption setFrame:CGRectMake(cell.caption.frame.origin.x,
                                          cell.frame.size.height - textBasedHeight,
                                          cell.frame.size.width,
                                          textBasedHeight)];
    }
    
    //load more data
    NSInteger cellsBeyond = [dedupedEntries count] - [indexPath row];
    if(cellsBeyond == 1 && channelCollection.channel.canFetchRemoteEntries){
        //since id should come from raw entries, not de-duped entries
        [self.browseDelegate loadMoreEntriesInChannel:channelCollection.channel
                                           sinceEntry:[[self entriesForChannel:channelCollection.channel] lastObject]];
    }

    return cell;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self.lastHighlightedCell unHighlightItem];
    
    SPVideoItemViewCell *cell = (SPVideoItemViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    [cell highlightItemWithColor:[((SPChannelCollectionView *)collectionView) channelColor]];

    self.lastHighlightedCell = cell;
}

- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
}

// KP KP: TODO
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    SPChannelCollectionView *channelCollectionView = (SPChannelCollectionView *)collectionView;
    if ([channelCollectionView isKindOfClass:[SPChannelCollectionView class]]) {
        DisplayChannel *channel = channelCollectionView.channel;
        if ([self.browseDelegate respondsToSelector:@selector(userPressedChannel:atItem:)]) {
            NSArray *dedupedEntries = [self deduplicatedEntriesForChannel:channelCollectionView.channel];
            id entry = nil;
            if (indexPath.row < [dedupedEntries count]) {
                entry = dedupedEntries[indexPath.row];
            }
            [self.browseDelegate userPressedChannel:channel atItem:entry];
            SPVideoItemViewCell *cell = (SPVideoItemViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
            [cell unHighlightItem];
        }
    }
    
//    NSNumber *changableMapperKey = [NSNumber numberWithUnsignedInt:[collectionView hash]];
//    NSNumber *key = self.changeableDataMapper[changableMapperKey];
//    [self launchPlayer:[key intValue] andVideo:indexPath.row];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    // TODO: Deselect item
}

#pragma mark - Action Methods (Public)
- (void)toggleSecretModes:(id)sender
{
    
    /*
     Each switch statement sets the conditions for the next SecretMode.
     
     Example: 
     Entering SecretMode_None sets the condition for SecretMode_Offline.
     Entering SecretMode_Offline sets the condition for SecretMode_OfflineView.
     Entering SecretMode_OfflineView sets the condition for SecretMode_None.
     
     */
    
    if ( [[NSUserDefaults standardUserDefaults] boolForKey:kShelbyDefaultUserAuthorized] && [[NSUserDefaults standardUserDefaults] boolForKey:kShelbyDefaultUserIsAdmin] ) {
    
        switch ( _secretMode ) {
            
            case SecretMode_None: {
                
                [self setSecretMode:SecretMode_Offline];
                [self.versionLabel setText:[NSString stringWithFormat:@"Shelby.tv for iPad v%@-O", kShelbyCurrentVersion]];
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kShelbyDefaultOfflineModeEnabled];
                [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kShelbyDefaultOfflineViewModeEnabled];
                [[NSUserDefaults standardUserDefaults] synchronize];
                DLog(@"Offline Mode ENABLED!")
                
            } break;
            
            case SecretMode_Offline: {

                [self setSecretMode:SecretMode_OfflineView];
                [self.versionLabel setText:[NSString stringWithFormat:@"Shelby.tv for iPad v%@-OV", kShelbyCurrentVersion]];
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kShelbyDefaultOfflineModeEnabled];
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kShelbyDefaultOfflineViewModeEnabled];
                [[NSUserDefaults standardUserDefaults] synchronize];
                DLog(@"Offline+View Mode ENABLED!")
                
            } break;
                
            case SecretMode_OfflineView: {
                
                [self setSecretMode:SecretMode_None];
                [self resetVersionLabel];
                [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kShelbyDefaultOfflineModeEnabled];
                [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kShelbyDefaultOfflineViewModeEnabled];
                [[NSUserDefaults standardUserDefaults] synchronize];
                DLog(@"Offline+View Mode DISABLED!")
                
            } break;
            
        }
    }
}

- (ShelbyHideBrowseAnimationViews *)animationViewForOpeningChannel:(DisplayChannel *)channel
{
    // KP KP: TODO: deal with the case that the channel not found - maybe make the check in ShelbyHome before calling BrowseVC
    NSInteger row = [self.channels indexOfObject:channel];
    
    SPChannelCell *channelCell = (SPChannelCell *)[self.channelsTableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:row inSection:0]];
    
    UIImage *channelImage = [ImageUtilities screenshot:channelCell];
    UIImageView *channelImageView = [[UIImageView alloc] initWithImage:channelImage];
    
    CGPoint channelCellOriginInWindow = [self.view convertPoint:channelCell.frame.origin fromView:self.channelsTableView];
    
    CGRect topRect = CGRectMake(0, 0, 1024, channelCellOriginInWindow.y);
    CGRect bottomRect = CGRectMake(0, channelCellOriginInWindow.y + channelCell.frame.size.height, 1024, 1024 - channelCellOriginInWindow.y);
    
    UIImage *channelsImage = [ImageUtilities screenshot:self.view];
    UIImage *topImage = [ImageUtilities crop:channelsImage inRect:topRect];
    UIImage *bottomImage = [ImageUtilities crop:channelsImage inRect:bottomRect];
    
    UIImageView *topImageView = [[UIImageView alloc] initWithImage:topImage];
    UIImageView *bottomImageView = [[UIImageView alloc] initWithImage:bottomImage];
    
    [channelImageView setFrame:CGRectMake(0, channelCellOriginInWindow.y + 20, 1024, channelCell.frame.size.height)];
    [topImageView setFrame:CGRectMake(topRect.origin.x, topRect.origin.y + 20, topRect.size.width, topRect.size.height)];
    [bottomImageView setFrame:CGRectMake(bottomRect.origin.x, bottomRect.origin.y + 20, bottomRect.size.width, bottomRect.size.height)];
    
    CGRect finalTopFrame = CGRectMake(0, -topImageView.frame.size.height, topImageView.frame.size.width, topImageView.frame.size.height);
    CGRect finalBottomFrame = CGRectMake(0, 900, bottomImageView.frame.size.width, bottomImageView.frame.size.height);
    CGRect finalCenterFrame = CGRectMake(51, channelImageView.frame.origin.y, channelImageView.frame.size.width*0.9, channelImageView.frame.size.height*0.9);

    return [ShelbyHideBrowseAnimationViews createWithTop:topImageView finalTopFrame:finalTopFrame center:channelImageView finalCenterFrame:finalCenterFrame bottom:bottomImageView andFinalBottomFrame:finalBottomFrame];
}


- (ShelbyHideBrowseAnimationViews *)animationViewForClosingChannel:(DisplayChannel *)channel
{
    // KP KP: TODO: deal with the case that the channel not found - maybe make the check in ShelbyHome before calling BrowseVC
    NSInteger row = [self.channels indexOfObject:channel];
    
    BOOL up = NO;
    if (row == 0) {
        up = YES;
    }

    SPChannelCell *channelCell =  [self loadCell:row withDirection:up animated:NO];
    
    UIImage *channelImage = [ImageUtilities screenshot:channelCell];
    UIImageView *channelImageView = [[UIImageView alloc] initWithImage:channelImage];
    
    CGPoint channelCellOriginInWindow = [self.view convertPoint:channelCell.frame.origin fromView:self.channelsTableView];
    
    CGRect topRect = CGRectMake(0, 0, 1024, channelCellOriginInWindow.y);
    CGRect bottomRect = CGRectMake(0, channelCellOriginInWindow.y + channelCell.frame.size.height, 1024, 1024 - channelCellOriginInWindow.y);
    
    UIImage *channelsImage = [ImageUtilities screenshot:self.view];
    UIImage *topImage = [ImageUtilities crop:channelsImage inRect:topRect];
    UIImage *bottomImage = [ImageUtilities crop:channelsImage inRect:bottomRect];
    
    UIImageView *topImageView = [[UIImageView alloc] initWithImage:topImage];
    UIImageView *bottomImageView = [[UIImageView alloc] initWithImage:bottomImage];
    
    [topImageView setFrame:CGRectMake(0, -topImageView.frame.size.height, topImageView.frame.size.width, topImageView.frame.size.height)];
    [bottomImageView setFrame:CGRectMake(0, 900, bottomImageView.frame.size.width, bottomImageView.frame.size.height)];
    [channelImageView setFrame:CGRectMake(51, channelCellOriginInWindow.y, channelImageView.frame.size.width*0.9, channelImageView.frame.size.height*0.9)];
    
    CGRect finalCenterFrame = CGRectMake(0, channelCellOriginInWindow.y + 20, 1024, channelCell.frame.size.height);
        
    CGRect finalTopFrame = CGRectMake(topRect.origin.x, topRect.origin.y + 20, topRect.size.width, topRect.size.height);
    CGRect finalBottomFrame = CGRectMake(bottomRect.origin.x, bottomRect.origin.y + 20, bottomRect.size.width, bottomRect.size.height);

    
    return [ShelbyHideBrowseAnimationViews createWithTop:topImageView finalTopFrame:finalTopFrame center:channelImageView finalCenterFrame:finalCenterFrame bottom:bottomImageView andFinalBottomFrame:finalBottomFrame];
}


// djs was only called by deprecated code, should not be added back
//- (void)addUserRollToChannels
//{
//    if (!self.personalRollID) {
//        CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
//        User *user = [dataUtility fetchUser];
//        [self setPersonalRollID:[user personalRollID]];
//        [self setLikesRollID:[user likesRollID]];
//    }
//    
//    [self.channels addObject:self.likesRollID];
//    [self.channels addObject:self.personalRollID];
//}

@end