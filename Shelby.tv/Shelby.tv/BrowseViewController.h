//
//  BrowseViewController.h
//  Shelby.tv
//
//  Created by Keren on 2/13/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BrowseViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UITextFieldDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UIButton *toggleSecretButton;

/// Action Methods
- (IBAction)toggleSecretModes:(id)sender;

/// DataSource Methods
- (void)fetchAllCategories;
- (void)resetView; // To be called when PageControl and CollectioView need to be reset according to user login status

@end
