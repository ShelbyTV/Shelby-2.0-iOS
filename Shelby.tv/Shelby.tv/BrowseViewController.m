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

// View Controllers
#import "SPVideoReel.h"

// Utilities
#import "ImageUtilities.h"

@interface BrowseViewController ()

@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (strong, nonatomic) NSString *userNickname;
@property (assign, nonatomic) BOOL isLoggedIn;

@property (nonatomic) LoginView *loginView;
@property (nonatomic) SignupView *signupView;
@property (nonatomic) UIView *backgroundLoginView;

@property (nonatomic) NSMutableArray *categories; // TODO: to move to a collection view data file
@property (nonatomic) NSMutableArray *categoriesData;

@property (assign, nonatomic) SecretMode secretMode;

@property (nonatomic) SPVideoReel *videoReel;

- (void)fetchUserNickname;

// TODO: need to port from MeVC
/// Gesture Methods
//- (void)setupGestures;
//- (void)likesGestureScale:(UIPinchGestureRecognizer *)gesture;
//- (void)personalRollGestureScale:(UIPinchGestureRecognizer *)gesture;
//- (void)streamGestureScale:(UIPinchGestureRecognizer *)gesture;

- (void)scrollCollectionViewToPage:(int)page animated:(BOOL)animated;


/// Authentication Methods
- (void)loginAction;
- (void)logoutAction;

/// Video Player Launch Methods
- (void)launchPlayer:(GroupType)groupType fromCell:(UICollectionViewCell *)cell;
- (void)presentViewController:(GAITrackedViewController *)viewControllerToPresent fromCell:(UICollectionViewCell *)cell;

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

    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarStyleBlackTranslucent];
    
    [self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"background"]]];
    
    [self setTrackedViewName:@"Browse"];
    
    [self resetVersionLabel];
    
    [self setIsLoggedIn:[[NSUserDefaults standardUserDefaults] boolForKey:kShelbyDefaultUserAuthorized]];
    
    [self fetchUserNickname];
    
    [self setCategories:[@[] mutableCopy]];
    [self setCategoriesData:[@[] mutableCopy]];
    
    [self setSecretMode:SecretMode_None];
    
    // Register Cell Nibs
    UINib *cellNib = [UINib nibWithNibName:@"SPVideoItemViewCell" bundle:nil];
    [self.collectionView registerNib:cellNib forCellWithReuseIdentifier:@"SPVideoItemViewCell"];
    
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
    
    for (id category in self.categories) {
        NSMutableArray *frames = nil;
        if ([category isKindOfClass:[Channel class]]) {
            frames = [datautility fetchFramesInCategoryChannel:[((Channel *)category) channelID]];
        } else if ([category isKindOfClass:[Roll class]]) {
            frames = [datautility fetchFramesInCategoryRoll:[((Roll *)category) rollID]];
        } else {
            frames = [@[] mutableCopy];
        }
        
        [self.categoriesData addObject:frames];
    }

    [self.collectionView reloadData];
}

- (void)scrollCollectionViewToPage:(int)page animated:(BOOL)animated
{    
    [self.collectionView setContentOffset:[((CollectionViewGroupsLayout *)self.collectionView.collectionViewLayout) pointAtPage:page] animated:animated];
}

- (void)resetVersionLabel
{
    [self.versionLabel setFont:[UIFont fontWithName:@"Ubuntu-Bold" size:_versionLabel.font.pointSize]];
    [self.versionLabel setText:[NSString stringWithFormat:@"Shelby.tv for iPad v%@", kShelbyCurrentVersion]];
    [self.versionLabel setTextColor:kShelbyColorBlack];
}

// TODO: factor the data source delegete methods to a model class.
#pragma mark - UICollectionView Datasource
- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section
{
    NSMutableArray *frames = self.categoriesData[section];
    if (frames) {
        return [frames count];
    }
    
    return 0;
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView
{
    if (self.categories) {
        return [self.categories count];
    }
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    SPVideoItemViewCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"SPVideoItemViewCell" forIndexPath:indexPath];
    
    NSMutableArray *frames = self.categoriesData[indexPath.section];
    Frame *frame = frames[indexPath.row];
    
    NSManagedObjectContext *context = [self context];
    NSManagedObjectID *objectID = [frame objectID];
    if (objectID) {
        Frame *videoFrame = (Frame *)[context existingObjectWithID:objectID error:nil];
        if (videoFrame) {
            Video *video = [frame video]; // KP KP: TODO: need to fetch video if fault.
            [[cell caption] setText:[video caption]];
        }
    }
//    DLog(@"%@", frame.video.caption);
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
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
    
    id category = (id)[self.categories objectAtIndex:indexPath.section];
    if ([category isMemberOfClass:[Channel class]]) { // Category is a Channel
        [self launchPlayer:GroupType_CategoryChannel fromCell:cell];
    } else if ( [category isMemberOfClass:[Roll class]] ) { // Cateogory is a Roll
        [self launchPlayer:GroupType_CategoryRoll fromCell:cell];
    }
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
- (void)launchPlayer:(GroupType)groupType fromCell:(UICollectionViewCell *)cell
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        if ( ![self videoReel] ) {
            self.videoReel = [[SPVideoReel alloc] init];
        }
        
        CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
        NSMutableArray *videoFrames = nil;
        NSString *errorMessage = nil;
        NSString *title = nil;

        NSManagedObjectContext *context = [self context];
        NSInteger categoryIndex = [self.collectionView indexPathForCell:cell].section;
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
                [self presentViewController:[self videoReel] fromCell:cell];
                NSManagedObjectContext *mainThreadContext = [self context];
                if (groupType == GroupType_CategoryChannel) { // Category Channel
                    NSInteger categoryIndex = [self.collectionView indexPathForCell:cell].section;
                    NSManagedObjectID *objectID = [(self.categories)[categoryIndex] objectID];
                    Channel *channel = (Channel *)[mainThreadContext existingObjectWithID:objectID error:nil];
                    [self.videoReel loadWithGroupType:groupType groupTitle:title videoFrames:videoFrames andCategoryID:channel.channelID];
                } else if (groupType == GroupType_CategoryRoll) { // Category Roll
                    NSInteger categoryIndex = [self.collectionView indexPathForCell:cell].section;
                    NSManagedObjectID *objectID = [(self.categories)[categoryIndex] objectID];
                    Roll *roll = (Roll *)[mainThreadContext existingObjectWithID:objectID error:nil];
                    [self.videoReel loadWithGroupType:groupType groupTitle:title videoFrames:videoFrames andCategoryID:roll.rollID];
                }
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

- (void)presentViewController:(GAITrackedViewController *)viewControllerToPresent fromCell:(UICollectionViewCell *)cell
{
    UIImage *screenShot = [ImageUtilities screenshot:self.view];
    UIImageView *srcImage = [[UIImageView alloc] initWithImage:screenShot];
    UIImage *cellScreenShot = [ImageUtilities screenshot:cell];
    UIImageView *cellSrcImage = [[UIImageView alloc] initWithImage:cellScreenShot];
    [cellSrcImage setFrame:CGRectMake((int)cell.frame.origin.x % (int)self.collectionView.frame.size.width, 20 + (int)cell.frame.origin.y % (int)self.collectionView.frame.size.height, cell.frame.size.width, cell.frame.size.height)];
    [srcImage setFrame:CGRectMake(0, 20, viewControllerToPresent.view.frame.size.width, viewControllerToPresent.view.frame.size.height - 20)];
    [cellSrcImage.layer setCornerRadius:20];
    [cellSrcImage.layer setMasksToBounds:YES];
    [viewControllerToPresent.view addSubview:srcImage];
    [viewControllerToPresent.view addSubview:cellSrcImage];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarStyleBlackTranslucent];
    
    [self presentViewController:viewControllerToPresent animated:NO completion:^{
        [srcImage removeFromSuperview];
        [cellSrcImage removeFromSuperview];
    }];
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
        [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
    }
}

#pragma mark - AuthorizationDelegate Methods
- (void)authorizationDidComplete
{
    [self setIsLoggedIn:YES];
    [self fetchUserNickname];
    [self fetchAllCategories];
    [self.collectionView reloadData];
}


@end