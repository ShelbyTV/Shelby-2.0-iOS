//
//  ShelbyBrowseTutorialView.h
//  Shelby.tv
//
//  Created by Keren on 5/15/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ShelbyBrowseTutorialView : UIView
- (id)initWithTitle:(NSString *)title message:(NSString *)message closeButtonText:(NSString *)closeButtonText andOwner:(UIViewController *)owner;
@end
