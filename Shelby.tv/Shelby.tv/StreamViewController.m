//
//  FirstViewController.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 10/17/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import "StreamViewController.h"

@interface StreamViewController ()

- (void)getStream;

@end

@implementation StreamViewController
@synthesize button = _button;


#pragma mark - Memory Management Methods
- (void)dealloc
{
    self.button = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - View Lifecycle Methods
- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if ( [[NSUserDefaults standardUserDefaults] objectForKey:kUserAuthorizedDefault] ) {
        
//        [self getStream];

    }
    
}

#pragma mark - Private Methods
- (void)getStream
{
    
    NSString *authToken = [[NSUserDefaults standardUserDefaults] objectForKey:kUserAuthorizedDefault];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:kAPIShelbyGetStream, authToken]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];

        AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                
                CoreDataUtility *cdu = [[CoreDataUtility alloc] initWithRequestType:APIRequestType_GetStream];
                [cdu storeStream:JSON];
                
            });
            
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Stream Error"
                                                                message:@"Please try again"
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil, nil];
            [alertView show];
            
        }];
        
        [operation start];
}

@end