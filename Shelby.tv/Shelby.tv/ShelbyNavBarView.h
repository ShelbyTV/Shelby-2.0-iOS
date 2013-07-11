//
//  ShelbyNavBarView.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 7/9/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ShelbyNavBarView : UIView

@property (weak, nonatomic) IBOutlet UIView *streamRow;
@property (weak, nonatomic) IBOutlet UIView *likesRow;
@property (weak, nonatomic) IBOutlet UIView *sharesRow;
@property (weak, nonatomic) IBOutlet UIView *communityRow;
@property (weak, nonatomic) IBOutlet UIView *selectionIdentifier;

//our model, set to update display state
@property (weak, nonatomic) UIView *currentRow;

- (void)showLoggedInUserRows:(BOOL)showUserRows;

@end
