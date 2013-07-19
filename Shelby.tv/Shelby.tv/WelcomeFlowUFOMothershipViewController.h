//
//  WelcomeFlowUFOMothershipViewController.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 7/19/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WelcomeFlowUFOMothershipViewController : UIViewController

- (void)controllingContentOffsetDidChange:(CGPoint)offset;
- (void)pageDidChange:(NSUInteger)page;

@end
