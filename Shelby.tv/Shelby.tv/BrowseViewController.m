//
//  BrowseViewController.m
//  Shelby.tv
//
//  Created by Keren on 2/13/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import "BrowseViewController.h"
#import "ChannelViewCell.h"
#import "CollectionViewChannelsLayout.h"
#import "LoginView.h"
#import "MeViewController.h"
#import "MyRollViewCell.h"
#import "PageControl.h"
#import "SPVideoReel.h"
#import "ImageUtilities.h"
#import <QuartzCore/QuartzCore.h>

typedef enum {
    PlayerTypeStream,
    PlayerTypeLikes,
    PlayerTypePersonalRoll,
    PlayerTypeChannel
} PlayerType;

@interface BrowseViewController ()

@property (strong, nonatomic) NSString *userNickname;
@property (assign, nonatomic) BOOL isLoggedIn;

@property (nonatomic) LoginView *loginView;
@property (nonatomic) UIView *backgroundLoginView;

@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

// TODO: to move to a collection view data file
@property NSMutableArray *channels;

@property (weak, nonatomic) IBOutlet PageControl *pageControl;
// Fetch nickname of logged in user from CoreData
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

/// Navigation Action Methods
- (IBAction)cancelButtonAction:(id)sender;
- (IBAction)goButtonAction:(id)sender;

/// Authentication Methods
- (void)loginAction;
- (void)logoutAction;
- (void)performAuthentication;
- (void)userAuthenticationDidSucceed:(NSNotification *)notification;

/// Video Player Launch Methods
- (void)launchPlayer:(PlayerType)playerType fromCell:(UICollectionViewCell *)cell;
- (void)presentViewController:(UIViewController *)viewControllerToPresent fromCell:(UICollectionViewCell *)cell;

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
    
    [self setIsLoggedIn:[[NSUserDefaults standardUserDefaults] boolForKey:kShelbyDefaultUserAuthorized]];
    
    [self fetchUserNickname];
    _channels = [[NSMutableArray alloc] init];
    
    // Register Cell Nibs
    UINib *cellNib = [UINib nibWithNibName:@"ChannelViewCell" bundle:nil];
    [self.collectionView registerNib:cellNib forCellWithReuseIdentifier:@"ChannelViewCell"];
    cellNib = [UINib nibWithNibName:@"MyRollViewCell" bundle:nil];
    [self.collectionView registerNib:cellNib forCellWithReuseIdentifier:@"MyRollViewCell"];

    [self.pageControl setNumberOfPages:1];
    [self fetchChannels];
  
    // Customize look
    [self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"background.png"]]];
    
    // Version label
    [self resetVersionLabel];
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarStyleBlackTranslucent];
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
    [self scrollCollectionViewToPage:displayPage animated:NO];
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

- (void)fetchChannels
{
    CoreDataUtility *datautility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    [self.channels removeAllObjects];
    [self.channels addObjectsFromArray:[datautility fetchAllChannels]];
    
    [self.collectionView reloadData];

    NSUInteger pages = [(CollectionViewChannelsLayout *)self.collectionView.collectionViewLayout numberOfPages];
    [self.pageControl setNumberOfPages:pages];
}

- (void)fetchFramesForChannel
{
    
}

- (void)scrollCollectionViewToPage:(int)page animated:(BOOL)animated
{
    NSUInteger width = self.collectionView.frame.size.width;
    NSUInteger x = (width * page);
    NSUInteger y = 0;
    
    [self.collectionView setContentOffset:CGPointMake(x, y) animated:animated];
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
    if (section == 0) {
        return kShelbyCollectionViewNumberOfCardsInMeSectionPage;
    } else {
        return [self.channels count];
    }
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView
{
    return 2;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    // My Roll Card
    if (indexPath.section == 0 && indexPath.row == 2) {
        MyRollViewCell *cell = (MyRollViewCell *)[cv dequeueReusableCellWithReuseIdentifier:@"MyRollViewCell" forIndexPath:indexPath];
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
    
    ChannelViewCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"ChannelViewCell" forIndexPath:indexPath];
    NSString *name = nil;
    NSString *description = nil;
    NSString *buttonImageName = nil;
    int row = indexPath.row;
    
    if (indexPath.section == 0) { // Me Cards
        [cell enableCard:[self isLoggedIn]];

        if (row == 0) {
            name = @"Likes";
            description = @"Add videos to your likes so you can come back to them and watch them in Shelby at a later time.";
            buttonImageName = @"likesCard.png";
        } else if (row == 2) {
        } else if (row == 1) {
            name = @"Stream";
            description = @"Watch videos from the people in your Shelby, Facebook, and Twitter networks";
            buttonImageName = @"streamCard.png";
        } else if (row == 3) {
            [cell enableCard:YES];
            if ([self isLoggedIn]) {
                name = @"Logout";
            } else {
                name = @"Login";
            }
            description = @"Ain't nothin' but a gangsta party!";
            buttonImageName = @"loginCard.png";
        }
        UIImage *buttonImage = [UIImage imageNamed:buttonImageName];
        [cell.channelImage setImage:buttonImage];
    } else {  // Channel Cards
        [cell enableCard:YES];
        if (indexPath.row < [self.channels count]) {
            buttonImageName = @"missingCard.png";
            
            NSManagedObjectContext *context = [self context];
            NSManagedObjectID *objectID = [(self.channels)[indexPath.row] objectID];
            Channel *channel = (Channel *)[context existingObjectWithID:objectID error:nil];
            // TODO: Channel should NOT be nil!
            if (channel) {
                name = [channel displayTitle];
                description = [channel displayDescription];
                NSString *thumbnailUrl = [channel displayThumbnailURL];
              
                [AsynchronousFreeloader loadImageFromLink:thumbnailUrl
                                             forImageView:cell.channelImage
                                      withPlaceholderView:nil
                                           andContentMode:UIViewContentModeScaleAspectFill];
                
            
            } else {
                UIImage *buttonImage = [UIImage imageNamed:buttonImageName];
                [cell.channelImage setImage:buttonImage];
            }
        }
    }
    
    if (!name) {
        name = @"";
    }
    
    if (!description) {
        description = @"";
    }
 
    [cell.channelName setText:name];
    [cell.channelDescription setText:description];
    
    return cell;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    ChannelViewCell  *cell = (ChannelViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    [cell.selectionView setHidden:NO];
}

- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    ChannelViewCell  *cell = (ChannelViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    [cell.selectionView setHidden:YES];
    
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    int row = indexPath.row;
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
    if (indexPath.section == 0) {
        if ([self isLoggedIn]) {
            if (row == 0) {
                [self launchPlayer:PlayerTypeLikes fromCell:cell];
            } else if (row == 2) {
                [self launchPlayer:PlayerTypePersonalRoll fromCell:cell];
            } else if (row == 1) {
                [self launchPlayer:PlayerTypeStream fromCell:cell];
            } else if (row == 3) {
                [self logoutAction];
            }
        } else if (row == 3) {
            [self loginAction];
        }
    } else {
        [self launchPlayer:PlayerTypeChannel fromCell:cell];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    // TODO: Deselect item
}


#pragma mark - Action Methods (Public)
- (void)cancelButtonAction:(id)sender
{
 
    for ( UITextField *textField in [_loginView subviews] ) {
        
        if ( [textField isFirstResponder] ) {
            
            [textField resignFirstResponder];
            
        }
        
    }
    
    [UIView animateWithDuration:0.5
                     animations:^{
                         
                         CGFloat xOrigin = self.view.frame.size.width/2.0f - _loginView.frame.size.width/4.0f;
                         [self.loginView setFrame:CGRectMake(xOrigin,
                                                             self.view.frame.size.height,
                                                             _loginView.frame.size.width,
                                                             _loginView.frame.size.height)];
                         
                         [self.backgroundLoginView setAlpha:0.0f];
                         
                     } completion:^(BOOL finished) {
                         
                         [self.loginView removeFromSuperview];
                         [self.backgroundLoginView removeFromSuperview];
                         
                     }];
    
}

- (void)goButtonAction:(id)sender
{
    [self performAuthentication];
}

- (void)toggleOfflineMode:(id)sender
{
    
    if ( [[NSUserDefaults standardUserDefaults] boolForKey:kShelbyDefaultUserAuthorized] ) {
     
        if ( [[NSUserDefaults standardUserDefaults] boolForKey:kShelbyDefaultOfflineModeEnabled] ) { // If offlineMode enabled, DISABLE it
            
            // Set Defaults
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kShelbyDefaultOfflineModeEnabled];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            // Version label
            [self resetVersionLabel]; 
            
            DLog(@"Offline Mode DISABLED!")
            
        } else { // If offlineMode disabled, ENABLE it
            
            // Set Defaults
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kShelbyDefaultOfflineModeEnabled];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            // Fetch User
            CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
            User *user = [dataUtility fetchUser];
            
            // Version label
            [self.versionLabel setFont:[UIFont fontWithName:@"Ubuntu-Bold" size:_versionLabel.font.pointSize]];
            [self.versionLabel setText:[NSString stringWithFormat:@"Shelby.tv for iPad v%@ (%@)", kShelbyCurrentVersion, user.nickname]];
            [self.versionLabel setTextColor:kShelbyColorBlack];
            
            DLog(@"Offline Mode ENABLED!");
            
        }
    }
}

#pragma mark - User Authentication Methods (Private)
- (void)loginAction
{
    
    self.backgroundLoginView = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.backgroundLoginView setBackgroundColor:[UIColor colorWithHex:@"adadad" andAlpha:1.0f]];
    [self.backgroundLoginView setAlpha:0.0f];
    [self.view addSubview:_backgroundLoginView];
    
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"LoginView" owner:self options:nil];
    self.loginView = nib[0];
    
    CGFloat xOrigin = self.view.frame.size.width/2.0f - _loginView.frame.size.width/4.0f;
    CGFloat yOrigin = self.view.frame.size.height/5.0f - _loginView.frame.size.height/4.0f;
    
    [self.loginView setFrame:CGRectMake(xOrigin,
                                        self.view.frame.size.height,
                                        _loginView.frame.size.width,
                                        _loginView.frame.size.height)];
    [self.view addSubview:_loginView];
    
    [UIView animateWithDuration:0.5f
                     animations:^{
                         
                         [self.backgroundLoginView setAlpha:0.75f];
                         [self.loginView setFrame:CGRectMake(xOrigin,
                                                             yOrigin,
                                                             _loginView.frame.size.width,
                                                             _loginView.frame.size.height)];
                         
                     } completion:^(BOOL finished) {
                         
                         [self.loginView.emailField becomeFirstResponder];
                         
                     }];
    
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

- (void)performAuthentication
{
    
    // Hide Keyboard
    [self.view endEditing:YES];
    
    if ( ![_loginView.emailField.text length] || ![_loginView.passwordField.text length] ) {
        
        // Do nothing if at least one text field is empty
        
    } else {
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(userAuthenticationDidSucceed:)
                                                     name:kShelbyNotificationUserAuthenticationDidSucceed object:nil];
        
        [self.loginView.cancelButton setEnabled:NO];
        [self.loginView.goButton setEnabled:NO];
        [self.loginView.emailField setEnabled:NO];
        [self.loginView.passwordField setEnabled:NO];
        
        [self.loginView.indicator setHidden:NO];
        [self.loginView.indicator startAnimating];
        
        [ShelbyAPIClient postAuthenticationWithEmail:[_loginView.emailField.text lowercaseString] andPassword:_loginView.passwordField.text withLoginView:_loginView];
        
    }
}

- (void)userAuthenticationDidSucceed:(NSNotification *)notification
{
    
    [UIView animateWithDuration:0.5
                     animations:^{
                         
                         CGFloat xOrigin = self.view.frame.size.width/2.0f - _loginView.frame.size.width/4.0f;
                         [self.loginView setFrame:CGRectMake(xOrigin,
                                                             self.view.frame.size.height,
                                                             _loginView.frame.size.width,
                                                             _loginView.frame.size.height)];
                         
                         [self.backgroundLoginView setAlpha:0.0f];
                         
                     } completion:^(BOOL finished) {
                         
                         [self.loginView removeFromSuperview];
                         [self.backgroundLoginView removeFromSuperview];
                         [self setIsLoggedIn:YES];
                         [self fetchUserNickname];
                         [self fetchChannels];
                         [self.collectionView reloadData];
                     }];
}


#pragma mark - Video Player Launch Methods (Private)
- (void)launchPlayer:(PlayerType)playerType fromCell:(UICollectionViewCell *)cell
{
    DataRequestType requestType = DataRequestType_Fetch;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *videoFrames = nil;
        CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:requestType];
        NSString *errorMessage = nil;
        NSString *title = nil;
        CategoryType categoryType;
        Channel *channel = nil;
        switch (playerType) {
            case PlayerTypeChannel:
            {
                
                NSManagedObjectContext *context = [self context];
                NSInteger channelIndex = [self.collectionView indexPathForCell:cell].row;
                NSManagedObjectID *objectID = [(self.channels)[channelIndex] objectID];
                channel = (Channel *)[context existingObjectWithID:objectID error:nil];
                videoFrames = [dataUtility fetchFramesInChannel:channel.channelID];
                errorMessage = @"No videos in Channel.";
                title = [channel displayTitle];
                categoryType = CategoryType_Channel;
                break;
            }
            case PlayerTypePersonalRoll:
            {
                videoFrames = [dataUtility fetchPersonalRollEntries];
                errorMessage = @"No videos in Personal Roll.";
                title = @"Personal Roll";
                categoryType = CategoryType_PersonalRoll;
                break;
            }
            case PlayerTypeLikes:
            {
                videoFrames = [dataUtility fetchLikesEntries];
                errorMessage = @"No videos in Likes.";
                title = @"Likes";
                categoryType = CategoryType_Likes;
                break;
            }
            case PlayerTypeStream:
            {
                videoFrames = [dataUtility fetchStreamEntries];
                errorMessage = @"No videos in Stream.";
                title = @"Stream";
                categoryType = CategoryType_Stream;
                break;
            }
            default: // Should never get here
            {
                videoFrames = [dataUtility fetchStreamEntries];
                errorMessage = @"No videos in Stream.";
                title = @"Stream";
                categoryType = CategoryType_Stream;
                break;
                break;
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if ( [videoFrames count] ) {
                SPVideoReel *reel = nil;
                if (categoryType == PlayerTypeChannel) {
                    reel = [[SPVideoReel alloc] initWithCategoryType:categoryType categoryTitle:title videoFrames:videoFrames andChannelID:[channel channelID]];
                    
                } else {
                    reel = [[SPVideoReel alloc] initWithCategoryType:categoryType categoryTitle:title andVideoFrames:videoFrames];
                }

                [self presentViewController:reel fromCell:cell];
                
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

- (void)presentViewController:(UIViewController *)viewControllerToPresent fromCell:(UICollectionViewCell *)cell
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
    [(SPVideoReel *)viewControllerToPresent setupTransition:srcImage andZoomInScreenshot:cellSrcImage];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarStyleBlackTranslucent];
    
    [self presentViewController:viewControllerToPresent animated:NO completion:nil];
}

#pragma mark - UITextFieldDelegate Methods
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if ( [string isEqualToString:@"\n"] ) {
        
        [textField resignFirstResponder];
        return NO;
        
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if ( textField == _loginView.emailField ) {
        [self.loginView.passwordField becomeFirstResponder];
        return NO;
    } else {
        [self performAuthentication];
        return YES;
    }
}

#pragma mark UIScrollViewDelegate Methods
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    NSArray *visibleCells = [self.collectionView visibleCells];
    if ([visibleCells count] > 0) {
        NSIndexPath *firstCell = [self.collectionView indexPathForCell:visibleCells[0]];
        int numberOfCardsInSectionPage = (firstCell.section == 0 ? kShelbyCollectionViewNumberOfCardsInMeSectionPage : kShelbyCollectionViewNumberOfCardsInChannelSectionPage);
        int page = (firstCell.row / numberOfCardsInSectionPage) + firstCell.section;
        [self.pageControl setCurrentPage:page];
    }
}

#pragma mark - UIAlertViewDelegate Methods
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{

    switch ( buttonIndex ) {
            
      case 0: {

         // Do nothing
         
      } break;
     
        case 1: {
       
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            [appDelegate logout];
            [self setIsLoggedIn:NO];
            [self setUserNickname:nil];
            [self resetVersionLabel];
            [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
        
        } default:
            break;
    }
}

@end
