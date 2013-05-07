//
//  BrowseViewController.m
//  Shelby.tv
//
//  Created by Keren on 2/13/13.
//  Copyright (c) 2013 Shelby TV. All rights reserved.
//

#import "BrowseViewController.h"

// Views
#import "LoginView.h"
#import "SignupView.h"
#import "PageControl.h"
#import "SPVideoItemViewCell.h"
#import "SPChannelCell.h"
#import "SPChannelCollectionView.h"
#import "SPVideoItemViewCellLabel.h"
#import "SettingsViewController.h"
#import "ShelbyBrain.h"


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

// { channelObjectID: [/*array of DashboardEntry or Frame*/], ... }
@property (nonatomic, strong) NSMutableDictionary *channelEntriesByObjectID;

@property (assign, nonatomic) SecretMode secretMode;

@property (assign, nonatomic) NSUInteger activeChannelIndex;
@property (assign, nonatomic) SPVideoReel *activeVideoReel;

@property (assign, nonatomic) BOOL animationInProgress;

@property (nonatomic) UIView *tutorialView;

- (void)fetchUser;

// Helper methods
- (SPChannelCell *)loadCell:(NSInteger)row withDirection:(BOOL)up animated:(BOOL)animated;
- (NSDate *)dateTutorialCompleted;

/// Authentication Methods
- (void)login;
- (void)logout;
- (void)showSettings;

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
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarStyleBlackTranslucent];
    
    [self setAnimationInProgress:NO];
    
    [self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"background"]]];
    
    [self setTrackedViewName:@"Browse"];
    
    [self resetVersionLabel];
    
    [self setIsLoggedIn:[[NSUserDefaults standardUserDefaults] boolForKey:kShelbyDefaultUserAuthorized]];
    
    [self fetchUser];
    
    self.channelEntriesByObjectID = [@{} mutableCopy];
    
    [self setSecretMode:SecretMode_None];
    
    // Register Cell Nibs
    [self.channelsTableView registerNib:[UINib nibWithNibName:@"SPChannelCell" bundle:nil] forCellReuseIdentifier:@"SPChannelCell"];
    //djs this shouldn't ever fetch channels

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

- (void)setEntries:(NSArray *)channelEntries forChannel:(DisplayChannel *)channel
{
    self.channelEntriesByObjectID[channel.objectID] = channelEntries;
    //djs XXX this is going to break once we have non-channels in the view... can't use channel.order
    [self.channelsTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForItem:[channel.order integerValue] inSection:0]] withRowAnimation:NO];
}

- (void)addEntries:(NSArray *)newChannelEntries toEnd:(BOOL)shouldAppend ofChannel:(DisplayChannel *)channel
{
    NSArray *curEntries = self.channelEntriesByObjectID[channel.objectID];
    SPChannelCell *cell = [self cellForChannel:channel];
    NSMutableArray *indexPathsForInsert = [NSMutableArray arrayWithCapacity:[newChannelEntries count]];
    if(shouldAppend){
        self.channelEntriesByObjectID[channel.objectID] = [curEntries arrayByAddingObjectsFromArray:newChannelEntries];
        for(NSUInteger i = 0; i < [newChannelEntries count]; i++){
            [indexPathsForInsert addObject:[NSIndexPath indexPathForItem:i+[curEntries count] inSection:0]];
        }
    } else {
        self.channelEntriesByObjectID[channel.objectID] = [newChannelEntries arrayByAddingObjectsFromArray:curEntries];
        for(NSUInteger i = 0; i < [newChannelEntries count]; i++){
            [indexPathsForInsert addObject:[NSIndexPath indexPathForItem:i inSection:0]];
        }
    }
    [cell.channelFrames insertItemsAtIndexPaths:indexPathsForInsert];
}

- (NSArray *)entriesForChannel:(DisplayChannel *)channel
{
    return self.channelEntriesByObjectID[channel.objectID];
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

#pragma mark - Private Methods

//TODO: FIXME
- (SPChannelCell *)cellForChannel:(DisplayChannel *)channel
{
    //djs XXX this is going to break once we have non-channels in the view... can't use channel.order
    SPChannelCell *cell = (SPChannelCell *)[self.channelsTableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:[channel.order integerValue] inSection:0]];
    return cell;
}

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

- (SPChannelCell *)loadCell:(NSInteger)row withDirection:(BOOL)up animated:(BOOL)animated
{
    SPChannelCell *channelCell = (SPChannelCell *)[self.channelsTableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:row inSection:0]];
    if (!channelCell) {
        UITableViewScrollPosition position = up ? UITableViewScrollPositionTop : UITableViewScrollPositionBottom;
        NSIndexPath *nextIndexPath = [NSIndexPath indexPathForItem:row inSection:0];
        [self.channelsTableView scrollToRowAtIndexPath:nextIndexPath atScrollPosition:position animated:animated];
        [self.channelsTableView reloadRowsAtIndexPaths:@[nextIndexPath] withRowAnimation:UITableViewRowAnimationNone];
        channelCell = (SPChannelCell *)[self.channelsTableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:row inSection:0]];
    }
    
    return channelCell;
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
    
//    [self launchPlayer:0 andVideo:0 withTutorialMode:YES];
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
    
    SPChannelCollectionView *channelFrames = [cell channelFrames];
    [channelFrames registerNib:[UINib nibWithNibName:@"SPVideoItemViewCell" bundle:nil] forCellWithReuseIdentifier:@"SPVideoItemViewCell"];
    [channelFrames setDelegate:self];
    [channelFrames setDataSource:self];
    [channelFrames reloadData];
    
    DisplayChannel *channel = (DisplayChannel *)self.channels[indexPath.row];

    channelFrames.channel = channel;
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
    SPChannelCollectionView *channelCollection = (SPChannelCollectionView *)view;
    if ([channelCollection isKindOfClass:[SPChannelCollectionView class]]) {
        NSArray *entries = self.channelEntriesByObjectID[channelCollection.channel.objectID];
        if (entries) {
             return [entries count];
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
    NSAssert([channelCollection isKindOfClass:[SPChannelCollectionView class]], @"expecting a different class!");
    NSArray *entries = self.channelEntriesByObjectID[channelCollection.channel.objectID];
    NSAssert(indexPath.row < [entries count], @"expected a valid index path row");
    id entry = entries[indexPath.row];
    
    Frame *videoFrame = nil;
    if ([entry isKindOfClass:[DashboardEntry class]]) {
        videoFrame = ((DashboardEntry *)entry).frame;
    } else if([entry isKindOfClass:[Frame class]]) {
        videoFrame = entry;
    } else {
        NSAssert(false, @"Expected a DashboardEntry or Frame");
    }
    if (videoFrame && videoFrame.video) {
        Video *video = videoFrame.video;
        if (video && video.thumbnailURL) {
                [AsynchronousFreeloader loadImageFromLink:video.thumbnailURL
                                             forImageView:cell.thumbnailImageView
                                          withPlaceholder:[UIImage imageNamed:@"videoListThumbnail"]
                                           andContentMode:UIViewContentModeCenter];
        }

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
    
    //load more data
    NSInteger cellsBeyond = [entries count] - [indexPath row];
    if(cellsBeyond == 1){
        [self.browseDelegate loadMoreEntriesInChannel:channelCollection.channel sinceEntry:[entries lastObject]];
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

// KP KP: TODO
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    SPChannelCollectionView *channelCollectionView = (SPChannelCollectionView *)collectionView;
    if ([channelCollectionView isKindOfClass:[SPChannelCollectionView class]]) {
        DisplayChannel *channel = channelCollectionView.channel;
        if ([self.browseDelegate respondsToSelector:@selector(userPressedChannel:atItem:)]) {
            NSArray *entries = self.channelEntriesByObjectID[channelCollectionView.channel.objectID];
            id entry = nil;
            if (indexPath.row < [entries count]) {
                entry = entries[indexPath.row];
            }
            [self.browseDelegate userPressedChannel:channel atItem:entry];
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


#pragma mark - AuthorizationDelegate Methods
- (void)authorizationDidComplete
{
    //djs not sure we're going to be a AuthorizationDelegate in the future
    //but if we are, this is about the only thing I can imagine is okay to do:
    [self setIsLoggedIn:YES];
    //djs the rest of this stuff should be handled by other objects
//    [self fetchUser];
//    [ShelbyAPIClient getStream];
//    [ShelbyAPIClient getPersonalRoll];
//    [ShelbyAPIClient getLikes];
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
    }

}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    [self dismissPopover];
}
@end