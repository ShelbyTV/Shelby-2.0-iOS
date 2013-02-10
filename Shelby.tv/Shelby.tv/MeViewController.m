//
//  MeViewController.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 10/17/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import "MeViewController.h"
#import "LoginView.h"
#import "SPVideoReel.h"

@interface MeViewController ()

@property (nonatomic) LoginView *loginView;
@property (nonatomic) UIView *backgroundLoginView;

/// Video Player Launch Methods
- (void)launchPlayerWithStreamEntries;
- (void)launchPlayerWithLikesRollEntries;
- (void)launchPlayerWithPersonalRollEntries;

/// Authentication Methods
- (void)authenticationButtonAction;
- (void)loginAction;
- (void)logoutAction;
- (void)userAuthenticationDidSucceed:(NSNotification*)notification;

/// UI Methods
- (void)enableCards;
- (void)disableCards;

@end

@implementation MeViewController

#pragma mark - Memory Management Methods
- (void)dealloc
{
    self.likesButton = nil;
    self.likesTitleLabel = nil;
    self.likesDescriptionLabel = nil;
    
    self.personalRollButton = nil;
    self.personalRollDescriptionLabel = nil;
    self.personalRollTitleLabel = nil;
    self.personalRollUsernameLabel = nil;
    self.streamButton = nil;
    self.streamTitleLabel = nil;
    self.streamDescriptionLabel = nil;
//    self.logoutButton = nil;
    self.versionLabel = nil;
}

#pragma mark - View Lifecycle Methods
- (void)viewDidLoad
{
    
    [super viewDidLoad];
 
    // Labels
    [self.likesTitleLabel setFont:[UIFont fontWithName:@"Ubuntu-Bold" size:_likesTitleLabel.font.pointSize]];
    [self.likesTitleLabel setTextColor:kColorBlack];
    [self.likesDescriptionLabel setFont:[UIFont fontWithName:@"Ubuntu" size:_likesDescriptionLabel.font.pointSize]];
    [self.likesDescriptionLabel setTextColor:kColorBlack];
    
    [self.personalRollTitleLabel setFont:[UIFont fontWithName:@"Ubuntu-Bold" size:_personalRollTitleLabel.font.pointSize]];
    [self.personalRollTitleLabel setTextColor:kColorBlack];
    [self.personalRollDescriptionLabel setFont:[UIFont fontWithName:@"Ubuntu" size:_personalRollDescriptionLabel.font.pointSize]];
    [self.personalRollDescriptionLabel setTextColor:kColorBlack];
    [self.personalRollUsernameLabel setFont:[UIFont fontWithName:@"Ubuntu-Bold" size:_personalRollUsernameLabel.font.pointSize]];
    [self.personalRollUsernameLabel setTextColor:[UIColor colorWithHex:@"fff" andAlpha:1.0f]];
    
    [self.streamTitleLabel setFont:[UIFont fontWithName:@"Ubuntu-Bold" size:_streamTitleLabel.font.pointSize]];
    [self.streamTitleLabel setTextColor:kColorBlack];
    [self.streamDescriptionLabel setFont:[UIFont fontWithName:@"Ubuntu" size:_streamDescriptionLabel.font.pointSize]];
    [self.streamDescriptionLabel setTextColor:kColorBlack];
    
    [self.versionLabel setFont:[UIFont fontWithName:@"Ubuntu-Bold" size:_versionLabel.font.pointSize]];
    [self.versionLabel setText:[NSString stringWithFormat:@"Shelby.tv for iPad v%@", kCurrentVersion]];
    [self.versionLabel setTextColor:kColorBlack];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    
    [super viewWillAppear:animated];
    
    // Toggle card UI depending on if user is logged-in or logged-out
    ( [[NSUserDefaults standardUserDefaults] valueForKey:kDefaultUserAuthorized] ) ? [self enableCards] : [self disableCards];
 
    if ( [[UIApplication sharedApplication] isStatusBarHidden] ) {
        
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarStyleBlackTranslucent];
        [self.view setFrame:CGRectMake(0.0f, 0.0f, 1024.0f, 748.0f)];
    
    }

}

#pragma mark - Action Buttons (Public)
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
                         [self.personalRollButton setEnabled:YES];

                     }];

}

- (void)goButtonAction:(id)sender
{
    [self loginAction];
}

#pragma mark - Video Player Launch Methods (Private)
- (void)launchPlayerWithStreamEntries
{
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    NSMutableArray *videoFrames = [dataUtility fetchStreamEntries];

    if ( [videoFrames count] ) {
        
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarStyleBlackTranslucent];
        SPVideoReel *reel = [[SPVideoReel alloc] initWithCategoryType:CategoryType_Stream categoryTitle:@"Stream" andVideoFrames:videoFrames];
        [self presentViewController:reel animated:YES completion:nil];
        
    } else {
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:@"No videos in Stream."
                                                           delegate:self
                                                  cancelButtonTitle:@"Dismiss"
                                                  otherButtonTitles:nil];
        
        [alertView show];
        
    }
    
}

- (void)launchPlayerWithLikesRollEntries
{
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    NSMutableArray *videoFrames = [dataUtility fetchLikesEntries];
    
    if ( [videoFrames count] ) {
        
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarStyleBlackTranslucent];
        SPVideoReel *reel = [[SPVideoReel alloc] initWithCategoryType:CategoryType_Likes categoryTitle:@"Likes" andVideoFrames:videoFrames];
        [self presentViewController:reel animated:YES completion:nil];
        
    } else {
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:@"No videos in Likes."
                                                           delegate:self
                                                  cancelButtonTitle:@"Dismiss"
                                                  otherButtonTitles:nil];
        
        [alertView show];
        
    }

}

- (void)launchPlayerWithPersonalRollEntries
{
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    NSMutableArray *videoFrames = [dataUtility fetchPersonalRollEntries];
    
    if ( [videoFrames count] ) {
        
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarStyleBlackTranslucent];
        SPVideoReel *reel = [[SPVideoReel alloc] initWithCategoryType:CategoryType_PersonalRoll categoryTitle:@"Personal Roll" andVideoFrames:videoFrames];
        [self presentViewController:reel animated:YES completion:nil];
        
    } else {
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:@"No videos in Personal Roll."
                                                           delegate:self
                                                  cancelButtonTitle:@"Dismiss"
                                                  otherButtonTitles:nil];
        
        [alertView show];
        
    }
    
}

#pragma mark - User Authentication Methods (Private)
- (void)authenticationButtonAction
{
    
    self.backgroundLoginView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 1024.0f, 748.0f)];
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
                         
                         [self.backgroundLoginView setAlpha:0.5f];
                         [self.loginView setFrame:CGRectMake(xOrigin,
                                                             yOrigin,
                                                             _loginView.frame.size.width,
                                                             _loginView.frame.size.height)];
                         
                     } completion:^(BOOL finished) {
                         
//                         [self.personalRollButton setEnabled:NO];
                         
                         [self.loginView.emailField becomeFirstResponder];
                     
                     }];
    
}

- (void)loginAction
{
    
    // Hide Keyboard
    [self.view endEditing:YES];
    
    if ( ![_loginView.emailField.text length] || ![_loginView.passwordField.text length] ) {
    
        // Do nothing if at least one text field is empty
        
    } else {
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(userAuthenticationDidSucceed:)
                                                     name:kNotificationUserAuthenticationDidSucceed object:nil];
        
        [self.loginView.cancelButton setEnabled:NO];
        [self.loginView.goButton setEnabled:NO];
        [self.loginView.emailField setEnabled:NO];
        [self.loginView.passwordField setEnabled:NO];
        
        [self.loginView.indicator setHidden:NO];
        [self.loginView.indicator startAnimating];
        
        [ShelbyAPIClient postAuthenticationWithEmail:[_loginView.emailField.text lowercaseString] andPassword:_loginView.passwordField.text withIndicator:_loginView.indicator];
        
    }
}

- (void)logoutAction
{
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [appDelegate logout];
}


- (void)userAuthenticationDidSucceed:(NSNotification*)notification
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
                         
                         [self enableCards];
                         
                     }];
}

#pragma mark - UI Methods (Private)
- (void)enableCards
{
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    User *user = [dataUtility fetchUser];
    
    [self.personalRollButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    [self.personalRollButton addTarget:self action:@selector(launchPlayerWithPersonalRollEntries) forControlEvents:UIControlEventTouchUpInside];
    [self.personalRollUsernameLabel setText:[NSString stringWithFormat:@"%@.shelby.tv", user.nickname]];
    [self.personalRollButton setEnabled:YES];
    
    [self.likesButton addTarget:self action:@selector(launchPlayerWithLikesRollEntries) forControlEvents:UIControlEventTouchUpInside];
    [self.likesButton setEnabled:YES];
    [self.likesTitleLabel setEnabled:YES];
    [self.likesDescriptionLabel setEnabled:YES];
    
    [self.streamButton addTarget:self action:@selector(launchPlayerWithStreamEntries) forControlEvents:UIControlEventTouchUpInside];
    [self.streamButton setEnabled:YES];
    [self.streamTitleLabel setEnabled:YES];
    [self.streamDescriptionLabel setEnabled:YES];
    
    
}

- (void)disableCards
{
    [self.personalRollButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    [self.personalRollButton addTarget:self action:@selector(authenticationButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [self.personalRollUsernameLabel setText:@"Login to view your .TV"];
    
    [self.likesButton setEnabled:NO];
    [self.likesTitleLabel setEnabled:NO];
    [self.likesDescriptionLabel setEnabled:NO];
    
    [self.streamButton setEnabled:NO];
    [self.streamTitleLabel setEnabled:NO];
    [self.streamDescriptionLabel setEnabled:NO];
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
    if ( textField == self.loginView.emailField ) {
        [self.loginView.passwordField becomeFirstResponder];
        return NO;
    } else {
        [self loginAction];
        return YES;
    }
}

@end
