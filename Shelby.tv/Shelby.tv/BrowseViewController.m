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
#import "SPCategoryViewCell.h"
#import "SPVideoItemViewCellLabel.h"

// Utilities
#import "ImageUtilities.h"

// Models
#import "SPCategoryDisplay.h"

@interface BrowseViewController ()

@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (weak, nonatomic) IBOutlet UITableView *categoriesTable;

@property (strong, nonatomic) NSString *userNickname;
@property (assign, nonatomic) BOOL isLoggedIn;

@property (nonatomic) LoginView *loginView;
@property (nonatomic) SignupView *signupView;
@property (nonatomic) UIView *backgroundLoginView;

@property (nonatomic) NSMutableArray *categories;
@property (nonatomic) NSMutableDictionary *categoriesData;
@property (nonatomic) NSMutableDictionary *changableDataMapper;

@property (assign, nonatomic) SecretMode secretMode;

@property (assign, nonatomic) NSUInteger activeCategoryIndex;
@property (assign, nonatomic) SPVideoReel *activeVideoReel;

@property (assign, nonatomic) BOOL animationInProgress;

- (void)fetchUserNickname;

// TODO: need to port from MeVC
/// Gesture Methods
//- (void)setupGestures;
//- (void)likesGestureScale:(UIPinchGestureRecognizer *)gesture;
//- (void)personalRollGestureScale:(UIPinchGestureRecognizer *)gesture;
//- (void)streamGestureScale:(UIPinchGestureRecognizer *)gesture;

// Helper methods
- (SPCategoryViewCell *)loadCell:(NSInteger)row withDirection:(BOOL)up animated:(BOOL)animated;

/// Authentication Methods
- (void)loginAction;
- (void)logoutAction;

/// Video Player Launch Methods
- (void)launchPlayer:(NSUInteger)categoryIndex;
- (void)launchPlayer:(NSUInteger)categoryIndex andVideo:(NSUInteger)videoIndex;
- (void)launchPlayer:(NSUInteger)categoryIndex andVideo:(NSUInteger)videoIndex withGroupType:(GroupType)groupType;
- (void)presentViewController:(GAITrackedViewController *)viewControllerToPresent;
- (void)animateSwitchCategories:(SPVideoReel *)viewControllerToPresent;
- (void)animateOpenCategories:(SPVideoReel *)viewControllerToPresent;
- (void)animateCloseCategories:(SPVideoReel *)viewController;
- (NSInteger)nextCategoryForDirection:(BOOL)up;

/// Version Label
- (void)resetVersionLabel;

@end

@implementation BrowseViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
    }
    return self;
}

#pragma mark - View Lifecycle Methods
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchAllCategories) name:kShelbyNotificationCategoriesFinishedSync object:nil];

    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarStyleBlackTranslucent];
    
    [self setAnimationInProgress:NO];
    
    [self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"background"]]];
    
    [self setTrackedViewName:@"Browse"];
    
    [self resetVersionLabel];
    
    [self setIsLoggedIn:[[NSUserDefaults standardUserDefaults] boolForKey:kShelbyDefaultUserAuthorized]];
    
    [self fetchUserNickname];
    
    [self setCategories:[@[] mutableCopy]];
    [self setCategoriesData:[@{} mutableCopy]];
    [self setChangableDataMapper:[@{} mutableCopy]];
    
    [self setSecretMode:SecretMode_None];
    
    // Register Cell Nibs
    [self.categoriesTable registerNib:[UINib nibWithNibName:@"SPCategoryViewCell" bundle:nil] forCellReuseIdentifier:@"SPCategoryViewCell"];
    [self fetchAllCategories];
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

- (void)fetchAllCategories
{
    CoreDataUtility *datautility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    [self.categories removeAllObjects];
    [self.categories addObjectsFromArray:[datautility fetchAllCategories]];
    
        int i = 0;
        for (id category in self.categories) {
            NSMutableArray *frames = nil;
            if ([category isKindOfClass:[Channel class]]) {
                frames = [datautility fetchFramesInCategoryChannel:[((Channel *)category) channelID]];
            } else if ([category isKindOfClass:[Roll class]]) {
                frames = [datautility fetchFramesInCategoryRoll:[((Roll *)category) rollID]];
            } else {
                frames = [@[] mutableCopy];
            }
            [self.categoriesData setObject:frames forKey:[NSNumber numberWithInt:i]];
            i++;
        }
        
        [self.categoriesTable reloadData];
}

- (SPCategoryViewCell *)loadCell:(NSInteger)row withDirection:(BOOL)up animated:(BOOL)animated
{
    SPCategoryViewCell *categoryCell = (SPCategoryViewCell *)[self.categoriesTable cellForRowAtIndexPath:[NSIndexPath indexPathForItem:row inSection:0]];
    if (!categoryCell) {
        UITableViewScrollPosition position = up ? UITableViewScrollPositionTop : UITableViewScrollPositionBottom;
        NSIndexPath *nextIndexPath = [NSIndexPath indexPathForItem:row inSection:0];
        [self.categoriesTable scrollToRowAtIndexPath:nextIndexPath atScrollPosition:position animated:animated];
        [self.categoriesTable reloadRowsAtIndexPaths:@[nextIndexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
    
    return categoryCell;
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
    return [self.categories count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    SPCategoryViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SPCategoryViewCell" forIndexPath:indexPath];
    
    UICollectionView *categoryFrames = [cell categoryFrames];
    [categoryFrames registerNib:[UINib nibWithNibName:@"SPVideoItemViewCell" bundle:nil] forCellWithReuseIdentifier:@"SPVideoItemViewCell"];
    [categoryFrames setDelegate:self];
    [categoryFrames setDataSource:self];
    [categoryFrames reloadData];
    NSUInteger hash = [categoryFrames hash];
    [self.changableDataMapper setObject:[NSNumber numberWithInt:indexPath.row] forKey:[NSNumber numberWithUnsignedInt:hash]];
    
    id category = (id)self.categories[indexPath.row];
    if ([category isKindOfClass:[NSManagedObject class]]) {
        NSManagedObjectID *categoryObjectID = [category objectID];
        NSManagedObjectContext *context = [self context];
        NSString *title = nil;
        NSString *color = nil;
        if ([category isMemberOfClass:[Channel class]]) {
            Channel *channel = (Channel *)[context existingObjectWithID:categoryObjectID error:nil];
            title = [channel displayTitle];
            color = [channel displayColor];
        } else if ([category isMemberOfClass:[Roll class]]) {
            Roll *roll = (Roll *)[context existingObjectWithID:categoryObjectID error:nil];
            title = [roll displayTitle];
            color = [roll displayColor];
        }

        [cell setcategoryColor:color andTitle:title];
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
    NSNumber *key = self.changableDataMapper[changableMapperKey];
    NSMutableArray *frames = self.categoriesData[key];
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
    NSNumber *key = self.changableDataMapper[changableMapperKey];
    NSMutableArray *frames = self.categoriesData[key];
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
    NSNumber *key = self.changableDataMapper[changableMapperKey];
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
    id category = (id)self.categories[categoryIndex];
    GroupType groupType = GroupType_CategoryRoll;
    if ([category isMemberOfClass:[Channel class]]) {
        groupType = GroupType_CategoryChannel;
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
        NSManagedObjectID *objectID = [(self.categories)[categoryIndex] objectID];

        switch (groupType) {
            case GroupType_CategoryChannel:
            {
                Channel *channel = (Channel *)[context existingObjectWithID:objectID error:nil];
                videoFrames = [dataUtility fetchFramesInCategoryChannel:[channel channelID]];
                errorMessage = @"No videos in Category Channel.";
                title = [channel displayTitle];
                break;
            }
            case GroupType_CategoryRoll:
            {
                Roll *roll = (Roll *)[context existingObjectWithID:objectID error:nil];
                videoFrames = [dataUtility fetchFramesInCategoryRoll:[roll rollID]];
                errorMessage = @"No videos in Category Roll.";
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
                if (groupType == GroupType_CategoryChannel) { // Category Channel
                    NSManagedObjectID *objectID = [(self.categories)[categoryIndex] objectID];
                    Channel *channel = (Channel *)[mainThreadContext existingObjectWithID:objectID error:nil];
                    categoryID = channel.channelID;
                } else if (groupType == GroupType_CategoryRoll) { // Category Roll
                    NSManagedObjectID *objectID = [(self.categories)[categoryIndex] objectID];
                    Roll *roll = (Roll *)[mainThreadContext existingObjectWithID:objectID error:nil];
                    categoryID = roll.rollID;
                }

                if (self.activeVideoReel) {
                    [self.activeVideoReel cleanup];
                }
                SPVideoReel *videoReel = [[SPVideoReel alloc] initWithGroupType:groupType groupTitle:title videoFrames:videoFrames videoStartIndex:videoIndex andCategoryID:categoryID];
                [videoReel setDelegate:self];
                [self setActiveCategoryIndex:categoryIndex];
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

- (void)animateSwitchCategories:(SPVideoReel *)viewControllerToPresent
{
    [self.activeVideoReel dismissViewControllerAnimated:NO completion:^{
        [self presentViewController:viewControllerToPresent animated:NO completion:^{
            [self setActiveVideoReel:nil];
        }];
        
    }];
}

- (void)animateOpenCategories:(SPVideoReel *)viewControllerToPresent
{
    if (self.animationInProgress) {
        return;
    } else {
        [self setAnimationInProgress:YES];
    }
    
    SPCategoryViewCell *categoryCell = (SPCategoryViewCell *)[self.categoriesTable cellForRowAtIndexPath:[NSIndexPath indexPathForItem:self.activeCategoryIndex inSection:0]];
    
    UIImage *categoryImage = [ImageUtilities screenshot:categoryCell];
    UIImageView *categoryImageView = [[UIImageView alloc] initWithImage:categoryImage];
    
    CGPoint categoryCellOriginInWindow = [self.view convertPoint:categoryCell.frame.origin fromView:self.categoriesTable];
    
    CGRect topRect = CGRectMake(0, 0, 1024, categoryCellOriginInWindow.y);
    CGRect bottomRect = CGRectMake(0, categoryCellOriginInWindow.y + categoryCell.frame.size.height, 1024, 1024 - categoryCellOriginInWindow.y);
  
    UIImage *categoriesImage = [ImageUtilities screenshot:self.view];
    UIImage *topImage = [ImageUtilities crop:categoriesImage inRect:topRect];
    UIImage *bottomImage = [ImageUtilities crop:categoriesImage inRect:bottomRect];
    
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
        [UIView animateWithDuration:1 animations:^{
            [topImageView setFrame:CGRectMake(0, -topImageView.frame.size.height, topImageView.frame.size.width, topImageView.frame.size.height)];
            [bottomImageView setFrame:CGRectMake(0, 900, bottomImageView.frame.size.width, bottomImageView.frame.size.height)];
            [categoryImageView setFrame:CGRectMake(0, 1024, categoryImageView.frame.size.width, categoryImageView.frame.size.height)];
            
        } completion:^(BOOL finished) {
            [categoryImageView removeFromSuperview];
            [bottomImageView removeFromSuperview];
            [topImageView removeFromSuperview];
            [self setAnimationInProgress:NO];
        }];
    }];
}

- (void)animateCloseCategories:(SPVideoReel *)viewController
{
    if (self.animationInProgress) {
        return;
    } else {
        [self setAnimationInProgress:YES];
    }

    SPCategoryViewCell *categoryCell = (SPCategoryViewCell *)[self.categoriesTable cellForRowAtIndexPath:[NSIndexPath indexPathForItem:self.activeCategoryIndex inSection:0]];
    
    UIImage *categoryImage = [ImageUtilities screenshot:categoryCell];
    UIImageView *categoryImageView = [[UIImageView alloc] initWithImage:categoryImage];
    
    CGPoint categoryCellOriginInWindow = [self.view convertPoint:categoryCell.frame.origin fromView:self.categoriesTable];
    
    CGRect topRect = CGRectMake(0, 0, 1024, categoryCellOriginInWindow.y);
    CGRect bottomRect = CGRectMake(0, categoryCellOriginInWindow.y + categoryCell.frame.size.height, 1024, 1024 - categoryCellOriginInWindow.y);
    
    UIImage *categoriesImage = [ImageUtilities screenshot:self.view];
    UIImage *topImage = [ImageUtilities crop:categoriesImage inRect:topRect];
    UIImage *bottomImage = [ImageUtilities crop:categoriesImage inRect:bottomRect];
    
    UIImageView *topImageView = [[UIImageView alloc] initWithImage:topImage];
    UIImageView *bottomImageView = [[UIImageView alloc] initWithImage:bottomImage];
    
    [viewController.view addSubview:categoryImageView];
    [viewController.view addSubview:bottomImageView];
    [viewController.view addSubview:topImageView];
    
    [topImageView setFrame:CGRectMake(0, -topImageView.frame.size.height, topImageView.frame.size.width, topImageView.frame.size.height)];
    [bottomImageView setFrame:CGRectMake(0, 900, bottomImageView.frame.size.width, bottomImageView.frame.size.height)];
    [categoryImageView setFrame:CGRectMake(0, 1024, categoryImageView.frame.size.width, categoryImageView.frame.size.height)];

    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarStyleBlackTranslucent];
    
    [UIView animateWithDuration:1 animations:^{
        [categoryImageView setFrame:CGRectMake(0, categoryCellOriginInWindow.y + 20, 1024, categoryCell.frame.size.height)];
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
    NSInteger nextCategory = self.activeCategoryIndex + next;
    if (nextCategory < 0) {
        nextCategory = [self.categories count] + nextCategory;
    } else if (nextCategory == [self.categories count]) {
        nextCategory = 0;
    }

    return nextCategory;
}

- (void)presentViewController:(GAITrackedViewController *)viewControllerToPresent
{
    if (self.activeVideoReel) {
        [self animateSwitchCategories:(SPVideoReel *)viewControllerToPresent];
    } else {
        [self animateOpenCategories:(SPVideoReel *)viewControllerToPresent];
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
    [self fetchAllCategories];
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
    [self animateCloseCategories:videoReel];
}

- (SPCategoryDisplay *)categoryDisplayForDirection:(BOOL)up
{
    NSInteger nextCategory = [self nextCategoryForDirection:up];
    
    SPCategoryViewCell *categoryCell = [self loadCell:nextCategory withDirection:up animated:NO];
    SPCategoryDisplay *categoryDisplay = [[SPCategoryDisplay alloc] initWithCategoryColor:[categoryCell categoryDisplayColor] andCategoryDisplayTitle:[categoryCell categoryDisplayTitle]];
    
    return categoryDisplay;
}
@end