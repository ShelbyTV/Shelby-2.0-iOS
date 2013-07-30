//
//  ShelbyShareViewController.m
//  Shelby.tv
//
//  Created by Keren on 7/29/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyShareViewController.h"
#import "Frame.h"
#import "FacebookHandler.h"
#import "ShelbyDataMediator.h"
#import "TwitterHandler.h"

@interface ShelbyShareViewController ()
@property (assign, nonatomic) BOOL facebookConnected;
@property (assign, nonatomic) BOOL twitterConnected;

@property (nonatomic, weak) IBOutlet UIImageView *facebookCheck;
@property (nonatomic, weak) IBOutlet UIImageView *twitterCheck;

@property (nonatomic, weak) IBOutlet UIButton *facebookButton;
@property (nonatomic, weak) IBOutlet UIButton *twitterButton;

@property (nonatomic, weak) IBOutlet UILabel *videoTitle;
@property (nonatomic, weak) IBOutlet UITextView *message;

@property (nonatomic, strong) Frame *frame;
@property (nonatomic, strong) NSString *link;

@property (nonatomic, weak) IBOutlet UIButton *sendButton;

@property (nonatomic, strong) SPShareController *shareController;

- (IBAction)toggleFacebook:(id)sender;
- (IBAction)toggleTwitter:(id)sender;
- (IBAction)openDefaultShare:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)send:(id)sender;
@end

@implementation ShelbyShareViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self updateSocialButtons];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateFacebookToggle)
                                                 name:kShelbyNotificationFacebookAuthorizationCompleted object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateTwitterToggle)
                                                 name:kShelbyNotificationTwitterAuthorizationCompleted object:nil];
    

	// Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.message becomeFirstResponder];
    
    self.videoTitle.text = self.frame.video.title;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

-(BOOL) shouldAutorotate {
    return YES;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupShareWith:(Frame *)frame
                  link:(NSString *)link
    andShareController:(SPShareController *)shareController
{
    self.frame = frame;
    self.link = link;
    self.shareController = shareController;
}

- (void)send:(id)sender
{
    [self.shareController shelbyShareWithMessage:self.message.text withFacebook:!self.facebookCheck.hidden andWithTwitter:!self.twitterCheck.hidden];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)toggleFacebook:(id)sender
{
    self.facebookCheck.hidden = !self.facebookCheck.hidden;
    self.facebookButton.selected = !self.facebookCheck.hidden;
    
    
    [self.shareController toggleSocialFacebookButton:YES selected:!self.facebookCheck.hidden];
}


- (IBAction)toggleTwitter:(id)sender
{
    self.twitterCheck.hidden = !self.twitterCheck.hidden;
    self.twitterButton.selected = !self.twitterCheck.hidden;
    
    [self.shareController toggleSocialFacebookButton:NO selected:!self.twitterCheck.hidden];
}

- (IBAction)openDefaultShare:(id)sender
{
    
}

- (IBAction)cancel:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)updateFacebookToggle
{
    [self updateSocialButtons];
}

- (void)updateTwitterToggle
{
    [self updateSocialButtons];
}

- (void)updateSocialButtons
{
    User *user = [[ShelbyDataMediator sharedInstance] fetchAuthenticatedUserOnMainThreadContext];
   if (user) {
        self.facebookConnected = user.facebookName ? YES : NO;
        self.twitterConnected = user.twitterNickname ? YES : NO;
    } else {
        self.facebookConnected = NO;
        self.twitterConnected = NO;
    }
    
    if (self.facebookConnected) {
        self.facebookCheck.hidden = NO;
        self.facebookButton.selected = YES;
    } else {
        self.facebookCheck.hidden = YES;
        self.facebookButton.selected = NO;
    }

    if (self.twitterConnected) {
        self.twitterCheck.hidden = NO;
        self.twitterButton.selected = YES;
    } else {
        self.twitterCheck.hidden = YES;
        self.twitterButton.selected = NO;
    }
}


#pragma mark - UITextViewDelgate
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    NSString *shareMessage = textView.text;
    shareMessage = [shareMessage stringByReplacingCharactersInRange:range withString:text];
    if ([shareMessage length] > 10) {
        self.sendButton.enabled = YES;
    } else {
        self.sendButton.enabled = NO;
    }
    
    return YES;
}

@end
