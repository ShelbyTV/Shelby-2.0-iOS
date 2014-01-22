//
//  ShelbyUserEducationViewController.h
//  Shelby.tv
//
//  Created by Dan Spinosa on 1/21/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ShelbyUserEducationViewController : UIViewController

//returns nil if user has already been educated
+ (ShelbyUserEducationViewController *)newStreamUserEducationViewController;

//return nil if user has already been educated
+ (ShelbyUserEducationViewController *)newChannelsUserEducationViewController;

//resets all user education views
+ (void)reset;

//only shows view if user hasn't been educated
- (void)referenceViewWillAppear:(CGRect)referenceViewFrame animated:(BOOL)animated;

//hides view
- (void)referenceViewWillDisappear:(BOOL)animated;

//prevents view from appearing.
//future calles to +new... will return nil for this type of education.
- (void)userHasBeenEducatedAndViewShouldHide:(BOOL)shouldHide;

@end
