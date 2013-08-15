//
//  AuthenticateTwitterViewController.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 5/17/12.
//  Copyright (c) 2012 Shelby.tv. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OAuthConsumer.h"

@protocol AuthenticateTwitterDelegate <NSObject>
- (void)authenticationRequestDidReturnPin:(NSString*)pin;
- (void)authenticationRequestDidCancel;
@end

@interface AuthenticateTwitterViewController : UIViewController <UIWebViewDelegate>

@property (strong, nonatomic) UIWebView *webView;
@property (nonatomic) OAToken *twitterRequestToken;

- (id)initWithDelegate:(id<AuthenticateTwitterDelegate>)delegate;

@end