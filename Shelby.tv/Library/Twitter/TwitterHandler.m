//
//  TwitterHandler.m
//  TwitterHandler
//
//  Created by Arthur Ariel Sabintsev on 4/18/12.
//  Copyright (c) 2012 ArtSabintsev. All rights reserved.
//

#import "TwitterHandler.h"

#import <Accounts/Accounts.h>
#import "AuthenticateTwitterViewController.h"
#import "OAuthConsumer.h"
#import <Social/Social.h>
#import "DeviceUtilities.h"
#import "ShelbyDataMediator.h"
#import "ShelbyAnalyticsClient.h"
#import "ShelbyAPIClient.h"
#import "User+Helper.h"

NSString * const kShelbyNotificationTwitterAuthorizationCompleted = @"kShelbyNotificationTwitterAuthorizationCompleted";

@interface TwitterHandler () <AuthenticateTwitterDelegate>

@property (nonatomic) UIViewController *viewController;
@property (nonatomic) ACAccountStore *twitterAccountStore;
@property (nonatomic) ACAccount *twitterAccount;                   
@property (nonatomic) OAToken *twitterRequestToken;
@property (copy, nonatomic) NSString *twitterName;
@property (copy, nonatomic) NSString *twitterID;
@property (copy, nonatomic) NSString *twitterReverseAuthToken;              
@property (copy, nonatomic) NSString *twitterReverseAuthSecret;
@property (nonatomic) NSMutableArray *storedTwitterAccounts;
@property (nonatomic, weak) id<TwitterHandlerDelegate> delegate;
@property (nonatomic, strong) NSString *shelbyToken;

/// Twitter Authorization Methods ///
- (void)checkForExistingTwitterAccounts;
- (void)userHasOneStoredTwitterAccount;
- (void)userHasMultipleStoredTwitterAccounts;

/// Twitter/OAuth - Request Token Methods ///
- (void)getRequestToken;
- (void)requestTokenTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data; 
- (void)requestTokenTicket:(OAServiceTicket *)ticket didFailWithError:(NSData *)data;
- (void)authenticateTwitterAccount;

/// Twitter/OAuth - Access Token Methods ///
- (void)getAccessTokenWithPin:(NSString *)pin;
- (void)accessTokenTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data;
- (void)accessTokenTicket:(OAServiceTicket *)ticket didFailWithError:(NSData *)data;
- (void)saveTwitterAccountWithAccessToken:(OAToken *)accessToken;

/// Twitter/OAuth - Reverse Auth Request Token Methods ///
- (void)getReverseAuthRequestToken;
- (void)reverseAuthRequestTokenTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data;
- (void)reverseAuthRequestTokenTicket:(OAServiceTicket *)ticket didFailWithError:(NSData *)data;

/// Twitter/OAuth - Reverse Auth Access Token Methods ///
- (void)getReverseAuthAccessToken:(NSString *)reverseAuthRequestResults;
- (void)sendReverseAuthAccessResultsToServer;
- (void)tokenSwapWasSuccessfulForUser:(NSDictionary *)userDictionary;

@end

@implementation TwitterHandler

#pragma mark - Initialization Methods
+ (TwitterHandler *)sharedInstance
{
    static TwitterHandler *sharedInstance = nil;
    static dispatch_once_t twitterToken = 0;
    dispatch_once(&twitterToken, ^{
        sharedInstance = [[super allocWithZone:NULL] init];
    });
    
    return sharedInstance;
}


#pragma mark - Twitter Authorization Methods
- (void)authenticateWithViewController:(UIViewController *)viewController withDelegate:(id<TwitterHandlerDelegate>)delegate andAuthToken:(NSString *)authToken
{
    [self setViewController:viewController];
    
    // Get all stored twitterAccounts
    self.twitterAccountStore = [[ACAccountStore alloc] init];
    ACAccountType *twitterType = [self.twitterAccountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    self.twitterAccount = [[ACAccount alloc] initWithAccountType:twitterType];
 
    // In iOS7 you have to request access to twitter account store. Even if there are no twitter accounts in Settings
    if ([DeviceUtilities isGTEiOS7]) {
        [self.twitterAccountStore requestAccessToAccountsWithType:twitterType options:nil completion:^(BOOL granted, NSError *error) {
            if (granted) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self checkForExistingTwitterAccounts];
               });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"To connect Twitter, go to Settings -> Privacy -> Twitter and turn Shelby ON" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [alertView show];
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:kShelbyNotificationTwitterAuthorizationCompleted object:nil];
                });
            }
        }];
    } else {
        [self checkForExistingTwitterAccounts];
        
    }

    self.delegate = delegate;
    self.shelbyToken = authToken;
}

#pragma mark - Private Methods
- (void)checkForExistingTwitterAccounts
{
    
    // Clear stored twitterAccount
    if ( [self.twitterAccount.username length] ) {
        self.twitterAccount = nil;
    }
    
    ACAccountType *twitterType = [self.twitterAccountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    NSArray *accounts = [NSArray arrayWithArray:[self.twitterAccountStore accountsWithAccountType:twitterType]];
    
    if (0 == [accounts count]) {
        [self getRequestToken];
    } else {
        [self.twitterAccountStore requestAccessToAccountsWithType:twitterType options:nil completion:^(BOOL granted, NSError *error) {
            
            if ( granted && !error ) {
                NSArray *accounts = [NSArray arrayWithArray:[self.twitterAccountStore accountsWithAccountType:twitterType]];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    if ( 1 == [accounts count] ) { // One stored Twitter account
                        DLog(@"User has one stored account");
                        self.twitterAccount = [accounts objectAtIndex:0];
                        [self userHasOneStoredTwitterAccount];
                    } else { // Multiple stored Twitter accounts
                        DLog(@"User has multiple stored accounts");
                        [self userHasMultipleStoredTwitterAccounts];
                    }
                    
                });
                
            } else {
                NSLog(@"Access granted? %@. %@", (granted) ? @"YES" : @"NO", error);
            }
            
        }];
    }
}

- (void)userHasOneStoredTwitterAccount
{
    [self getReverseAuthRequestToken];
}

- (void)userHasMultipleStoredTwitterAccounts
{
    
    // Create empty UIActionSheet
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Choose a stored Twitter account"
                                                       delegate:self
                                              cancelButtonTitle:nil
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:nil];
    
    
    // Add each account as new item on actionSheet
    ACAccountType *twitterType = [self.twitterAccountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    NSArray *accounts = [self.twitterAccountStore accountsWithAccountType:twitterType];
    for( ACAccount *account in accounts)  {
        [actionSheet addButtonWithTitle:account.username];
    }
    
    // Add cancel button
    [actionSheet addButtonWithTitle:@"Cancel"];
    
    // Present actionSheet
    [actionSheet showInView:self.viewController.view];
}

#pragma mark - Twitter/OAuth- Request Token Methods
- (void)getRequestToken 
{
    
    // Remove reqeustToken value if value exists and/or user decides to re-authenticate
    if (self.twitterRequestToken) {
        self.twitterRequestToken = nil;
    }
    
    NSURL *requestTokenURL = [NSURL URLWithString:@"https://api.twitter.com/oauth/request_token"];
    OAConsumer *consumer= [[OAConsumer alloc] initWithKey:kShelbyTwitterConsumerKey secret:kShelbyTwitterConsumerSecret];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:requestTokenURL
                                                                   consumer:consumer
                                                                      token:nil
                                                                      realm:nil 
                                                          signatureProvider:nil];
    
    
    [request setHTTPMethod:@"POST"];
    
    OARequestParameter *oauthParam = [[OARequestParameter alloc] initWithName:@"oauth_callback" value:@"oob"];
    NSArray *params = [NSArray arrayWithObject:oauthParam];
    [request setParameters:params];
    
    OADataFetcher *requestTokenFetcher = [[OADataFetcher alloc] init];
    [requestTokenFetcher fetchDataWithRequest:request
                                     delegate:self
                            didFinishSelector:@selector(requestTokenTicket:didFinishWithData:)
                              didFailSelector:@selector(requestTokenTicket:didFailWithError:)];

}

- (void)requestTokenTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data 
{
    if (ticket.didSucceed) {
        
        NSString* httpBodyData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        self.twitterRequestToken = [[OAToken alloc] initWithHTTPResponseBody:httpBodyData];
        [self authenticateTwitterAccount];
        
    }
}

- (void)requestTokenTicket:(OAServiceTicket *)ticket didFailWithError:(NSData *)data
{
    // Failed
    DLog(@"Request Token - Fetch Failure");
}

- (void)authenticateTwitterAccount
{
    
    
    // Load ViewController (that has webView)
    AuthenticateTwitterViewController *authenticateTwitterViewController = [[AuthenticateTwitterViewController alloc] initWithDelegate:self];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:authenticateTwitterViewController];

    authenticateTwitterViewController.twitterRequestToken = self.twitterRequestToken;
    authenticateTwitterViewController.webView.backgroundColor = [UIColor redColor];
    [self.viewController presentViewController:navigationController animated:YES completion:nil];
    
}

#pragma mark - Twitter/OAuth - Access Token Methods
- (void)getAccessTokenWithPin:(NSString *)pin
{
    
    NSURL *accessTokenURL = [NSURL URLWithString:@"https://api.twitter.com/oauth/access_token"];
    OAMutableURLRequest * accessTokenRequest = [[OAMutableURLRequest alloc] initWithURL:accessTokenURL
                                                                               consumer:nil
                                                                                  token:self.twitterRequestToken
                                                                                  realm:nil
                                                                      signatureProvider:nil];
    
    OARequestParameter * tokenParam = [[OARequestParameter alloc] initWithName:@"oauth_token" value:self.twitterRequestToken.key];
    OARequestParameter * verifierParam = [[OARequestParameter alloc] initWithName:@"oauth_verifier" value:pin];
    NSArray * params = [NSArray arrayWithObjects:tokenParam, verifierParam, nil];
    [accessTokenRequest setParameters:params];
    
    OADataFetcher * accessTokenFetcher = [[OADataFetcher alloc] init];
    [accessTokenFetcher fetchDataWithRequest:accessTokenRequest
                                    delegate:self
                           didFinishSelector:@selector(accessTokenTicket:didFinishWithData:)
                             didFailSelector:@selector(accessTokenTicket:didFailWithError:)];
}

- (void)accessTokenTicket:(OAServiceTicket*)ticket didFinishWithData:(NSData*)data 
{
    if (ticket.didSucceed) {
    
        NSString* httpBodyData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
         OAToken *accessToken = [[OAToken alloc] initWithHTTPResponseBody:httpBodyData];
        [self saveTwitterAccountWithAccessToken:accessToken];
    
    }
}

- (void)accessTokenTicket:(OAServiceTicket *)ticket didFailWithError:(NSData *)data
{
    // Failed
    DLog(@"Access Token - Fetch Failure");
}

- (void)saveTwitterAccountWithAccessToken:(OAToken *)accessToken
{
    NSString *token = accessToken.key;
    NSString *secret = accessToken.secret;
    
    // Store Twitter Account on device as ACAccount
    ACAccountType *twitterType = [self.twitterAccountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    ACAccount *newAccount = [[ACAccount alloc] initWithAccountType:twitterType];
    newAccount.credential = [[ACAccountCredential alloc] initWithOAuthToken:token tokenSecret:secret];;
    
    [self.twitterAccountStore saveAccount:newAccount withCompletionHandler:^(BOOL success, NSError *error) {

        // This completionHandler block is NOT performed on the main thread
        if ( success ) {

            DLog(@"New Account Saved to Store");
            
            // Reverse Auth must be performed on Main Thread.
            dispatch_async(dispatch_get_main_queue(), ^{
                self.twitterAccount = newAccount;
                [self getReverseAuthRequestToken];
            });
    
        }
    }];

}

#pragma mark - OAuthConsumer - Reverse Auth Request Token Methods
- (void)getReverseAuthRequestToken
{
    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/oauth/request_token"];
    OAConsumer *consumer= [[OAConsumer alloc] initWithKey:kShelbyTwitterConsumerKey secret:kShelbyTwitterConsumerSecret];
    OAMutableURLRequest *reverseAuthRequest = [[OAMutableURLRequest alloc] initWithURL:url
                                                                              consumer:consumer
                                                                                 token:nil
                                                                                 realm:nil 
                                                                     signatureProvider:nil];
    
    [reverseAuthRequest setHTTPMethod:@"POST"];
        
    OARequestParameter *xauthParam = [[OARequestParameter alloc] initWithName:@"x_auth_mode" value:@"reverse_auth"];
    NSArray *params = [NSArray arrayWithObject:xauthParam];
    [reverseAuthRequest setParameters:params];
    
    OADataFetcher *reverseAuthFetcher = [[OADataFetcher alloc] init];
    [reverseAuthFetcher fetchDataWithRequest:reverseAuthRequest
                                    delegate:self
                           didFinishSelector:@selector(reverseAuthRequestTokenTicket:didFinishWithData:)
                             didFailSelector:@selector(reverseAuthRequestTokenTicket:didFailWithError:)];
    
}

- (void)reverseAuthRequestTokenTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data
{
    if (ticket.didSucceed) {
        NSString *httpBodyData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        [self getReverseAuthAccessToken:httpBodyData];
    } else {
        [self twitterCleanup];
    }
}

- (void)reverseAuthRequestTokenTicket:(OAServiceTicket *)ticket didFailWithError:(NSData *)data
{
    // Failed
    DLog(@"Reverse Auth Request Token - Fetch Failure");
    
    [self twitterCleanup];
}

#pragma mark - OAuthConsumer - Reverse Auth Access Token Methods
- (void)getReverseAuthAccessToken:(NSString *)reverseAuthRequestResults
{
    
    NSURL *accessTokenURL = [NSURL URLWithString:@"https://api.twitter.com/oauth/access_token"];
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:kShelbyTwitterConsumerKey, @"x_reverse_auth_target", reverseAuthRequestResults, @"x_reverse_auth_parameters", nil];
    SLRequest *reverseAuthAccessTokenRequest  = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                                                   requestMethod:SLRequestMethodPOST
                                                                             URL:accessTokenURL
                                                                      parameters:parameters];
    DLog(@"Request Results: %@",parameters);
    
    ACAccountType *twitterType = [self.twitterAccountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    [self.twitterAccountStore requestAccessToAccountsWithType:twitterType options:nil completion:^(BOOL granted, NSError *error) {
        if ( granted && !error ) {
            [reverseAuthAccessTokenRequest setAccount:self.twitterAccount];
            [reverseAuthAccessTokenRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                if ( responseData ) {
                    // Get results string (e.g., Access Token, Access Token Secret, Twitter Handle)
                    NSString *reverseAuthAccessResults = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
                    
                    DLog(@"Access Results: %@",reverseAuthAccessResults);
                    // Parse string for Acces Token and Access Token Secret
                    NSString *token = nil;
                    NSString *secret = nil;
                    NSString *ID = nil;
                    NSString *name = nil;
                    NSScanner *scanner = [NSScanner scannerWithString:reverseAuthAccessResults];
                    [scanner scanUpToString:@"=" intoString:nil];
                    [scanner scanUpToString:@"&" intoString:&token];
                    token = [token stringByReplacingOccurrencesOfString:@"=" withString:@""];
                    [scanner scanUpToString:@"=" intoString:nil];
                    [scanner scanUpToString:@"&" intoString:&secret];
                    secret = [secret stringByReplacingOccurrencesOfString:@"=" withString:@""];
                    [scanner scanUpToString:@"=" intoString:nil];
                    [scanner scanUpToString:@"&" intoString:&ID];
                    ID = [ID stringByReplacingOccurrencesOfString:@"=" withString:@""];
                    [scanner scanUpToString:@"=" intoString:nil];
                    [scanner scanUpToString:@"" intoString:&name];
                    name = [name stringByReplacingOccurrencesOfString:@"=" withString:@""];
                    
                    // Store Reverse Auth Access Token and Access Token Secret
                    DLog(@"ReverseAuth Token: %@", token);
                    DLog(@"ReverseAuth Secret: %@", secret);
                    
                    [self setTwitterReverseAuthToken:token];
                    [self setTwitterReverseAuthSecret:secret];
                    [self setTwitterID:ID];
                    [self setTwitterName:name];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{

                        // localytics tracking for user connecting twitter account
                        [ShelbyAnalyticsClient sendLocalyticsEventForFinishConnectingAccountType:kLocalyticsAttributeValueAccountTypeTwitter];

                        User *user = [User updateUserWithTwitterUsername:name andTwitterID:ID];
                        NSError *err;
                        [user.managedObjectContext save:&err];
                        STVDebugAssert(!err, @"context save failed saving User after twitter login...");
                        if (err) {
                            [ShelbyAnalyticsClient sendEventWithCategory:kAnalyticsCategoryIssues
                                                                  action:kAnalyticsIssueContextSaveError
                                                                   label:[NSString stringWithFormat:@"-[getReverseAuthAccessToken:] error: %@", err]];
                        }
                        
                        [self.delegate twitterConnectDidComplete];
                        
                        [[NSNotificationCenter defaultCenter] postNotificationName:kShelbyNotificationTwitterConnectCompleted object:nil];
                        
                        if (name) {
                            [[NSUserDefaults standardUserDefaults] setObject:name forKey:kShelbyTwitterUsername];
                            [[NSUserDefaults standardUserDefaults] synchronize];
                        }
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                            // Send Reverse Auth Access Token and Access Token Secret to Shelby for Token Swap
                            [self sendReverseAuthAccessResultsToServer];
                        });
                    });
                } else {
                    // KP KP: TODO: change error message.s
                    [self.delegate twitterConnectDidCompleteWithError:@"Error setting Twitter account. Please try again later."];
                    DLog(@"%@", error);
                }
            }];
        }
    }];
}

- (void)sendReverseAuthAccessResultsToServer
{
    [ShelbyAPIClient postThirdPartyToken:@"twitter"
                           withAccountID:self.twitterID
                              oauthToken:self.twitterReverseAuthToken
                             oauthSecret:self.twitterReverseAuthSecret
                         shelbyAuthToken:self.shelbyToken
                                andBlock:^(id JSON, NSError *error) {
                                    // TODO: could it be a different error?
                                    if (error && [error.domain isEqualToString:@"ShelbyAPIClient"] && error.code == 403002) {
                                        NSDictionary *errorInfo = error.userInfo;
                                        NSString *errorMessage = [[ShelbyDataMediator sharedInstance] errorMessageForExistingAccountWithErrorDictionary:errorInfo];
                                        
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            [self twitterCleanup];
                                            
                                            [[NSNotificationCenter defaultCenter] postNotificationName:kShelbyNotificationTwitterAuthorizationCompleted object:nil];
                                            [self.delegate twitterConnectDidCompleteWithError:errorMessage];
                                        });
                                    }
                                 }];
}

- (void)tokenSwapWasSuccessfulForUser:(NSDictionary *)userDictionary
{
    // Post token-swap notification to listeners
    [[NSNotificationCenter defaultCenter] postNotificationName:kShelbyNotificationTwitterAuthorizationCompleted object:nil];
}

// Cleanup
- (void)twitterCleanup
{
    dispatch_async(dispatch_get_main_queue(), ^{
        User *user = [User updateUserWithTwitterUsername:nil andTwitterID:nil];
        NSError *err;
        [user.managedObjectContext save:&err];
        STVDebugAssert(!err, @"context save failed saving User after twitter login...");
    });
}

#pragma mark - AuthenticateTwitterDelegate Methods
- (void)authenticationRequestDidReturnPin:(NSString *)pin
{
    [self getAccessTokenWithPin:pin];
}

- (void)authenticationRequestDidCancel
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kShelbyNotificationTwitterAuthorizationCompleted object:nil];
}

#pragma mark - UIActionSheetDelegate Methods 
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    ACAccountType *twitterType = [self.twitterAccountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    NSArray *accounts = [self.twitterAccountStore accountsWithAccountType:twitterType];
    NSInteger accountsCount = [accounts count];

    
    if ( buttonIndex < accountsCount ) {
        self.twitterAccount = accounts[buttonIndex];
        [self getReverseAuthRequestToken];
        
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:kShelbyNotificationTwitterAuthorizationCompleted object:nil];
    }
    
}

@end