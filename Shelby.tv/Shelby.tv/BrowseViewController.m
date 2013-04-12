//
//  BrowseViewController.m
//  Shelby.tv
//
//  Created by Keren on 2/13/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import "BrowseViewController.h"

// Views
#import "GroupViewCell.h"
#import "CollectionViewGroupsLayout.h"
#import "LoginView.h"
#import "SignupView.h"
#import "PersonalRollViewCell.h"
#import "PageControl.h"

// View Controllers
#import "SPVideoReel.h"

// Utilities
#import "ImageUtilities.h"

@interface BrowseViewController ()

@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet PageControl *pageControl;

@property (strong, nonatomic) NSString *userNickname;
@property (assign, nonatomic) BOOL isLoggedIn;

@property (nonatomic) LoginView *loginView;
@property (nonatomic) SignupView *signupView;
@property (nonatomic) UIView *backgroundLoginView;

@property (nonatomic) NSMutableArray *categories; // TODO: to move to a collection view data file

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

/// Page Control
- (IBAction)goToPage:(id)sender;

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
    
    [self setSecretMode:SecretMode_None];
    
    // Register Cell Nibs
    UINib *cellNib = [UINib nibWithNibName:@"GroupViewCell" bundle:nil];
    [self.collectionView registerNib:cellNib forCellWithReuseIdentifier:@"GroupViewCell"];
    cellNib = [UINib nibWithNibName:@"PersonalRollViewCell" bundle:nil];
    [self.collectionView registerNib:cellNib forCellWithReuseIdentifier:@"PersonalRollViewCell"];
    
    [self.pageControl setNumberOfPages:1];

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

#pragma mark - Public Methods
- (void)resetView
{
    NSUInteger displayPage = ([self isLoggedIn] ? 0 : 1);
    [self.pageControl setCurrentPage:displayPage];
    [self scrollCollectionViewToPage:displayPage animated:YES];
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
    
    [self.collectionView reloadData];

    NSUInteger pages = [(CollectionViewGroupsLayout *)self.collectionView.collectionViewLayout numberOfPages];
    [self.pageControl setNumberOfPages:pages];
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

#pragma mark - PageControl Methods
- (IBAction)goToPage:(id)sender
{
    NSInteger page = self.pageControl.currentPage;
    
    // Next line is necessary, otherwise, the custom page control images won't update
    [self.pageControl setCurrentPage:page];
    
    [self scrollCollectionViewToPage:page animated:YES];
}

// TODO: factor the data source delegete methods to a model class.
#pragma mark - UICollectionView Datasource
- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section
{
    return ( 0 == section ) ? kShelbyCollectionViewNumberOfCardsInGroupSectionPage : [self.categories count];
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView
{
    return 2;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    // My Roll Card
    if (indexPath.section == 0 && indexPath.row == 2) {
        PersonalRollViewCell *cell = (PersonalRollViewCell *)[cv dequeueReusableCellWithReuseIdentifier:@"PersonalRollViewCell" forIndexPath:indexPath];
        NSString *myTv = nil;
        if ([self isLoggedIn]) {
            myTv = [NSString stringWithFormat:@"%@.shelby.tv", self.userNickname];
        } else {
            myTv = @"Your personalized .TV";
        }
        
        [cell.personalRollUsernameLabel setText:myTv];
        [cell enableCard:[self isLoggedIn]];
        return cell;
    }
    
    GroupViewCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"GroupViewCell" forIndexPath:indexPath];
    NSString *title = nil;
    NSString *description = nil;
    NSString *buttonImageName = nil;
    NSUInteger row = indexPath.row;
    
    if (indexPath.section == 0) { // Me Cards
       
        [cell enableCard:[self isLoggedIn]];

        if (row == 0) {
        
            title = @"Stream";
            description = @"Watch videos from the people in your Shelby, Facebook, and Twitter networks";
            buttonImageName = @"streamCard";
        
        } else if (row == 2) {
            
            // Do nothing
        
        } else if (row == 1) {
    
            [cell enableCard:YES];
            
            title = @"Likes";
            description = @"Add videos to your likes so you can come back to them and watch them in Shelby at a later time.";
            buttonImageName = @"likesCard";
        
        } else if (row == 3) {
            
            [cell enableCard:YES];
        
            title = ([self isLoggedIn]) ? @"Logout" : @"Login";
            description = @"Ain't nothin' but a gangsta party!";
            buttonImageName = @"loginCard";
        }
        
        UIImage *buttonImage = [UIImage imageNamed:buttonImageName];
        [cell.groupThumbnailImage setImage:buttonImage];
        
    } else {  // Channel Cards
        
        [cell enableCard:YES];
        
        if (indexPath.row < [self.categories count]) {
            
            buttonImageName = @"missingCard";
            NSManagedObjectContext *context = [self context];
            NSManagedObjectID *objectID = [(self.categories)[indexPath.row] objectID];
            Channel *channel = (Channel *)[context existingObjectWithID:objectID error:nil];
            
            // TODO: Channel should NOT be nil!
            if (channel) {
                title = [channel displayTitle];
                description = [channel displayDescription];
                NSString *thumbnailUrl = [channel displayThumbnailURL];
 
                [AsynchronousFreeloader loadImageFromLink:thumbnailUrl
                                             forImageView:[cell groupThumbnailImage]
                                      withPlaceholder:[UIImage imageNamed:buttonImageName]
                                           andContentMode:UIViewContentModeScaleAspectFill];
                
            
            } else {
                UIImage *buttonImage = [UIImage imageNamed:buttonImageName];
                [cell.groupThumbnailImage setImage:buttonImage];
            }
        }
    }
    
    if (!title) {
        title = @"";
    }
    
    if (!description) {
        description = @"";
    }
 
    [cell.groupTitle setText:title];
    [cell.groupDescription setText:description];
    
    return cell;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    GroupViewCell  *cell = (GroupViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    [cell.selectionView setHidden:NO];
}

- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    GroupViewCell  *cell = (GroupViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    [cell.selectionView setHidden:YES];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger row = [indexPath row];
    
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
    
    if ( 0 == indexPath.section ) { // ME Section
        
        switch ( row ) { // Likes
                
            case 0: {
                
                if ( [self isLoggedIn] ) {
                    
                    [self launchPlayer:GroupType_Stream fromCell:cell];
                    
                }
                
            } break;
                
            case 1: { // Stream
                
                [self launchPlayer:GroupType_Likes fromCell:cell];
                
            } break;
                
            case 2: { // Personal Roll
                
                if ( [self isLoggedIn] ) {
                    
                    [self launchPlayer:GroupType_PersonalRoll fromCell:cell];
                    
                }
                
            } break;
                
            case 3: { // Authentication State
                
                ( [self isLoggedIn] ) ? [self logoutAction] : [self loginAction];
                
            } break;
                
            default:
                break;
        }
        
    } else { // Channels Section
        
        id category = (id)[self.categories objectAtIndex:[indexPath row]];
        
        if ( [category isMemberOfClass:[Channel class]] ) { // Category is a Channel
            
            [self launchPlayer:GroupType_CategoryChannel fromCell:cell];
            
        } else if ( [category isMemberOfClass:[Roll class]] ) { // Cateogory is a Roll
            
            [self launchPlayer:GroupType_CategoryRoll fromCell:cell];
            
        }
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

        switch ( groupType ) {
                
            case GroupType_Likes: {
                
                videoFrames = [dataUtility fetchLikesEntries];
                errorMessage = @"No videos in Likes.";
                title = @"Likes";
                
            } break;
                
            case GroupType_PersonalRoll: {
               
                videoFrames = [dataUtility fetchPersonalRollEntries];
                errorMessage = @"No videos in Personal Roll.";
                title = @"Personal Roll";
               
            } break;
                
            case GroupType_Stream: {
                
                videoFrames = [dataUtility fetchStreamEntries];
                // TODO: change this error message before App Store release
                errorMessage = @"Thanks for testing! Please go to http://shelby.tv on a desktop web browser to set up your stream.";
                title = @"Stream";
                
            } break;
                
            case GroupType_CategoryChannel: {
                
                NSManagedObjectContext *context = [self context];
                NSInteger categoryIndex = [self.collectionView indexPathForCell:cell].row;
                NSManagedObjectID *objectID = [(self.categories)[categoryIndex] objectID];
                Channel *channel = (Channel *)[context existingObjectWithID:objectID error:nil];
                videoFrames = [dataUtility fetchFramesInCategoryChannel:[channel channelID]];
                errorMessage = @"No videos in Category Channel.";
                title = [channel displayTitle];
                
            } break;
                
            case GroupType_CategoryRoll: {
                
                NSManagedObjectContext *context = [self context];
                NSInteger categoryIndex = [self.collectionView indexPathForCell:cell].row;
                NSManagedObjectID *objectID = [(self.categories)[categoryIndex] objectID];
                Roll *roll = (Roll *)[context existingObjectWithID:objectID error:nil];
                videoFrames = [dataUtility fetchFramesInCategoryRoll:[roll rollID]];
                errorMessage = @"No videos in Category Roll.";
                title = [roll displayTitle];
                
            } break;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if ( [videoFrames count] ) {
            
                [self presentViewController:[self videoReel] fromCell:cell];
                
                NSManagedObjectContext *mainThreadContext = [self context];
                
                if ( groupType == GroupType_CategoryChannel ) { // Category Channel
                    
                    NSInteger categoryIndex = [self.collectionView indexPathForCell:cell].row;
                    NSManagedObjectID *objectID = [(self.categories)[categoryIndex] objectID];
                    Channel *channel = (Channel *)[mainThreadContext existingObjectWithID:objectID error:nil];
                    [self.videoReel loadWithGroupType:groupType groupTitle:title videoFrames:videoFrames andCategoryID:channel.channelID];
                    
                } else if ( groupType == GroupType_CategoryRoll ) { // Category Roll
                    
                    NSInteger categoryIndex = [self.collectionView indexPathForCell:cell].row;
                    NSManagedObjectID *objectID = [(self.categories)[categoryIndex] objectID];
                    Roll *roll = (Roll *)[mainThreadContext existingObjectWithID:objectID error:nil];
                    [self.videoReel loadWithGroupType:groupType groupTitle:title videoFrames:videoFrames andCategoryID:roll.rollID];
                    
                } else { // Stream, Likes, Personal Roll

                    [self.videoReel loadWithGroupType:groupType groupTitle:title andVideoFrames:videoFrames];
                    
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

#pragma mark UIScrollViewDelegate Methods
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    NSArray *visibleCells = [self.collectionView visibleCells];
    if ([visibleCells count] > 0) {
        NSIndexPath *firstCell = [self.collectionView indexPathForCell:visibleCells[0]];
        int numberOfCardsInSectionPage = (firstCell.section == 0 ? kShelbyCollectionViewNumberOfCardsInMeSectionPage : kShelbyCollectionViewNumberOfCardsInGroupSectionPage);
        int page = (firstCell.row / numberOfCardsInSectionPage) + firstCell.section;
        [self.pageControl setCurrentPage:page];
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