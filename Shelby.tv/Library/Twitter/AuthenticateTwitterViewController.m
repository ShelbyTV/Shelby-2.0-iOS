//
//  AuthenticateTwitterViewController.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 5/17/12.
//  Copyright (c) 2012 Shelby.tv. All rights reserved.
//

#import "AuthenticateTwitterViewController.h"

@interface AuthenticateTwitterViewController ()

@property (nonatomic) id <AuthenticateTwitterDelegate> delegate;  
@property (assign, nonatomic) BOOL pinPageLoaded;

- (void)initializationOnLoad;

@end

@implementation AuthenticateTwitterViewController

#pragma mark - Initialization Method
- (id)initWithDelegate:(id<AuthenticateTwitterDelegate>)delegate
{
    self = [super init];
    if ( self ) {
        _delegate = delegate;
    }
    
    return self;
}

#pragma mark - View Lifecycle Methods
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initializationOnLoad];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
        if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
            return;
        } else {
            self.webView.frame = [self frameForWebViewForOrientationLandscape:YES];
        }
    } else {
        self.webView.frame = [self frameForWebViewForOrientationLandscape:NO];
    }
}

#pragma mark - Private methods
- (void)initializationOnLoad
{
    
    // Customize leftBarButtonItem
    UIBarButtonItem *cancelBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" 
                                                                            style:UIBarButtonItemStyleDone 
                                                                           target:self 
                                                                           action:@selector(cancelAuthentication)];
    self.navigationItem.leftBarButtonItem = cancelBarButtonItem;
    
    self.navigationItem.title = @"Authorize Twitter";
    
    CGRect frameForWebView;
    if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
        frameForWebView = [self frameForWebViewForOrientationLandscape:YES];
    } else {
        frameForWebView = [self frameForWebViewForOrientationLandscape:NO];
    }

    self.webView = [[UIWebView alloc] initWithFrame:frameForWebView];
    self.webView.delegate = self;
    [self.view addSubview:self.webView];
    
    NSURL *authorizeUrl = [NSURL URLWithString:@"https://api.twitter.com/oauth/authenticate"];
    OAMutableURLRequest* authorizeRequest = [[OAMutableURLRequest alloc] initWithURL:authorizeUrl
                                                                            consumer:nil
                                                                               token:nil
                                                                               realm:nil
                                                                   signatureProvider:nil];
    // Create request for accessToken
    NSString *requestTokenKey = self.twitterRequestToken.key;
    OARequestParameter *tokenParam = [[OARequestParameter alloc] initWithName:@"oauth_token" value:requestTokenKey];
    OARequestParameter *loginParam = [[OARequestParameter alloc] initWithName:@"force_login" value:@"false"];
    [authorizeRequest setParameters:[NSArray arrayWithObjects:tokenParam, loginParam, nil]];
    
    [self.webView loadRequest:authorizeRequest];
}

- (CGRect)frameForWebViewForOrientationLandscape:(BOOL)landscapeOrientation
{
    NSInteger height, width;
    if (landscapeOrientation) {
        height = kShelbyFullscreenWidth;
        width = kShelbyFullscreenHeight;
    } else {
        height = kShelbyFullscreenHeight;
        width = kShelbyFullscreenWidth;
    }
    
    return CGRectMake(0.0f, 0.0f, width, height);
}

- (void)cancelAuthentication
{
    [self.delegate authenticationRequestDidCancel];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIWebViewDelegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    
    self.pinPageLoaded = ( [request.URL.absoluteString compare:@"https://api.twitter.com/oauth/authenticate"] == NSOrderedSame);
    
    return YES;
}


- (void)webViewDidFinishLoad:(UIWebView *)webView 
{

    if( self.pinPageLoaded ) {
        
        self.pinPageLoaded = NO;
        NSString *script = @"(function() { return document.getElementsByTagName(\"code\")[0].textContent; } ())";
        NSString *pin = [self.webView stringByEvaluatingJavaScriptFromString:script];

        if ( [pin length] > 0 ) {
            
            [self.delegate authenticationRequestDidReturnPin:pin];
            [self dismissViewControllerAnimated:YES completion:nil];

        }

    }
}

#pragma mark - Interface Orientation Methods
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end