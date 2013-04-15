//
//  BrowseViewController.h
//  Shelby.tv
//
//  Created by Keren on 2/13/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AuthorizationViewController.h"
#import "SPVideoReel.h"

@interface BrowseViewController : GAITrackedViewController <UICollectionViewDataSource, UICollectionViewDelegate, UITableViewDataSource, SPVideoReelDelegate, UITableViewDelegate, UIAlertViewDelegate, AuthorizationDelegate>

@property (weak, nonatomic) IBOutlet UIButton *toggleSecretButton;

/// Action Methods
- (IBAction)toggleSecretModes:(id)sender;

/// DataSource Methods
- (void)fetchAllCategories;

@end
