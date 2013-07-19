//
//  BlinkingLabel.h
//  Shelby.tv
//
//  Created by Keren on 7/16/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef void (^shelby_blinking_label_complete_block_t)(BOOL done);

@interface BlinkingLabel : UILabel

- (void)setupWords:(NSArray *)words
   andBlinkingTime:(CGFloat)time
withCompletionText:(NSString *)completionText
          andBlock:(shelby_blinking_label_complete_block_t)completionBlock;
@end
