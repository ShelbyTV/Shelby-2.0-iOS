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

@property (weak, nonatomic) IBOutlet UIView *headerView;

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
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateFacebookToggle)
                                                 name:kShelbyNotificationFacebookPublishAuthorizationCompleted object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateFacebookToggle)
                                                 name:kShelbyNotificationFacebookAuthorizationCompletedWithError object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateTwitterToggle)
                                                 name:kShelbyNotificationTwitterAuthorizationCompleted object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateTwitterToggle)
                                                 name:kShelbyNotificationTwitterConnectCompleted object:nil];

    //style the "header"
    [self.headerView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"top-nav-bkgd"]]];
    [self.sendButton setBackgroundImage:[[UIImage imageNamed:@"green-button-background"] resizableImageWithCapInsets:UIEdgeInsetsMake(2, 2, 2, 2)] forState:UIControlStateNormal];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self.message];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateSocialButtons];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [ShelbyAnalyticsClient trackScreen:kAnalyticsScreenShelbyShare];
    
    [self.message becomeFirstResponder];
    
    self.videoTitle.text = self.frame.video.title;
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
//    [ShelbyViewController sendEventWithCategory:kAnalyticsCategoryShare withAction:kAnalyticsShareActionShareSuccess withLabel:kShelbySPActivityTypeRoll];

    [self.shareController shelbyShareWithMessage:self.message.text withFacebook:!self.facebookCheck.hidden andWithTwitter:!self.twitterCheck.hidden];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)toggleFacebook:(id)sender
{
    self.facebookCheck.hidden = !self.facebookCheck.hidden;
    self.facebookButton.selected = !self.facebookCheck.hidden;
    self.facebookButton.enabled = !self.facebookButton.selected;
    
    BOOL waitingForPermissionsNotNeeded = [self.shareController toggleSocialFacebookButton:YES selected:!self.facebookCheck.hidden];
    
    if (waitingForPermissionsNotNeeded) {
        self.facebookButton.enabled = YES;
    }
}


- (IBAction)toggleTwitter:(id)sender
{
    self.twitterCheck.hidden = !self.twitterCheck.hidden;
    self.twitterButton.selected = !self.twitterCheck.hidden;
    self.twitterButton.enabled = !self.twitterButton.selected;
    
    BOOL waitingForPermissionsNotNeeded = [self.shareController toggleSocialFacebookButton:NO selected:!self.twitterCheck.hidden];
    if (waitingForPermissionsNotNeeded) {
        self.twitterButton.enabled = YES;
    }
}

- (IBAction)openDefaultShare:(id)sender
{
    //listen for iOS native share activity sheet notices
    [[NSNotificationCenter defaultCenter] addObserver:self.message
                                             selector:@selector(becomeFirstResponder)
                                                 name:kShelbyiOSNativeShareCancelled
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(iosNativeShareDone)
                                                 name:kShelbyiOSNativeShareDone
                                               object:nil];
    
    [self.shareController nativeShareWithFrame:self.frame message:self.videoTitle.text andLink:self.link fromViewController:self];
}

- (void)iosNativeShareDone
{
    //XXX we are waiting 1.5s for the iOS cancel animation to complete before dismissing ourselves
    // TODO: KP KP: do it in a nicer way. This is a TOTAL HACK
    double delayInSeconds = 1.5;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self dismissViewControllerAnimated:YES completion:^{
            [self.shareController shareComplete:YES];
        }];
    });
}

- (IBAction)cancel:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^{
        [self.shareController shareComplete:NO];
    }];
}

- (void)updateFacebookToggle
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.facebookButton.enabled = YES;
        [self updateSocialButtons];
    });
}

- (void)updateTwitterToggle
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.twitterButton.enabled = YES;
        [self updateSocialButtons];
    });
}

- (void)updateSocialButtons
{
    User *user = [[ShelbyDataMediator sharedInstance] fetchAuthenticatedUserOnMainThreadContext];
   if (user) {
        self.facebookConnected = user.facebookNickname && [[FacebookHandler sharedInstance] allowPublishActions] ? YES : NO;
        self.twitterConnected = user.twitterNickname ? YES : NO;
    } else {
        self.facebookConnected = NO;
        self.twitterConnected = NO;
    }
    
    BOOL defaultsFacebook = [[NSUserDefaults standardUserDefaults] boolForKey:kShelbyFacebookShareEnable];
    BOOL defaultsTwitter = [[NSUserDefaults standardUserDefaults] boolForKey:kShelbyTwitterShareEnable];
    
    if (self.facebookConnected && defaultsFacebook) {
        self.facebookCheck.hidden = NO;
        self.facebookButton.selected = YES;
    } else {
        self.facebookCheck.hidden = YES;
        self.facebookButton.selected = NO;
    }

    if (self.twitterConnected && defaultsTwitter) {
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
