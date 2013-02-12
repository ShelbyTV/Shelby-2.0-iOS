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

@property (weak, nonatomic) IBOutlet UIButton *likesButton;
@property (weak, nonatomic) IBOutlet UILabel *likesTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *likesDescriptionLabel;

@property (weak, nonatomic) IBOutlet UIButton *personalRollButton;
@property (weak, nonatomic) IBOutlet UILabel *personalRollTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *personalRollDescriptionLabel;
@property (nonatomic) UILabel *personalRollUsernameLabel;

@property (weak, nonatomic) IBOutlet UIButton *streamButton;
@property (weak, nonatomic) IBOutlet UILabel *streamTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *streamDescriptionLabel;

@property (weak, nonatomic) IBOutlet UIButton *authenticationButton;
@property (weak, nonatomic) IBOutlet UILabel *authenticationTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *authenticationDescriptionLabel;

@property (weak, nonatomic) IBOutlet UILabel *versionLabel;

/// UI Methods
- (void)setupCards;
- (void)toggleCardsEnabled:(BOOL)enabled;
- (void)enableCards;
- (void)disableCards;

/// Navigation Action Methods
- (IBAction)cancelButtonAction:(id)sender;
- (IBAction)goButtonAction:(id)sender;

/// Authentication Methods
- (void)loginButtonAction;
- (void)logoutButtonAction;
- (void)performAuthentication;
- (void)userAuthenticationDidSucceed:(NSNotification*)notification;

/// Video Player Launch Methods
- (void)launchPlayerWithStreamEntries;
- (void)launchPlayerWithLikesRollEntries;
- (void)launchPlayerWithPersonalRollEntries;


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
    
    self.authenticationButton = nil;
    self.authenticationTitleLabel = nil;
    self.authenticationDescriptionLabel = nil;
    
    self.versionLabel = nil;
}

#pragma mark - View Lifecycle Methods
- (void)viewDidLoad
{
    
    [super viewDidLoad];
    
    [self setupCards];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    
    [super viewWillAppear:animated];
    
    // Toggle card UI depending on if user is logged-in or logged-out
    ( [[NSUserDefaults standardUserDefaults] valueForKey:kDefaultUserAuthorized] ) ? [self toggleCardsEnabled:YES] : [self toggleCardsEnabled:NO];
    
    // If viewWillAppear is called when SPVideoReel modalVC is removed...
    if ( [[UIApplication sharedApplication] isStatusBarHidden] ) {
        
        // ... re-display status bar
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarStyleBlackTranslucent];
        
        // ... and reset the view's frame
        [self.view setFrame:CGRectMake(0.0f, 0.0f, 1024.0f, 748.0f)];
    
    }

}

#pragma mark - UI Methods (Private)
- (void)setupCards
{
    
    // Labels
    [self.likesTitleLabel setFont:[UIFont fontWithName:@"Ubuntu-Bold" size:_likesTitleLabel.font.pointSize]];
    [self.likesTitleLabel setTextColor:kColorBlack];
    [self.likesDescriptionLabel setFont:[UIFont fontWithName:@"Ubuntu" size:_likesDescriptionLabel.font.pointSize]];
    [self.likesDescriptionLabel setTextColor:kColorBlack];
    
    [self.personalRollTitleLabel setFont:[UIFont fontWithName:@"Ubuntu-Bold" size:_personalRollTitleLabel.font.pointSize]];
    [self.personalRollTitleLabel setTextColor:kColorBlack];
    [self.personalRollDescriptionLabel setFont:[UIFont fontWithName:@"Ubuntu" size:_personalRollDescriptionLabel.font.pointSize]];
    [self.personalRollDescriptionLabel setTextColor:kColorBlack];
    
    self.personalRollUsernameLabel = [[UILabel alloc] initWithFrame:CGRectMake(688.0f, 130.0f, 278, 52.0f)];
    self.personalRollUsernameLabel.text = @"Login to your .TV";
    [self.personalRollUsernameLabel setBackgroundColor:[UIColor clearColor]];
    [self.view addSubview:_personalRollUsernameLabel];
    [self.personalRollUsernameLabel setFont:[UIFont fontWithName:@"Ubuntu-Bold" size:_personalRollUsernameLabel.font.pointSize]];
    [self.personalRollUsernameLabel setTextColor:[UIColor colorWithHex:@"ffffff" andAlpha:1.0f]];
    
    [self.streamTitleLabel setFont:[UIFont fontWithName:@"Ubuntu-Bold" size:_streamTitleLabel.font.pointSize]];
    [self.streamTitleLabel setTextColor:kColorBlack];
    [self.streamDescriptionLabel setFont:[UIFont fontWithName:@"Ubuntu" size:_streamDescriptionLabel.font.pointSize]];
    [self.streamDescriptionLabel setTextColor:kColorBlack];
    
    [self.authenticationTitleLabel setFont:[UIFont fontWithName:@"Ubuntu-Bold" size:_authenticationTitleLabel.font.pointSize]];
    [self.authenticationTitleLabel setTextColor:kColorBlack];
    [self.authenticationDescriptionLabel setFont:[UIFont fontWithName:@"Ubuntu" size:_authenticationDescriptionLabel.font.pointSize]];
    [self.authenticationDescriptionLabel setTextColor:kColorBlack];
    
    [self.versionLabel setFont:[UIFont fontWithName:@"Ubuntu-Bold" size:_versionLabel.font.pointSize]];
    [self.versionLabel setText:[NSString stringWithFormat:@"Shelby.tv for iPad v%@", kCurrentVersion]];
    [self.versionLabel setTextColor:kColorBlack];
    
    // Actions
    [self.likesButton addTarget:self action:@selector(launchPlayerWithLikesRollEntries) forControlEvents:UIControlEventTouchUpInside];
    [self.personalRollButton addTarget:self action:@selector(launchPlayerWithPersonalRollEntries) forControlEvents:UIControlEventTouchUpInside];
    [self.streamButton addTarget:self action:@selector(launchPlayerWithStreamEntries) forControlEvents:UIControlEventTouchUpInside];
}

- (void)toggleCardsEnabled:(BOOL)enable
{
    
    [self.authenticationButton addTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    
    if ( enable ) {
        
        [self enableCards];
        [self.authenticationButton addTarget:self action:@selector(logoutButtonAction) forControlEvents:UIControlEventTouchUpInside];
        
    } else {
        
        [self disableCards];
        [self.authenticationButton addTarget:self action:@selector(loginButtonAction) forControlEvents:UIControlEventTouchUpInside];
        
    }
    
}

- (void)enableCards
{
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    User *user = [dataUtility fetchUser];
    
    [self.likesButton setEnabled:YES];
    [self.likesTitleLabel setEnabled:YES];
    [self.likesDescriptionLabel setEnabled:YES];

    [self.personalRollButton setEnabled:YES];
    [self.personalRollUsernameLabel setEnabled:YES];
    [self.personalRollUsernameLabel setText:[NSString stringWithFormat:@"%@.shelby.tv", user.nickname]];
    
    [self.streamButton setEnabled:YES];
    [self.streamTitleLabel setEnabled:YES];
    [self.streamDescriptionLabel setEnabled:YES];
    
    [self.authenticationTitleLabel setText:@"Logout"];
    
}

- (void)disableCards
{
    
    [self.likesButton setEnabled:NO];
    [self.likesTitleLabel setEnabled:NO];
    [self.likesDescriptionLabel setEnabled:NO];
    
    [self.personalRollButton setEnabled:NO];
    [self.personalRollTitleLabel setEnabled:NO];
    [self.personalRollDescriptionLabel setEnabled:NO];
    [self.personalRollUsernameLabel setEnabled:NO];
    [self.personalRollUsernameLabel setText:@"Login to your .TV"];
    
    [self.streamButton setEnabled:NO];
    [self.streamTitleLabel setEnabled:NO];
    [self.streamDescriptionLabel setEnabled:NO];
    
    [self.authenticationTitleLabel setText:@"Login"];
    
}

#pragma mark - Navigation Action Buttons (Public)
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

#pragma mark - User Authentication Methods (Private)
- (void)loginButtonAction
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
                         
                         [self.loginView.emailField becomeFirstResponder];
                         
                     }];
    
}

- (void)logoutButtonAction
{
    [self toggleCardsEnabled:NO];
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [appDelegate logout];
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
                                                     name:kNotificationUserAuthenticationDidSucceed object:nil];
        
        [self.loginView.cancelButton setEnabled:NO];
        [self.loginView.goButton setEnabled:NO];
        [self.loginView.emailField setEnabled:NO];
        [self.loginView.passwordField setEnabled:NO];
        
        [self.loginView.indicator setHidden:NO];
        [self.loginView.indicator startAnimating];
        
        [ShelbyAPIClient postAuthenticationWithEmail:[_loginView.emailField.text lowercaseString] andPassword:_loginView.passwordField.text withLoginView:_loginView];
        
    }
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
                         
                         [self toggleCardsEnabled:YES];
                         
                     }];
}

#pragma mark - Video Player Launch Methods (Private)
- (void)launchPlayerWithStreamEntries
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
        NSMutableArray *videoFrames = [dataUtility fetchStreamEntries];

        dispatch_async(dispatch_get_main_queue(), ^{
            
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
            
        });
        
    });
    
}

- (void)launchPlayerWithLikesRollEntries
{
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
        CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
        NSMutableArray *videoFrames = [dataUtility fetchLikesEntries];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
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

        });
        
    });
}

- (void)launchPlayerWithPersonalRollEntries
{

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
        CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
        NSMutableArray *videoFrames = [dataUtility fetchPersonalRollEntries];
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
        
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

        });
    });
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

@end
