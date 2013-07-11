//
//  ShelbyNavBarView.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 7/9/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ShelbyNavBarView : UIView
@property (weak, nonatomic) IBOutlet UIButton *streamButton;
@property (weak, nonatomic) IBOutlet UIButton *likesButton;
@property (weak, nonatomic) IBOutlet UIButton *sharesButton;
@property (weak, nonatomic) IBOutlet UIButton *communityButton;

@property (weak, nonatomic) IBOutlet UIView *streamRow;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *streamRowHeight;
@property (weak, nonatomic) IBOutlet UIView *likesRow;
@property (weak, nonatomic) IBOutlet UIView *sharesRow;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *sharesRowHeight;
@property (weak, nonatomic) IBOutlet UIView *communityRow;

@property (weak, nonatomic) IBOutlet UIView *selectionIdentifier;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *selectionIdentifierX;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *selectionIdentifierY;

@end
