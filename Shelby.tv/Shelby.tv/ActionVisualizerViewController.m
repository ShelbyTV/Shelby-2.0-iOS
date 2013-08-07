//
//  ActionVisualizerViewController.m
//  Shelby.tv
//
//  Created by Keren on 8/7/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ActionVisualizerViewController.h"
#import "HeartView.h"

@interface ActionVisualizerViewController ()
@property (nonatomic, strong) HeartView *heartView;
@end

@implementation ActionVisualizerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


- (id)init
{
    self = [super init];
    if (self) {
    
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSInteger width, height;
    if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
        width = self.view.frame.size.height;
        height = self.view.frame.size.width;
    } else {
        width = self.view.frame.size.width;
        height = self.view.frame.size.height;
    }
    
    CGRect frame = CGRectMake(width/2 - 36, height/2 - 36, 72, 72);
    _heartView = [[HeartView alloc] initWithFrame:frame];
    
 	self.view = self.heartView;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)startAnimationWithCompletionBlock:(shelby_action_visualizer_complete_block_t)completionBlock
{
    [((HeartView *)self.view) addPointsToView];
    [((HeartView *)self.view) addPointsToView];
    
    [UIView animateWithDuration:0.1 animations:^{
        [self.heartView setProgress:0.2];
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.1 animations:^{
            [self.heartView setProgress:0.4];
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.05 animations:^{
                [self.heartView setProgress:0.6];
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:0.05 animations:^{
                    [self.heartView setProgress:0.8];
                } completion:^(BOOL finished) {
                    [UIView animateWithDuration:0.2 animations:^{
                        [self.heartView setProgress:0.9];
                        [self.heartView fillShape];
                    } completion:^(BOOL finished) {
                        if (completionBlock) {
                            completionBlock(finished);
                        }
                    }];
                }];
            }];
        }];
    }];
}

@end
