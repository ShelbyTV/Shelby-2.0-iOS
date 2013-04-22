//
//  BrowseViewController.m
//  Shelby.tv
//
//  Created by Keren on 2/13/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import "BrowseViewController.h"

// Views
#import "CollectionViewGroupsLayout.h"
#import "LoginView.h"
#import "SignupView.h"
#import "PageControl.h"
#import "SPVideoItemViewCell.h"
#import "SPChannelCell.h"
#import "SPVideoItemViewCellLabel.h"

// Utilities
#import "ImageUtilities.h"

// Models
#import "SPChannelDisplay.h"

@interface BrowseViewController ()

@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (weak, nonatomic) IBOutlet UITableView *channelsTableView;

@property (strong, nonatomic) NSString *userNickname;
@property (assign, nonatomic) BOOL isLoggedIn;

@property (nonatomic) LoginView *loginView;
@property (nonatomic) SignupView *signupView;
@property (nonatomic) UIView *backgroundLoginView;

@property (nonatomic) NSMutableArray *channels;
@property (nonatomic) NSMutableDictionary *channelsDataSource;
@property (nonatomic) NSMutableDictionary *changeableDataMapper;
@property (nonatomic) NSMutableSet *collectionViewDataSourceUpdater;

@property (assign, nonatomic) SecretMode secretMode;

@property (assign, nonatomic) NSUInteger activeChannelIndex;
@property (assign, nonatomic) SPVideoReel *activeVideoReel;

@property (assign, nonatomic) BOOL animationInProgress;

- (void)fetchUserNickname;

// Helper methods
- (SPChannelCell *)loadCell:(NSInteger)row withDirection:(BOOL)up animated:(BOOL)animated;
- (NSInteger)indexForChannel:(NSString *)categoryID;

/// Authentication Methods
- (void)loginAction;
- (void)logoutAction;

/// Video Player Launch Methods
- (void)launchPlayer:(NSUInteger)categoryIndex;
- (void)launchPlayer:(NSUInteger)categoryIndex andVideo:(NSUInteger)videoIndex;
- (void)launchPlayer:(NSUInteger)categoryIndex andVideo:(NSUInteger)videoIndex withGroupType:(GroupType)groupType;
- (void)presentViewController:(GAITrackedViewController *)viewControllerToPresent;
- (void)animateSwitchChannels:(SPVideoReel *)viewControllerToPresent;
- (void)animateOpenChannels:(SPVideoReel *)viewControllerToPresent;
- (void)animateCloseChannels:(SPVideoReel *)viewController;
- (NSInteger)nextCategoryForDirection:(BOOL)up;

/// Fetch Methods
- (void)fetchOlderFramesForIndex:(NSNumber *)key;
- (void)fetchOlderFramesDidFail:(NSNotification *)notification;
- (void)dataSourceDidUpdateFromWeb:(NSNotification *)notification;
- (void)fetchDataSourceForChannel:(NSNotification *)notification;
- (void)setChannelsForTable;

/// Version Label
- (void)resetVersionLabel;

@end

@implementation BrowseViewController

#pragma mark - View Lifecycle Methods
- (void)viewDidLoad
{
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataSourceDidUpdateFromWeb:) name:kShelbySPUserDidScrollToUpdate object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchOlderFramesDidFail:) name:kShelbyNotificationFetchingOlderVideosFailed object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchDataSourceForChannel:) name:kShelbyNotificationChannelDataFetched object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setChannelsForTable) name:kShelbyNotificationChannelsFinishedSync object:nil];
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarStyleBlackTranslucent];
    
    [self setAnimationInProgress:NO];
    
    [self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"background"]]];
    
    [self setTrackedViewName:@"Browse"];
    
    [self resetVersionLabel];
    
    [self setIsLoggedIn:[[NSUserDefaults standardUserDefaults] boolForKey:kShelbyDefaultUserAuthorized]];
    
    [self fetchUserNickname];
    
    [self setChannels:[@[] mutableCopy]];
    [self setChannelsDataSource:[@{} mutableCopy]];
    [self setChangeableDataMapper:[@{} mutableCopy]];
    self.collectionViewDataSourceUpdater = [[NSMutableSet alloc] init];
    
    [self setSecretMode:SecretMode_None];
    
    // Register Cell Nibs
    [self.channelsTableView registerNib:[UINib nibWithNibName:@"SPChannelCell" bundle:nil] forCellReuseIdentifier:@"SPChannelCell"];
    [self fetchAllChannels];
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

#pragma mark - Private Methods
- (NSManagedObjectContext *)context
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    return [appDelegate context];
}

- (void)fetchUserNickname
{
    if ([self isLoggedIn]) {
        CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
        User *user = [dataUtility fetchUser];
        [self setUserNickname:[user nickname]];
    }
}

- (void)setChannelsForTable
{
    CoreDataUtility *datautility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    [self.channels removeAllObjects];
    [self.channels addObjectsFromArray:[datautility fetchAllChannels]];
 
    [self.channelsTableView reloadData];
}

- (void)fetchDataSourceForChannel:(NSNotification *)notification
{
    // KP KP: TODO: once we add logged in user, add support for Personal Rolls, Likes and Stream
    
    NSString *channelID = [notification object];
    if (channelID && [channelID isKindOfClass:[NSString class]]) {
        NSInteger i = [self indexForChannel:channelID];
        if (i == -1) {
            return;
        }
        NSMutableArray *frames = self.channelsDataSource[[NSNumber numberWithInt:i]];
        if (frames || [frames count] != 0) {
            return;
        }
        id category = self.channels[i];
        if ([category isKindOfClass:[NSManagedObject class]]) {
            NSManagedObjectID *categoryObjectID = [category objectID];
            NSManagedObjectContext *context = [self context];
            if ([category isMemberOfClass:[Dashboard class]]) {
                Dashboard *dashboard = (Dashboard *)[context existingObjectWithID:categoryObjectID error:nil];
                NSString *objectID = [dashboard dashboardID];
                if ([objectID isEqualToString:channelID]) {
                    CoreDataUtility *datautility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
                    frames = [datautility fetchDashboardEntriesInDashboard:channelID];
                }
            } else if ([category isMemberOfClass:[Roll class]]) {
                Roll *roll = (Roll *)[context existingObjectWithID:categoryObjectID error:nil];
                NSString *objectID = [roll rollID];
                if ([objectID isEqualToString:channelID]) {
                    CoreDataUtility *datautility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
                    frames = [datautility fetchFramesInCategoryRoll:channelID];
                }
            }
        }
     
        if (frames) {
            [self.channelsDataSource setObject:frames forKey:[NSNumber numberWithInt:i]];
            [self.channelsTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
        }
    }
}

- (void)fetchAllChannels
{
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    [self.channels removeAllObjects];
    [self.channels addObjectsFromArray:[dataUtility fetchAllChannels]];
    
    int i = 0;
    for (id channel in self.channels) {
        NSMutableArray *frames = nil;
        if ([channel isKindOfClass:[Dashboard class]]) {
            CoreDataUtility *channelDataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
            frames = [channelDataUtility fetchDashboardEntriesInDashboard:[((Dashboard *)channel) dashboardID]];
        } else if ([channel isKindOfClass:[Roll class]]) {
            CoreDataUtility *rollDataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
            frames = [rollDataUtility fetchFramesInCategoryRoll:[((Roll *)channel) rollID]];
        } else {
            frames = [@[] mutableCopy];
        }
        [self.channelsDataSource setObject:frames forKey:[NSNumber numberWithInt:i]];
        i++;
    }
    
    [self.channelsTableView reloadData];
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

- (NSInteger)indexForChannel:(NSString *)categoryID
{
    if (categoryID && [categoryID isKindOfClass:[NSString class]]) {
        NSInteger i = 0;
        for (id category in self.channels) {
            if ([category isKindOfClass:[NSManagedObject class]]) {
                NSManagedObjectID *categoryObjectID = [category objectID];
                NSManagedObjectContext *context = [self context];
                if ([category isMemberOfClass:[Dashboard class]]) {
                    Dashboard *dashboard = (Dashboard *)[context existingObjectWithID:categoryObjectID error:nil];
                    NSString *dashboardID = [dashboard dashboardID];
                    if ([dashboardID isEqualToString:categoryID]) {
                        return i;
                    }
                } else if ([category isMemberOfClass:[Roll class]]) {
                    Roll *roll = (Roll *)[context existingObjectWithID:categoryObjectID error:nil];
                    NSString *rollID = [roll rollID];
                    if ([rollID isEqualToString:categoryID]) {
                        return i;
                    }
                }
            }
            i++;
        }
    }
    
    return -1; // Category wasn't found
}

- (void)resetVersionLabel
{
    [self.versionLabel setFont:[UIFont fontWithName:@"Ubuntu-Bold" size:_versionLabel.font.pointSize]];
    [self.versionLabel setText:[NSString stringWithFormat:@"Shelby.tv for iPad v%@", kShelbyCurrentVersion]];
    [self.versionLabel setTextColor:kShelbyColorBlack];
}


#pragma mark - UITableViewDataSource Methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.channels count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    SPChannelCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SPChannelCell" forIndexPath:indexPath];
    
    UICollectionView *categoryFrames = [cell categoryFrames];
    [categoryFrames registerNib:[UINib nibWithNibName:@"SPVideoItemViewCell" bundle:nil] forCellWithReuseIdentifier:@"SPVideoItemViewCell"];
    [categoryFrames setDelegate:self];
    [categoryFrames setDataSource:self];
    [categoryFrames reloadData];
    NSUInteger hash = [categoryFrames hash];
    [self.changeableDataMapper setObject:[NSNumber numberWithInt:indexPath.row] forKey:[NSNumber numberWithUnsignedInt:hash]];
    
    id category = (id)self.channels[indexPath.row];
    if ([category isKindOfClass:[NSManagedObject class]]) {
        NSManagedObjectID *categoryObjectID = [category objectID];
        NSManagedObjectContext *context = [self context];
        NSString *title = nil;
        NSString *color = nil;
        if ([category isMemberOfClass:[Dashboard class]]) {
            Dashboard *dashboard = (Dashboard *)[context existingObjectWithID:categoryObjectID error:nil];
            title = [dashboard displayTitle];
            color = [dashboard displayColor];
        } else if ([category isMemberOfClass:[Roll class]]) {
            Roll *roll = (Roll *)[context existingObjectWithID:categoryObjectID error:nil];
            title = [roll displayTitle];
            color = [roll displayColor];
        }

        [cell setChannelColor:color andTitle:title];
    }

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

    NSManagedObjectContext *context = [self context];
    id category = (id)self.channels[[key intValue]];
    NSString *categoryID = nil;
    if ([category isMemberOfClass:[Roll class]]) {
        Roll *roll = (id)category;
        roll = (Roll *)[context existingObjectWithID:[roll objectID] error:nil];
        categoryID = roll.rollID;
    } else if ([category isMemberOfClass:[Dashboard class]]) {
        Dashboard *dashboard = (id)category;
        dashboard = (Dashboard *)[context existingObjectWithID:[dashboard objectID] error:nil];
        categoryID = dashboard.dashboardID;
    }

    NSInteger cellsLeftToDisplay = [frames count] - [indexPath row];
    if (cellsLeftToDisplay < 10) {
        
        if ( ![self.collectionViewDataSourceUpdater containsObject:categoryID] ) {
            [self.collectionViewDataSourceUpdater addObject:categoryID];   
            [self fetchOlderFramesForIndex:key];
        }
    
    }
    
    Frame *frame = (Frame *)frames[indexPath.row];
    
    if (frame) {
        NSManagedObjectContext *context = [self context];
        NSManagedObjectID *frameObjectID = [frame objectID];
        Frame *videoFrame = (Frame *)[context existingObjectWithID:frameObjectID error:nil];
        
        if (videoFrame && [videoFrame video]) {
            [AsynchronousFreeloader loadImageFromLink:videoFrame.video.thumbnailURL
                                         forImageView:cell.thumbnailImageView
                                      withPlaceholder:[UIImage imageNamed:@"videoListThumbnail"]
                                       andContentMode:UIViewContentModeCenter];
            
            NSManagedObjectID *videoObjectID = [videoFrame.video objectID];
            if (videoObjectID) {
                
                Video *video = (Video *)[context existingObjectWithID:videoObjectID error:nil];
                
                if (video) {
                    
                    [cell.caption setText:[video caption]];
                    CGRect captionFrame = [cell.caption frame];
                    CGFloat textBasedHeight = [cell.caption.text sizeWithFont:[cell.caption font]
                                                                     constrainedToSize:captionFrame.size
                                                                lineBreakMode:NSLineBreakByWordWrapping].height;
                    
                    [cell.caption setFrame:CGRectMake(captionFrame.origin.x,
                                                      cell.frame.size.height - textBasedHeight,
                                                      cell.frame.size.width,
                                                      textBasedHeight)];
                }
            }
        }
    }

    return cell;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
}

- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
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
- (void)loginAction
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

- (void)logoutAction
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Logout?"
                                                        message:@"Are you sure you want to logout?"
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Logout", nil];
 	
    [alertView show];
}


#pragma mark - Video Player Launch Methods (Private)
- (void)launchPlayer:(NSUInteger)categoryIndex
{
    [self launchPlayer:categoryIndex andVideo:0];
}

- (void)launchPlayer:(NSUInteger)categoryIndex andVideo:(NSUInteger)videoIndex
{
    id category = (id)self.channels[categoryIndex];
    GroupType groupType = GroupType_ChannelRoll;
    if ([category isMemberOfClass:[Dashboard class]]) {
        groupType = GroupType_ChannelDashboard;
    }
    
    [self launchPlayer:categoryIndex andVideo:videoIndex withGroupType:groupType];
}

- (void)launchPlayer:(NSUInteger)categoryIndex andVideo:(NSUInteger)videoIndex withGroupType:(GroupType)groupType
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
        NSMutableArray *videoFrames = nil;
        NSString *errorMessage = nil;
        NSString *title = nil;

        NSManagedObjectContext *context = [self context];
        NSManagedObjectID *objectID = [(self.channels)[categoryIndex] objectID];

        switch (groupType) {
            case GroupType_ChannelDashboard:
            {
                Dashboard *dashboard = (Dashboard *)[context existingObjectWithID:objectID error:nil];
                videoFrames = [dataUtility fetchDashboardEntriesInDashboard:[dashboard dashboardID]];
                errorMessage = @"No videos in Channel Dashboard.";
                title = [dashboard displayTitle];
                break;
            }
            case GroupType_ChannelRoll:
            {
                Roll *roll = (Roll *)[context existingObjectWithID:objectID error:nil];
                videoFrames = [dataUtility fetchFramesInCategoryRoll:[roll rollID]];
                errorMessage = @"No videos in Channel Roll.";
                title = [roll displayTitle];
                break;
            }
            default:
            {
                return;
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([videoFrames count]) {
                NSManagedObjectContext *mainThreadContext = [self context];
                NSString *categoryID = nil;
                if (groupType == GroupType_ChannelDashboard) { // Category Channel
                    NSManagedObjectID *objectID = [(self.channels)[categoryIndex] objectID];
                    Dashboard *dashboard = (Dashboard *)[mainThreadContext existingObjectWithID:objectID error:nil];
                    categoryID = dashboard.dashboardID;
                } else if (groupType == GroupType_ChannelRoll) { // Category Roll
                    NSManagedObjectID *objectID = [(self.channels)[categoryIndex] objectID];
                    Roll *roll = (Roll *)[mainThreadContext existingObjectWithID:objectID error:nil];
                    categoryID = roll.rollID;
                }

                if (self.activeVideoReel) {
                    [self.activeVideoReel cleanup];
                }
                SPVideoReel *videoReel = [[SPVideoReel alloc] initWithGroupType:groupType groupTitle:title videoFrames:videoFrames videoStartIndex:videoIndex andCategoryID:categoryID];
                [videoReel setDelegate:self];
                [self setActiveChannelIndex:categoryIndex];
                [self presentViewController:videoReel];

            } else {
                
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                    message:errorMessage
                                                                   delegate:self
                                                          cancelButtonTitle:@"Dismiss"
                                                          otherButtonTitles:nil];
                
                [alertView show];
                
            }
            
        });
    });
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
    
    SPChannelCell *categoryCell = (SPChannelCell *)[self.channelsTableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:self.activeChannelIndex inSection:0]];
    
    UIImage *categoryImage = [ImageUtilities screenshot:categoryCell];
    UIImageView *categoryImageView = [[UIImageView alloc] initWithImage:categoryImage];
    
    CGPoint categoryCellOriginInWindow = [self.view convertPoint:categoryCell.frame.origin fromView:self.channelsTableView];
    
    CGRect topRect = CGRectMake(0, 0, 1024, categoryCellOriginInWindow.y);
    CGRect bottomRect = CGRectMake(0, categoryCellOriginInWindow.y + categoryCell.frame.size.height, 1024, 1024 - categoryCellOriginInWindow.y);
  
    UIImage *channelsImage = [ImageUtilities screenshot:self.view];
    UIImage *topImage = [ImageUtilities crop:channelsImage inRect:topRect];
    UIImage *bottomImage = [ImageUtilities crop:channelsImage inRect:bottomRect];
    
    UIImageView *topImageView = [[UIImageView alloc] initWithImage:topImage];
    UIImageView *bottomImageView = [[UIImageView alloc] initWithImage:bottomImage];
    
    [viewControllerToPresent.view addSubview:categoryImageView];
    [viewControllerToPresent.view addSubview:bottomImageView];
    [viewControllerToPresent.view addSubview:topImageView];
    [categoryImageView setFrame:CGRectMake(0, categoryCellOriginInWindow.y + 20, 1024, categoryCell.frame.size.height)];
    [topImageView setFrame:CGRectMake(topRect.origin.x, topRect.origin.y + 20, topRect.size.width, topRect.size.height)];
    [bottomImageView setFrame:CGRectMake(bottomRect.origin.x, bottomRect.origin.y + 20, bottomRect.size.width, bottomRect.size.height)];

    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarStyleBlackTranslucent];
    
    [self presentViewController:viewControllerToPresent animated:NO completion:^{
        [UIView animateWithDuration:1 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            [topImageView setFrame:CGRectMake(0, -topImageView.frame.size.height, topImageView.frame.size.width, topImageView.frame.size.height)];
            [bottomImageView setFrame:CGRectMake(0, 900, bottomImageView.frame.size.width, bottomImageView.frame.size.height)];
            [categoryImageView setFrame:CGRectMake(51, categoryImageView.frame.origin.y, categoryImageView.frame.size.width*0.9, categoryImageView.frame.size.height*0.9)];
            
            [categoryImageView setAlpha:0];
        } completion:^(BOOL finished) {
            [categoryImageView removeFromSuperview];
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

    SPChannelCell *categoryCell = (SPChannelCell *)[self.channelsTableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:self.activeChannelIndex inSection:0]];
    
    UIImage *categoryImage = [ImageUtilities screenshot:categoryCell];
    UIImageView *categoryImageView = [[UIImageView alloc] initWithImage:categoryImage];
    
    CGPoint categoryCellOriginInWindow = [self.view convertPoint:categoryCell.frame.origin fromView:self.channelsTableView];
    
    CGRect topRect = CGRectMake(0, 0, 1024, categoryCellOriginInWindow.y);
    CGRect bottomRect = CGRectMake(0, categoryCellOriginInWindow.y + categoryCell.frame.size.height, 1024, 1024 - categoryCellOriginInWindow.y);
    
    UIImage *channelsImage = [ImageUtilities screenshot:self.view];
    UIImage *topImage = [ImageUtilities crop:channelsImage inRect:topRect];
    UIImage *bottomImage = [ImageUtilities crop:channelsImage inRect:bottomRect];
    
    UIImageView *topImageView = [[UIImageView alloc] initWithImage:topImage];
    UIImageView *bottomImageView = [[UIImageView alloc] initWithImage:bottomImage];
    
    [viewController.view addSubview:categoryImageView];
    [viewController.view addSubview:bottomImageView];
    [viewController.view addSubview:topImageView];
    
    [topImageView setFrame:CGRectMake(0, -topImageView.frame.size.height, topImageView.frame.size.width, topImageView.frame.size.height)];
    [bottomImageView setFrame:CGRectMake(0, 900, bottomImageView.frame.size.width, bottomImageView.frame.size.height)];
    [categoryImageView setFrame:CGRectMake(0, 1024, categoryImageView.frame.size.width, categoryImageView.frame.size.height)];

    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarStyleBlackTranslucent];
    [categoryImageView setAlpha:0];

    [categoryImageView setFrame:CGRectMake(51, categoryCellOriginInWindow.y, categoryImageView.frame.size.width*0.9, categoryImageView.frame.size.height*0.9)];
    
    [UIView animateWithDuration:0.45 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
       [categoryImageView setFrame:CGRectMake(0, categoryCellOriginInWindow.y + 20, 1024, categoryCell.frame.size.height)];
        
        [categoryImageView setAlpha:1];
        [topImageView setFrame:CGRectMake(topRect.origin.x, topRect.origin.y + 20, topRect.size.width, topRect.size.height)];
        [bottomImageView setFrame:CGRectMake(bottomRect.origin.x, bottomRect.origin.y + 20, bottomRect.size.width, bottomRect.size.height)];
        
    } completion:^(BOOL finished) {
        [categoryImageView removeFromSuperview];
        [bottomImageView removeFromSuperview];
        [topImageView removeFromSuperview];
        [viewController cleanup];
        [viewController dismissViewControllerAnimated:NO completion:nil];
        [self setAnimationInProgress:NO];
    }];
}


- (NSInteger)nextCategoryForDirection:(BOOL)up
{
    NSInteger next = up ? -1 : 1;
    NSInteger nextCategory = self.activeChannelIndex + next;
    if (nextCategory < 0) {
        nextCategory = [self.channels count] + nextCategory;
    } else if (nextCategory == [self.channels count]) {
        nextCategory = 0;
    }

    return nextCategory;
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

    NSManagedObjectContext *context = [self context];
    
    id category = (id)self.channels[[key intValue]];
    GroupType groupType = GroupType_ChannelDashboard;
    NSString *categoryID = nil;
    if ([category isMemberOfClass:[Roll class]]) {
        groupType = GroupType_ChannelRoll;
        Roll *roll = (id)category;
        roll = (Roll *)[context existingObjectWithID:[roll objectID] error:nil];
        categoryID = roll.rollID;
    } else if ([category isMemberOfClass:[Dashboard class]]) {
        groupType = GroupType_ChannelDashboard;
        Dashboard *dashboard = (id)category;
        dashboard = (Dashboard *)[context existingObjectWithID:[dashboard objectID] error:nil];
        categoryID = dashboard.dashboardID;
    }
    
    switch ( groupType ) {
            
        case GroupType_ChannelDashboard: {
            
            CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
            NSUInteger totalNumberOfVideosInDatabase = [dataUtility fetchCountForCategoryChannel:categoryID];
            NSString *numberToString = [NSString stringWithFormat:@"%d", totalNumberOfVideosInDatabase];
            [ShelbyAPIClient getMoreDashboardEntries:numberToString forChannelDashboard:categoryID];
            
        } break;
            
        case GroupType_ChannelRoll: {
            
            CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
            NSUInteger totalNumberOfVideosInDatabase = [dataUtility fetchCountForCategoryRoll:categoryID];
            NSString *numberToString = [NSString stringWithFormat:@"%d", totalNumberOfVideosInDatabase];
            [ShelbyAPIClient getMoreFrames:numberToString forCategoryRoll:categoryID];
            
        } break;
            
        default: {
            [self.collectionViewDataSourceUpdater removeObject:categoryID];
            // Handle remaining cases later
            
        }
    }
}


- (void)dataSourceDidUpdateFromWeb:(NSNotification *)notification
{
    
    NSString *categoryID = [notification object];
     if (categoryID && [categoryID isKindOfClass:[NSString class]]) {
         
         NSInteger i = [self indexForChannel:categoryID];
         if (i == -1) {
             [self.collectionViewDataSourceUpdater removeObject:categoryID];
             return;
         }
         
         NSManagedObjectContext *context = [self context];
         
         id category = self.channels[i];
         NSString *categoryID = nil;
         GroupType groupType = GroupType_Unknown;
         if ([category isMemberOfClass:[Roll class]]) {
             groupType = GroupType_ChannelRoll;
             Roll *roll = (id)category;
             roll = (Roll *)[context existingObjectWithID:[roll objectID] error:nil];
             categoryID = roll.rollID;
         } else if ([category isMemberOfClass:[Dashboard class]]) {
             groupType = GroupType_ChannelDashboard;
             Dashboard *dashboard = (id)category;
             dashboard = (Dashboard *)[context existingObjectWithID:[dashboard objectID] error:nil];
             categoryID = dashboard.dashboardID;
         }
        
         NSMutableArray *frames = self.channelsDataSource[[NSNumber numberWithInt:i]];
         NSManagedObjectID *lastFramedObjectID = [[frames lastObject] objectID];
         if (!lastFramedObjectID) {
             [self.collectionViewDataSourceUpdater removeObject:categoryID];
             return;
         }
        
         Frame *lastFrame = (Frame *)[context existingObjectWithID:lastFramedObjectID error:nil];
         if (!lastFrame) {
             [self.collectionViewDataSourceUpdater removeObject:categoryID];
             return;
         }
        
         NSDate *date = lastFrame.timestamp;
        
         NSMutableArray *olderFramesArray = [@[] mutableCopy];
        
         switch ( groupType ) {
                
             case GroupType_ChannelDashboard:{
                  CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
                 [olderFramesArray addObjectsFromArray:[dataUtility fetchMoreDashboardEntriesInDashboard:categoryID afterDate:date]];
             } break;
                
             case GroupType_ChannelRoll:{
                  CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
                 [olderFramesArray addObjectsFromArray:[dataUtility fetchMoreFramesInCategoryRoll:categoryID afterDate:date]];
             } break;
                
             default: {
                // Handle remaining cases later  
             }
        }
        
        // If olderFramesArray is populated, compare against existing visddeos, and deduplicate if necessary
        if ( [olderFramesArray count] ) {
            
            Frame *firstFrame = (Frame *)olderFramesArray[0];
            NSManagedObjectID *firstFrameObjectID = [firstFrame objectID];
            if (!firstFrameObjectID) {
                [self.collectionViewDataSourceUpdater removeObject:categoryID];
                return;
            }
            
            firstFrame = (Frame *)[context existingObjectWithID:firstFrameObjectID error:nil];
            if (!firstFrame) {
                [self.collectionViewDataSourceUpdater removeObject:categoryID];
                return;
            }
            if ( [firstFrame.videoID isEqualToString:lastFrame.videoID] ) {
                [olderFramesArray removeObject:firstFrame];
            }
            
            // Add deduplicated frames from olderFramesArray to frames
            [frames addObjectsFromArray:olderFramesArray];
   
            [self.channelsTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
            
        } 
        
         [self.collectionViewDataSourceUpdater removeObject:categoryID];
    }
}

- (void)fetchOlderFramesDidFail:(NSNotification *)notification
{
    NSString *categoryID = [notification object];
    if (categoryID && [categoryID isKindOfClass:[NSString class]]) {
            [self.collectionViewDataSourceUpdater removeObject:categoryID];
    }
}

#pragma mark - UIAlertViewDelegate Methods
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate logout];
        [self setIsLoggedIn:NO];
        [self setUserNickname:nil];
        [self resetVersionLabel];
//        [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
    }
}

#pragma mark - AuthorizationDelegate Methods
- (void)authorizationDidComplete
{
    [self setIsLoggedIn:YES];
    [self fetchUserNickname];
    [self fetchAllChannels];
//    [self.collectionView reloadData];
}

#pragma mark - SPVideoReel Delegate
- (void)userDidSwitchChannel:(SPVideoReel *)videoReel direction:(BOOL)up;
{
    [self setActiveVideoReel:videoReel];

    NSInteger nextCategory = [self nextCategoryForDirection:up];
    [self launchPlayer:nextCategory];
    
    [self loadCell:nextCategory withDirection:up animated:NO];
}

- (void)userDidCloseChannel:(SPVideoReel *)videoReel
{
    [self animateCloseChannels:videoReel];
}

- (SPChannelDisplay *)categoryDisplayForDirection:(BOOL)up
{
    NSInteger nextCategory = [self nextCategoryForDirection:up];
    
    SPChannelCell *channelCell = [self loadCell:nextCategory withDirection:up animated:NO];
    SPChannelDisplay *channelDisplay = [[SPChannelDisplay alloc] initWithChannelColor:[channelCell channelDisplayColor]
                                                               andChannelDisplayTitle:[channelCell channelDisplayTitle]];
    
    return channelDisplay;
}
@end