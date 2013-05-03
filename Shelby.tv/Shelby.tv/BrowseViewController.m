//
//  BrowseViewController.m
//  Shelby.tv
//
//  Created by Keren on 2/13/13.
//  Copyright (c) 2013 Shelby TV. All rights reserved.
//

#import "BrowseViewController.h"

// Views
#import "CollectionViewGroupsLayout.h"
#import "LoginView.h"
#import "SignupView.h"
#import "PageControl.h"
#import "SPVideoItemViewCell.h"
#import "SPChannelCell.h"
#import "SPChannelCollectionView.h"
#import "SPVideoItemViewCellLabel.h"
#import "SettingsViewController.h"


#define kShelbyTutorialMode @"kShelbyTutorialMode"

// Utilities
#import "ImageUtilities.h"

// Models
#import "ShelbyDataMediator.h"
#import "SPChannelDisplay.h"
#import "Frame+Helper.h"
#import "User+Helper.h"
#import "DisplayChannel+Helper.h"


@interface BrowseViewController ()

@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (weak, nonatomic) IBOutlet UITableView *channelsTableView;

@property (strong, nonatomic) NSString *userNickname;
@property (strong, nonatomic) NSString *userID;
@property (strong, nonatomic) NSString *personalRollID;
@property (strong, nonatomic) NSString *likesRollID;
@property (strong, nonatomic) NSString *userImage;
@property (assign, nonatomic) BOOL isLoggedIn;
@property (strong, nonatomic) UIView *userView;
@property (strong, nonatomic) UIPopoverController *settingsPopover;

@property (nonatomic) LoginView *loginView;
@property (nonatomic) SignupView *signupView;
@property (nonatomic) UIView *backgroundLoginView;

@property (nonatomic) NSMutableDictionary *channelsDataSource;
@property (nonatomic) NSMutableDictionary *changeableDataMapper;
@property (nonatomic) NSMutableSet *collectionViewDataSourceUpdater;

@property (assign, nonatomic) SecretMode secretMode;

@property (assign, nonatomic) NSUInteger activeChannelIndex;
@property (assign, nonatomic) SPVideoReel *activeVideoReel;

@property (assign, nonatomic) BOOL animationInProgress;

@property (nonatomic) UIView *tutorialView;

- (void)fetchUser;

// Helper methods
- (SPChannelCell *)loadCell:(NSInteger)row withDirection:(BOOL)up animated:(BOOL)animated;
- (NSInteger)indexForChannel:(NSString *)channelID;
- (NSDate *)dateTutorialCompleted;

/// Authentication Methods
- (void)login;
- (void)logout;
- (void)showSettings;

/// Video Player Launch Methods
- (void)launchPlayer:(NSUInteger)channelIndex;
- (void)launchPlayer:(NSUInteger)channelIndex andVideo:(NSUInteger)videoIndex;
- (void)launchPlayer:(NSUInteger)channelIndex andVideo:(NSUInteger)videoIndex withTutorialMode:(SPTutorialMode)tutorialMode;
- (void)launchPlayer:(NSUInteger)channelIndex andVideo:(NSUInteger)videoIndex andGroupType:(GroupType)groupType  withTutorialMode:(SPTutorialMode)tutorialMode;

- (void)presentViewController:(GAITrackedViewController *)viewControllerToPresent;
- (void)animateSwitchChannels:(SPVideoReel *)viewControllerToPresent;
- (void)animateOpenChannels:(SPVideoReel *)viewControllerToPresent;
- (void)animateCloseChannels:(SPVideoReel *)viewController;
- (NSInteger)nextChannelForDirection:(BOOL)up;

/// Fetch Methods
- (void)fetchOlderFramesForIndex:(NSNumber *)key;
- (void)fetchOlderFramesDidFail:(NSNotification *)notification;
- (void)dataSourceDidUpdateFromWeb:(NSNotification *)notification;
//djs don't like this part of the flow, killing it
//- (void)fetchDataSourceForChannel:(NSNotification *)notification;
- (void)setChannelsForTable;

/// Version Label
- (void)resetVersionLabel;

///Tutorial
- (IBAction)openChannelZero:(id)sender;

@end

@implementation BrowseViewController

#pragma mark - View Lifecycle Methods
- (void)viewDidLoad
{
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataSourceDidUpdateFromWeb:) name:kShelbySPUserDidScrollToUpdate object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchOlderFramesDidFail:) name:kShelbyNotificationFetchingOlderVideosFailed object:nil];
    //djs this stuff should be handed to this controller, it shouldn't be fetching them itself
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchDataSourceForChannel:) name:kShelbyNotificationChannelDataFetched object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setChannelsForTable) name:kShelbyNotificationChannelsFinishedSync object:nil];
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarStyleBlackTranslucent];
    
    [self setAnimationInProgress:NO];
    
    [self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"background"]]];
    
    [self setTrackedViewName:@"Browse"];
    
    [self resetVersionLabel];
    
    [self setIsLoggedIn:[[NSUserDefaults standardUserDefaults] boolForKey:kShelbyDefaultUserAuthorized]];
    
    [self fetchUser];
    
    [self setChannelsDataSource:[@{} mutableCopy]];
    [self setChangeableDataMapper:[@{} mutableCopy]];
    self.collectionViewDataSourceUpdater = [[NSMutableSet alloc] init];
    
    [self setSecretMode:SecretMode_None];
    
    // Register Cell Nibs
    [self.channelsTableView registerNib:[UINib nibWithNibName:@"SPChannelCell" bundle:nil] forCellReuseIdentifier:@"SPChannelCell"];
    //djs this shouldn't ever fetch channels
//    [self fetchAllChannels];

    //djs bring the tutorial stuff back
//    if (![self dateTutorialCompleted]) {
//        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"ShelbyChannelZeroTutorialView" owner:self options:nil];
//        if ([nib isKindOfClass:[NSArray class]] && [nib count] != 0 && [nib[0] isKindOfClass:[UIView class]]) {
//            UIView *tutorial = nib[0];
//            [tutorial setAlpha:0.95];
//            [tutorial setFrame:CGRectMake(self.view.frame.size.width/2 - tutorial.frame.size.width/2, self.view.frame.size.height/2 - tutorial.frame.size.height/2, tutorial.frame.size.width, tutorial.frame.size.height)];
//            UIView *mask = [[UIView alloc] initWithFrame:self.view.frame];
//            [self.view addSubview:mask];
//            [self.view bringSubviewToFront:mask];
//            [mask setAlpha:0.5];
//            [mask setBackgroundColor:[UIColor blackColor]];
//            [self setTutorialView:mask];
//            [self.view addSubview:tutorial];
//            [self.view bringSubviewToFront:tutorial];
//        }
//    }
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

- (void)setChannels:(NSArray *)channels
{
    _channels = channels;
    [self.channelsTableView reloadData];
}

#pragma mark - Private Methods
//djs get context otherwise
//- (NSManagedObjectContext *)context
//{
//    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
//    
//    return [appDelegate context];
//}

- (void)fetchUser
{
    if ([self isLoggedIn]) {
        //djs proper way to get current user
        User *user = [User currentAuthenticatedUserInContext:[[ShelbyDataMediator sharedInstance] mainThreadContext]];
//        CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
//        User *user = [dataUtility fetchUser];
        [self setUserNickname:[user nickname]];
        [self setUserID:[user userID]];
        [self setUserImage:[user userImage]];
    }
}

- (void)setChannelsForTable
{
    //djs this shouldn't ever fetch channels
//    [self fetchAllChannels];
    
    [self.channelsTableView reloadData];
}

- (void)fetchDataSourceForChannel:(NSNotification *)notification
{
    //djs I don't think this will be part of the flow at all anymore...
    assert(!"BrowseVC shouldn't fetchDataSourceForChannel");
    
//    // KP KP: TODO: once we add logged in user, add support for Personal Rolls, Likes and Stream
//    
//    NSString *channelID = [notification object];
//    if (channelID && [channelID isKindOfClass:[NSString class]]) {
//        NSInteger i = [self indexForChannel:channelID];
//        if (i == -1) {
//            return;
//        }
//        NSMutableArray *frames = self.channelsDataSource[[NSNumber numberWithInt:i]];
//
//        id channel = self.channels[i];
//        if ([channel isKindOfClass:[NSManagedObject class]]) {
//            NSManagedObjectID *channelObjectID = [channel objectID];
//            NSManagedObjectContext *context = [self context];
//            if ([channel isMemberOfClass:[Dashboard class]]) {
//                Dashboard *dashboard = (Dashboard *)[context existingObjectWithID:channelObjectID error:nil];
//                NSString *objectID = [dashboard dashboardID];
//                if ([objectID isEqualToString:channelID]) {
//                    CoreDataUtility *datautility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
//                    frames = [datautility fetchDashboardEntriesInDashboard:channelID];
//                }
//            } else if ([channel isMemberOfClass:[Roll class]]) {
//                Roll *roll = (Roll *)[context existingObjectWithID:channelObjectID error:nil];
//                NSString *objectID = [roll rollID];
//                if ([objectID isEqualToString:channelID]) {
//                    CoreDataUtility *datautility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
//                    frames = [datautility fetchFramesInChannelRoll:channelID];
//                }
//            }
//        }
//     
//        if (frames) {
//            [self.channelsDataSource setObject:frames forKey:[NSNumber numberWithInt:i]];
//            [self.channelsTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
//        }
//    }
}

- (void)fetchAllChannels
{
    //djs *definately* don't like the fetch all channels crap in here...
    assert(!"don't fetch all channels anymore");
    
//    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
//    [self.channels removeAllObjects];
//    [self.channelsDataSource removeAllObjects];
//    [self.changeableDataMapper removeAllObjects];
//    [self.channels addObjectsFromArray:[dataUtility fetchAllChannels]];
//    
//    if (self.isLoggedIn) {
//        id streamChannel;
//        for (id channel in self.channels) {
//            if ([channel isKindOfClass:[Dashboard class]]) {
//                if ([[((Dashboard *)channel) dashboardID] isEqualToString:self.userID]) {
//                    streamChannel = channel;
//                    break;
//                }
//            }
//        }
//        
//        if (streamChannel && [self.channels count] > 1) {
//            [self.channels removeObject:streamChannel];
//            [self.channels insertObject:streamChannel atIndex:0];
//            
//        }
//        
//        [self addUserRollToChannels];
//    }
//    
//    NSInteger i = 0;
//    for (id channel in self.channels) {
//        NSMutableArray *frames = nil;
//        if ([channel isKindOfClass:[Dashboard class]]) {
//            CoreDataUtility *channelDataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
//            frames = [channelDataUtility fetchDashboardEntriesInDashboard:[((Dashboard *)channel) dashboardID]];
//        } else if ([channel isKindOfClass:[Roll class]]) {
//            CoreDataUtility *rollDataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
//            frames = [rollDataUtility fetchFramesInChannelRoll:[((Roll *)channel) rollID]];
//        } else if ([channel isKindOfClass:[NSString class]]) {
//            if ([((NSString *)channel) isEqualToString:self.personalRollID]) {
//                CoreDataUtility *rollDataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
//                frames = [rollDataUtility fetchPersonalRollEntries];
//            } else {
//                CoreDataUtility *rollDataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
//                frames = [rollDataUtility fetchLikesEntries];
//            }
//        } else {
//            frames = [@[] mutableCopy];
//        }
//        [self.channelsDataSource setObject:frames forKey:[NSNumber numberWithInt:i]];
//        i++;
//    }
//    
//    [self.channelsTableView reloadData];
}

- (SPChannelCell *)loadCell:(NSInteger)row withDirection:(BOOL)up animated:(BOOL)animated
{
    SPChannelCell *channelCell = (SPChannelCell *)[self.channelsTableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:row inSection:0]];
    if (!channelCell) {
        UITableViewScrollPosition position = up ? UITableViewScrollPositionTop : UITableViewScrollPositionBottom;
        NSIndexPath *nextIndexPath = [NSIndexPath indexPathForItem:row inSection:0];
        [self.channelsTableView scrollToRowAtIndexPath:nextIndexPath atScrollPosition:position animated:animated];
        [self.channelsTableView reloadRowsAtIndexPaths:@[nextIndexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
    
    return channelCell;
}

- (NSInteger)indexForChannel:(NSString *)channelID
{
    if (channelID && [channelID isKindOfClass:[NSString class]]) {
        NSInteger i = 0;
        for (id channel in self.channels) {
            if ([channel isKindOfClass:[NSManagedObject class]]) {
                //djs just going to use the channels we have
//                NSManagedObjectID *channelObjectID = [channel objectID];
//                NSManagedObjectContext *context = [self context];
                if ([channel isMemberOfClass:[Dashboard class]]) {
                    //djs core data refactor
//                    Dashboard *dashboard = (Dashboard *)[context existingObjectWithID:channelObjectID error:nil];
                    NSString *dashboardID = [((Dashboard *)channel) dashboardID];
                    if ([dashboardID isEqualToString:channelID]) {
                        return i;
                    }
                } else if ([channel isMemberOfClass:[Roll class]]) {
                    //djs core data refactor
//                    Roll *roll = (Roll *)[context existingObjectWithID:channelObjectID error:nil];
                    NSString *rollID = [((Roll *)channel) rollID];
                    if ([rollID isEqualToString:channelID]) {
                        return i;
                    }
                }
            }
            i++;
        }
    }
    
    return -1; // channel wasn't found
}


- (NSDate *)dateTutorialCompleted
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:kShelbyTutorialMode];
}


- (void)resetVersionLabel
{
    [self.versionLabel setFont:[UIFont fontWithName:@"Ubuntu-Bold" size:_versionLabel.font.pointSize]];
    [self.versionLabel setText:[NSString stringWithFormat:@"Shelby.tv for iPad v%@", kShelbyCurrentVersion]];
    [self.versionLabel setTextColor:kShelbyColorBlack];
}


- (IBAction)openChannelZero:(id)sender
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
    
    [self launchPlayer:0 andVideo:0 withTutorialMode:YES];
}

#pragma mark - UITableViewDataSource Methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.channels count];
}


//djs updating this for real...
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    SPChannelCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SPChannelCell" forIndexPath:indexPath];
    
    UICollectionView *channelFrames = [cell channelFrames];
    [channelFrames registerNib:[UINib nibWithNibName:@"SPVideoItemViewCell" bundle:nil] forCellWithReuseIdentifier:@"SPVideoItemViewCell"];
    [channelFrames setDelegate:self];
    [channelFrames setDataSource:self];
    [channelFrames reloadData];
    NSUInteger hash = [channelFrames hash];
    self.changeableDataMapper[[NSNumber numberWithUnsignedInt:hash]] = [NSNumber numberWithInt:indexPath.row];
    
    DisplayChannel *channel = (DisplayChannel *)self.channels[indexPath.row];

    //TODO: deal with no color, no title
    [cell setChannelColor:[channel displayColor] andTitle:[channel displayTitle]];
    return cell;
}

#pragma mark - UITableViewDelegate Methods
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

// TODO: factor the data source delegete methods to a model class.
#pragma mark - UICollectionView Datasource
- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section
{
    NSNumber *changableMapperKey = [NSNumber numberWithUnsignedInt:[view hash]];
    NSNumber *key = self.changeableDataMapper[changableMapperKey];
    NSMutableArray *frames = self.channelsDataSource[key];
    if (frames) {
        return [frames count];
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
    
    NSNumber *changableMapperKey = [NSNumber numberWithUnsignedInt:[cv hash]];
    NSNumber *key = self.changeableDataMapper[changableMapperKey];
    NSMutableArray *frames = self.channelsDataSource[key];

    //djs using the objects we have
//    NSManagedObjectContext *context = [self context];
    id channel = (id)self.channels[[key intValue]];
    NSString *channelID = nil;
    if ([channel isMemberOfClass:[Roll class]]) {
        Roll *roll = (Roll *)channel;
//        roll = (Roll *)[context existingObjectWithID:[roll objectID] error:nil];
        channelID = roll.rollID;
    } else if ([channel isMemberOfClass:[Dashboard class]]) {
        Dashboard *dashboard = (Dashboard *)channel;
//        dashboard = (Dashboard *)[context existingObjectWithID:[dashboard objectID] error:nil];
        channelID = dashboard.dashboardID;
    } else if ([channel isKindOfClass:[NSString class]]) {
        if ([((NSString *)channel) isEqualToString:self.personalRollID]) {
            channelID = self.personalRollID;
        } else {
            channelID = self.likesRollID;
        }
    }

    NSInteger cellsLeftToDisplay = abs([frames count] - [indexPath row]);
    if (cellsLeftToDisplay < 10) {
        
        if (![self.collectionViewDataSourceUpdater containsObject:channelID] ) {
            [self.collectionViewDataSourceUpdater addObject:channelID];
            [self fetchOlderFramesForIndex:key];
        }
    
    }
    
    Frame *frame = (Frame *)frames[indexPath.row];
    
    if (frame) {
        //djs using the objects we have
//        NSManagedObjectContext *context = [self context];
//        NSManagedObjectID *frameObjectID = [frame objectID];
        Frame *videoFrame = frame;//[context existingObjectWithID:frameObjectID error:nil];
        
        if (videoFrame && [videoFrame video]) {
            [AsynchronousFreeloader loadImageFromLink:videoFrame.video.thumbnailURL
                                         forImageView:cell.thumbnailImageView
                                      withPlaceholder:[UIImage imageNamed:@"videoListThumbnail"]
                                       andContentMode:UIViewContentModeCenter];
            
            [cell.caption setText:[videoFrame creatorsInitialCommentWithFallback:YES]];
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
    }

    return cell;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    SPVideoItemViewCell *cell = (SPVideoItemViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    [cell highlightItemWithColor:[((SPChannelCollectionView *)collectionView) channelColor]];
}

- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    SPVideoItemViewCell *cell = (SPVideoItemViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    [cell unHighlightItem];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSNumber *changableMapperKey = [NSNumber numberWithUnsignedInt:[collectionView hash]];
    NSNumber *key = self.changeableDataMapper[changableMapperKey];
    [self launchPlayer:[key intValue] andVideo:indexPath.row];
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

#pragma mark - Authorization Methods (Private)
- (void)login
{
    AuthorizationViewController *authorizationViewController = [[AuthorizationViewController alloc] initWithNibName:@"AuthorizationView" bundle:nil];
    
    CGFloat xOrigin = self.view.frame.size.width / 2.0f - authorizationViewController.view.frame.size.width / 4.0f;
    CGFloat yOrigin = self.view.frame.size.height / 5.0f - authorizationViewController.view.frame.size.height / 4.0f;
    CGSize loginDialogSize = authorizationViewController.view.frame.size;
    
    [authorizationViewController setModalInPopover:YES];
    [authorizationViewController setModalPresentationStyle:UIModalPresentationFormSheet];
    [authorizationViewController setDelegate:self];
    
    [self presentViewController:authorizationViewController animated:YES completion:nil];
    
    authorizationViewController.view.superview.frame = CGRectMake(xOrigin, yOrigin, loginDialogSize.width, loginDialogSize.height);
}

- (void)logout
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Logout?"
                                                        message:@"Are you sure you want to logout?"
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Logout", nil];
 	
    [alertView show];
}

- (void)showSettings
{
    if(!self.settingsPopover) {
        SettingsViewController *settingsViewController = [[SettingsViewController alloc] initWithNibName:@"SettingsView" bundle:nil];

        _settingsPopover = [[UIPopoverController alloc] initWithContentViewController:settingsViewController];
        [self.settingsPopover setDelegate:self];
        [settingsViewController setParent:self];
    }
    [self.settingsPopover presentPopoverFromRect:self.userView.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}


#pragma mark - Video Player Launch Methods (Private)
- (void)launchMyLikesPlayer
{
    NSInteger row = [self.channels count] - 2;
    if (self.isLoggedIn && row > 2) {
        [self.channelsTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForItem:row inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}

- (void)launchMyRollPlayer
{
    NSInteger row = [self.channels count] -1;
    if (self.isLoggedIn && row) {
        [self.channelsTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForItem:row inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
     }
}

- (void)launchPlayer:(NSUInteger)channelIndex
{
    [self launchPlayer:channelIndex andVideo:0 withTutorialMode:NO];
}

- (void)launchPlayer:(NSUInteger)channelIndex andVideo:(NSUInteger)videoIndex
{
    id channel = (id)self.channels[channelIndex];
    GroupType groupType = GroupType_ChannelRoll;
    if ([channel isMemberOfClass:[Dashboard class]]) {
        groupType = GroupType_ChannelDashboard;
    }
    
    [self launchPlayer:channelIndex andVideo:videoIndex withGroupType:groupType];
}

- (void)launchPlayer:(NSUInteger)channelIndex andVideo:(NSUInteger)videoIndex withGroupType:(GroupType)groupType
{
    [self launchPlayer:channelIndex andVideo:videoIndex withTutorialMode:SPTutorialModeNone];
}

- (void)launchPlayer:(NSUInteger)categoryIndex andVideo:(NSUInteger)videoIndex withTutorialMode:(SPTutorialMode)tutorialMode
{
    id channel = (id)self.channels[categoryIndex];
    GroupType groupType = GroupType_ChannelRoll;
    if ([channel isMemberOfClass:[Dashboard class]]) {
        groupType = GroupType_ChannelDashboard;
    } else if ([channel isKindOfClass:[NSString class]]) {
        if ([((NSString *)channel) isEqualToString:self.personalRollID]) {
            groupType = GroupType_PersonalRoll;
        } else {
            groupType = GroupType_Likes;
        }
    }
    
    [self launchPlayer:categoryIndex andVideo:videoIndex andGroupType:groupType withTutorialMode:tutorialMode];
}

- (void)launchPlayer:(NSUInteger)channelIndex andVideo:(NSUInteger)videoIndex andGroupType:(GroupType)groupType withTutorialMode:(SPTutorialMode)tutorialMode
{
    DLog(@"TODO: launch player");
    //djs TODO: figure out a proper way of lauching the player
    // not sure why we have this async stuff here
    // if it's really improving performance we can use it, but then we do need to be careful about ManagedObjectContext since we're using
    // Thread confinement type concurrency with Core Data. That is, each thread has it's own context.
    
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        
//        NSMutableArray *videoFrames = nil;
//        NSString *errorMessage = nil;
//        NSString *title = nil;
//
//        NSManagedObjectContext *context = [self context];
//        id channel = self.channels[channelIndex];
//        NSManagedObjectID *objectID = nil;
//        if (![channel isKindOfClass:[NSString class]]) {
//            objectID = [(self.channels)[channelIndex] objectID];
//        }
//        switch (groupType) {
//            case GroupType_ChannelDashboard:
//            {
//                Dashboard *dashboard = (Dashboard *)[context existingObjectWithID:objectID error:nil];
//                errorMessage = @"No videos in Channel Dashboard.";
//                title = [dashboard displayTitle];
//                break;
//            }
//            case GroupType_ChannelRoll:
//            {
//                Roll *roll = (Roll *)[context existingObjectWithID:objectID error:nil];
//                errorMessage = @"No videos in Channel Roll.";
//                title = [roll displayTitle];
//                break;
//            }
//            case GroupType_Likes:
//            {
//                errorMessage = @"No videos in Likes";
//                title = @"Likes";
//                break;
//            }
//            case GroupType_PersonalRoll:
//            {
//                errorMessage = @"No videos in Roll";
//                title = @"My Roll";
//                break;
//            }
//            default:
//            {
//                return;
//            }
//        }
//        
//        videoFrames = self.channelsDataSource[[NSNumber numberWithInt:channelIndex]];
//        
//        dispatch_async(dispatch_get_main_queue(), ^{
//            if ([videoFrames count]) {
//                NSManagedObjectContext *mainThreadContext = [self context];
//                NSString *channelID = nil;
//                if (groupType == GroupType_ChannelDashboard) { // channel Channel
//                    NSManagedObjectID *objectID = [(self.channels)[channelIndex] objectID];
//                    Dashboard *dashboard = (Dashboard *)[mainThreadContext existingObjectWithID:objectID error:nil];
//                    channelID = dashboard.dashboardID;
//                } else if (groupType == GroupType_ChannelRoll) { // channel Roll
//                    NSManagedObjectID *objectID = [(self.channels)[channelIndex] objectID];
//                    Roll *roll = (Roll *)[mainThreadContext existingObjectWithID:objectID error:nil];
//                    channelID = roll.rollID;
//                } else if (groupType == GroupType_PersonalRoll) {
//                    channelID = self.personalRollID;
//                } else if (groupType == GroupType_Likes) {
//                    channelID = self.likesRollID;
//                }
//
//                if (self.activeVideoReel) {
//                    [self.activeVideoReel cleanup];
//                }
//                SPVideoReel *videoReel = [[SPVideoReel alloc] initWithGroupType:groupType groupTitle:title videoFrames:videoFrames videoStartIndex:videoIndex andChannelID:channelID];
//                [videoReel setDelegate:self];
//
//                [self setActiveChannelIndex:channelIndex];
//                [videoReel setTutorialMode:tutorialMode];
//                [self setActiveChannelIndex:channelIndex];
//                [self presentViewController:videoReel];
//
//            } else {
//                
//                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
//                                                                    message:errorMessage
//                                                                   delegate:self
//                                                          cancelButtonTitle:@"Dismiss"
//                                                          otherButtonTitles:nil];
//                
//                [alertView show];
//                
//            }
//            
//        });
//    });
}

- (void)animateSwitchChannels:(SPVideoReel *)viewControllerToPresent
{
    [self.activeVideoReel dismissViewControllerAnimated:NO completion:^{
        [self presentViewController:viewControllerToPresent animated:NO completion:^{
            [self setActiveVideoReel:nil];
        }];
        
    }];
}

- (void)animateOpenChannels:(SPVideoReel *)viewControllerToPresent
{
    if (self.animationInProgress) {
        return;
    } else {
        [self setAnimationInProgress:YES];
    }
    
    SPChannelCell *channelCell = (SPChannelCell *)[self.channelsTableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:self.activeChannelIndex inSection:0]];
    
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
    
    [viewControllerToPresent.view addSubview:channelImageView];
    [viewControllerToPresent.view addSubview:bottomImageView];
    [viewControllerToPresent.view addSubview:topImageView];
    [channelImageView setFrame:CGRectMake(0, channelCellOriginInWindow.y + 20, 1024, channelCell.frame.size.height)];
    [topImageView setFrame:CGRectMake(topRect.origin.x, topRect.origin.y + 20, topRect.size.width, topRect.size.height)];
    [bottomImageView setFrame:CGRectMake(bottomRect.origin.x, bottomRect.origin.y + 20, bottomRect.size.width, bottomRect.size.height)];

    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarStyleBlackTranslucent];
    
    [self presentViewController:viewControllerToPresent animated:NO completion:^{
        [UIView animateWithDuration:1 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            [topImageView setFrame:CGRectMake(0, -topImageView.frame.size.height, topImageView.frame.size.width, topImageView.frame.size.height)];
            [bottomImageView setFrame:CGRectMake(0, 900, bottomImageView.frame.size.width, bottomImageView.frame.size.height)];
            [channelImageView setFrame:CGRectMake(51, channelImageView.frame.origin.y, channelImageView.frame.size.width*0.9, channelImageView.frame.size.height*0.9)];
            
            [channelImageView setAlpha:0];
        } completion:^(BOOL finished) {
            [channelImageView removeFromSuperview];
            [bottomImageView removeFromSuperview];
            [topImageView removeFromSuperview];
            [self setAnimationInProgress:NO];
        }];
    }];
}

- (void)animateCloseChannels:(SPVideoReel *)viewController
{
    if (self.animationInProgress) {
        return;
    } else {
        [self setAnimationInProgress:YES];
    }

    SPChannelCell *channelCell = (SPChannelCell *)[self.channelsTableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:self.activeChannelIndex inSection:0]];
    
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
    
    [viewController.view addSubview:channelImageView];
    [viewController.view addSubview:bottomImageView];
    [viewController.view addSubview:topImageView];
    
    [topImageView setFrame:CGRectMake(0, -topImageView.frame.size.height, topImageView.frame.size.width, topImageView.frame.size.height)];
    [bottomImageView setFrame:CGRectMake(0, 900, bottomImageView.frame.size.width, bottomImageView.frame.size.height)];
    [channelImageView setFrame:CGRectMake(0, 1024, channelImageView.frame.size.width, channelImageView.frame.size.height)];

    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarStyleBlackTranslucent];
    [channelImageView setAlpha:0];

    [channelImageView setFrame:CGRectMake(51, channelCellOriginInWindow.y, channelImageView.frame.size.width*0.9, channelImageView.frame.size.height*0.9)];
    
    [UIView animateWithDuration:0.45 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
       [channelImageView setFrame:CGRectMake(0, channelCellOriginInWindow.y + 20, 1024, channelCell.frame.size.height)];
        
        [channelImageView setAlpha:1];
        [topImageView setFrame:CGRectMake(topRect.origin.x, topRect.origin.y + 20, topRect.size.width, topRect.size.height)];
        [bottomImageView setFrame:CGRectMake(bottomRect.origin.x, bottomRect.origin.y + 20, bottomRect.size.width, bottomRect.size.height)];
        
    } completion:^(BOOL finished) {
        [channelImageView removeFromSuperview];
        [bottomImageView removeFromSuperview];
        [topImageView removeFromSuperview];
        [viewController cleanup];
        [viewController dismissViewControllerAnimated:NO completion:nil];
        [self setAnimationInProgress:NO];
    }];
}


- (NSInteger)nextChannelForDirection:(BOOL)up
{
    NSInteger next = up ? -1 : 1;
    NSInteger nextChannel = self.activeChannelIndex + next;
    if (nextChannel < 0) {
        nextChannel = [self.channels count] + nextChannel;
    } else if (nextChannel == [self.channels count]) {
        nextChannel = 0;
    }

    return nextChannel;
}

- (void)presentViewController:(GAITrackedViewController *)viewControllerToPresent
{
    if (self.activeVideoReel) {
        [self animateSwitchChannels:(SPVideoReel *)viewControllerToPresent];
    } else {
        [self animateOpenChannels:(SPVideoReel *)viewControllerToPresent];
    }
}


#pragma mark - Fetching Methods
- (void)fetchOlderFramesForIndex:(NSNumber *)key
{

    DLog(@"TODO: fetch older frames for index");
    //djs this should be completely re-thought with the new architecture, so i'm not fixing stuff just yet
    
//    NSManagedObjectContext *context = [self context];
//    
//    id channel = (id)self.channels[[key intValue]];
//    GroupType groupType = GroupType_Unknown;
//    NSString *channelID = nil;
//    if ([channel isMemberOfClass:[Roll class]]) {
//        groupType = GroupType_ChannelRoll;
//        Roll *roll = (id)channel;
//        roll = (Roll *)[context existingObjectWithID:[roll objectID] error:nil];
//        channelID = roll.rollID;
//    } else if ([channel isMemberOfClass:[Dashboard class]]) {
//        Dashboard *dashboard = (id)channel;
//        dashboard = (Dashboard *)[context existingObjectWithID:[dashboard objectID] error:nil];
//        channelID = dashboard.dashboardID;
//        if (self.isLoggedIn && [channelID isEqualToString:self.userID]) {
//            channelID = self.userID;
//            groupType = GroupType_Stream;
//        } else {
//            groupType = GroupType_ChannelDashboard;
//        }
//    } else if ([channel isKindOfClass:[NSString class]]) {
//        channelID = channel;
//    }
//    
//    switch ( groupType ) {
//        case GroupType_Stream:
//        {
//            CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
//            NSUInteger totalNumberOfVideosInDatabase = [dataUtility fetchCountForChannelDashboard:channelID];
//            NSString *numberToString = [NSString stringWithFormat:@"%d", totalNumberOfVideosInDatabase];
//            [ShelbyAPIClient getMoreFramesInStream:numberToString];
//            break;
//        }
//        case GroupType_ChannelDashboard:
//        {
//            CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
//            NSUInteger totalNumberOfVideosInDatabase = [dataUtility fetchCountForChannelDashboard:channelID];
//            NSString *numberToString = [NSString stringWithFormat:@"%d", totalNumberOfVideosInDatabase];
//            [ShelbyAPIClient getMoreDashboardEntries:numberToString forChannelDashboard:channelID];
//            break;
//        }
//        case GroupType_ChannelRoll:
//        {
//            CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
//            NSUInteger totalNumberOfVideosInDatabase = [dataUtility fetchCountForChannelRoll:channelID];
//            NSString *numberToString = [NSString stringWithFormat:@"%d", totalNumberOfVideosInDatabase];
//            [ShelbyAPIClient getMoreFrames:numberToString forChannelRoll:channelID];
//            break;
//        }
//        case GroupType_Likes:
//        {
//            [ShelbyAPIClient getMoreFramesInLikes:self.likesRollID];
//            break;
//        }
//        case GroupType_PersonalRoll:
//        {
//            [ShelbyAPIClient getMoreFramesInPersonalRoll:self.personalRollID];
//            break;
//        }
//        default: {
//            [self.collectionViewDataSourceUpdater removeObject:channelID];
//            // Handle remaining cases later
//            
//        }
//    }
}


- (void)dataSourceDidUpdateFromWeb:(NSNotification *)notification
{

    //djs this is going to change big time as well...
    //the brain should simply hand us the models and/or updates
    //could even be done via a setter
    //def. not via notifications.
    
//    NSString *channelID = [notification object];
//     if (channelID && [channelID isKindOfClass:[NSString class]]) {
//         
//         NSInteger i = [self indexForChannel:channelID];
//         if (i == -1) {
//             [self.collectionViewDataSourceUpdater removeObject:channelID];
//             return;
//         }
//         
//         NSManagedObjectContext *context = [self context];
//         
//         id channel = self.channels[i];
//         NSString *channelID = nil;
//         GroupType groupType = GroupType_Unknown;
//         if ([channel isMemberOfClass:[Roll class]]) {
//             groupType = GroupType_ChannelRoll;
//             Roll *roll = (id)channel;
//             roll = (Roll *)[context existingObjectWithID:[roll objectID] error:nil];
//             channelID = roll.rollID;
//         } else if ([channel isMemberOfClass:[Dashboard class]]) {
//             groupType = GroupType_ChannelDashboard;
//             Dashboard *dashboard = (id)channel;
//             dashboard = (Dashboard *)[context existingObjectWithID:[dashboard objectID] error:nil];
//             channelID = dashboard.dashboardID;
//         }
//        
//         NSMutableArray *frames = self.channelsDataSource[[NSNumber numberWithInt:i]];
//         NSManagedObjectID *lastFramedObjectID = [[frames lastObject] objectID];
//         if (!lastFramedObjectID) {
//             [self.collectionViewDataSourceUpdater removeObject:channelID];
//             return;
//         }
//        
//         Frame *lastFrame = (Frame *)[context existingObjectWithID:lastFramedObjectID error:nil];
//         if (!lastFrame) {
//             [self.collectionViewDataSourceUpdater removeObject:channelID];
//             return;
//         }
//        
//         NSDate *date = lastFrame.timestamp;
//        
//         NSMutableArray *olderFramesArray = [@[] mutableCopy];
//        
//         switch ( groupType ) {
//                
//             case GroupType_ChannelDashboard:{
//                  CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
//                 [olderFramesArray addObjectsFromArray:[dataUtility fetchMoreDashboardEntriesInDashboard:channelID afterDate:date]];
//             } break;
//                
//             case GroupType_ChannelRoll:{
//                  CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
//                 [olderFramesArray addObjectsFromArray:[dataUtility fetchMoreFramesInChannelRoll:channelID afterDate:date]];
//             } break;
//                
//             default: {
//                // Handle remaining cases later  
//             }
//        }
//        
//        // If olderFramesArray is populated, compare against existing visddeos, and deduplicate if necessary
//        if ( [olderFramesArray count] ) {
//            
//            Frame *firstFrame = (Frame *)olderFramesArray[0];
//            NSManagedObjectID *firstFrameObjectID = [firstFrame objectID];
//            if (!firstFrameObjectID) {
//                [self.collectionViewDataSourceUpdater removeObject:channelID];
//                return;
//            }
//            
//            firstFrame = (Frame *)[context existingObjectWithID:firstFrameObjectID error:nil];
//            if (!firstFrame) {
//                [self.collectionViewDataSourceUpdater removeObject:channelID];
//                return;
//            }
//            if ( [firstFrame.videoID isEqualToString:lastFrame.videoID] ) {
//                [olderFramesArray removeObject:firstFrame];
//            }
//            
//            // Add deduplicated frames from olderFramesArray to frames
//            [frames addObjectsFromArray:olderFramesArray];
//   
//            [self.channelsTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
//            
//        } 
//        
//         [self.collectionViewDataSourceUpdater removeObject:channelID];
//    }
}

- (void)fetchOlderFramesDidFail:(NSNotification *)notification
{
    NSString *channelID = [notification object];
    if (channelID && [channelID isKindOfClass:[NSString class]]) {
            [self.collectionViewDataSourceUpdater removeObject:channelID];
    }
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


#pragma mark - AuthorizationDelegate Methods
- (void)authorizationDidComplete
{
    //djs not sure we're going to be a AuthorizationDelegate in the future
    //but if we are, this is about the only thing I can imagine is okay to do:
    [self setIsLoggedIn:YES];
    //djs the rest of this stuff should be handled by other objects
//    [self fetchUser];
//    [self fetchAllChannels];
//    [ShelbyAPIClient getStream];
//    [ShelbyAPIClient getPersonalRoll];
//    [ShelbyAPIClient getLikes];
}

#pragma mark - SPVideoReel Delegate
- (void)userDidSwitchChannel:(SPVideoReel *)videoReel direction:(BOOL)up;
{
    // Track "swipe vertical to change channel"
    id defaultTracker = [GAI sharedInstance].defaultTracker;
    [defaultTracker sendEventWithCategory:kGAICategoryVideoPlayer
                               withAction:kGAIVideoPlayerActionSwipeVertical
                                withLabel:[videoReel groupTitle]
                                withValue:nil];
    
    [self setActiveVideoReel:videoReel];

    NSInteger nextChannel = [self nextChannelForDirection:up];
    SPTutorialMode tutorialMode = SPTutorialModeNone;
    if (![self dateTutorialCompleted]) {
        tutorialMode = SPTutorialModePinch;
    }
    
    [self launchPlayer:nextChannel andVideo:0 withTutorialMode:tutorialMode];
    
    [self loadCell:nextChannel withDirection:up animated:NO];
}

- (void)userDidCloseChannel:(SPVideoReel *)videoReel
{
    // Track "pinch to browse"
    id defaultTracker = [GAI sharedInstance].defaultTracker;
    [defaultTracker sendEventWithCategory:kGAICategoryVideoPlayer
                               withAction:kGAIVideoPlayerActionPinch
                                withLabel:[videoReel groupTitle]
                                withValue:nil];
    
    if (![self dateTutorialCompleted]) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:kShelbyTutorialMode];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    [self animateCloseChannels:videoReel];

}

- (SPChannelDisplay *)channelDisplayForDirection:(BOOL)up
{
    NSInteger nextChannel = [self nextChannelForDirection:up];
    
    SPChannelCell *channelCell = [self loadCell:nextChannel withDirection:up animated:NO];
    SPChannelDisplay *channelDisplay = [[SPChannelDisplay alloc] initWithChannelColor:[channelCell channelDisplayColor]
                                                               andChannelDisplayTitle:[channelCell channelDisplayTitle]];
    
    return channelDisplay;
}

- (void)dismissPopover
{
    if (self.settingsPopover && [self.settingsPopover isPopoverVisible]) {
        [self.settingsPopover dismissPopoverAnimated:NO];
    }
    
    [self setIsLoggedIn:[[NSUserDefaults standardUserDefaults] boolForKey:kShelbyDefaultUserAuthorized]];
    
    if (!self.isLoggedIn) {
        [self setUserNickname:nil];
        [self resetVersionLabel];
        //djs this shouldn't ever fetch channels
//        [self fetchAllChannels];
    }

}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    [self dismissPopover];
}
@end