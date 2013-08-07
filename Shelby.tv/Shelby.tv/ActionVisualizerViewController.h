//
//  ActionVisualizerViewController.h
//  Shelby.tv
//
//  Created by Keren on 8/7/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^shelby_action_visualizer_complete_block_t)(BOOL complete);

@interface ActionVisualizerViewController : UIViewController

- (void)startAnimationWithCompletionBlock:(shelby_action_visualizer_complete_block_t)completionBlock;

@end
