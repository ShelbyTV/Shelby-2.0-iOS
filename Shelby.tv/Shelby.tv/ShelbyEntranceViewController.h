//
//  ShelbyEntranceViewController.h
//  Shelby.tv
//
//  Created by Dan Spinosa on 1/22/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ShelbyBrain.h"
#import "User.h"

@interface ShelbyEntranceViewController : UIViewController

@property (weak, nonatomic) ShelbyBrain *brain;

//affects visuals, you still need to remove view controller from hierarchy
- (void)animateDisappearanceWithCompletion:(void(^)())completion;

@end
