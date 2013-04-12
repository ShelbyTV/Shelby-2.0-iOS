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
        self.delegate = delegate;
    }
    
    return self;
}

#pragma mark - View Lifecycle Methods
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initializationOnLoad];
}

#pragma mark - Private methods
- (void)initializationOnLoad
{
    
    // Customize leftBarButtonItem
    UIBarButtonItem *cancelBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" 
                                                                            style:UIBarButtonItemStyleDone 
                                                                           target:self 
                                                                           action:@selector(dismissModalViewControllerAnimated:)];
    self.navigationItem.leftBarButtonItem = cancelBarButtonItem;
    
    // Add webView to view hierarchy
    self.webView = [[UIWebView alloc] initWithFrame:CGRectMake(0.0f,
                                                               0.0f,
                                                               [UIScreen mainScreen].bounds.size.height,
                                                               [UIScreen mainScreen].bounds.size.width)];
    self.webView.delegate = self;
    
    [self.view addSubview:self.webView];
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