//
//  BlinkingLabel.m
//  Shelby.tv
//
//  Created by Keren on 7/16/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "BlinkingLabel.h"
@interface BlinkingLabel()
@property (nonatomic, assign) CGFloat blinkingTime;
@property (nonatomic, strong) NSString *completionText;
@property (nonatomic, assign) CGFloat currentBlinkingTime;
@property (nonatomic, strong) NSArray *words;
@end

#define kShelbyBlinkTime 0.5

@implementation BlinkingLabel

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setupWords:(NSArray *)words
   andBlinkingTime:(CGFloat)time
withCompletionText:(NSString *)completionText
          andBlock:(shelby_blinking_label_complete_block_t)completionBlock
{
    self.words = words;
    self.blinkingTime = time;
    self.currentBlinkingTime = 0;
    self.completionText = completionText;
    
    [self startBlinking:completionBlock];
}

- (void)startBlinking:(shelby_blinking_label_complete_block_t)completionBlock
{
    if (self.currentBlinkingTime > self.blinkingTime) {
        self.text = self.completionText;
        if (completionBlock) {
            completionBlock(YES);
        }
        return;
    }
    self.currentBlinkingTime += kShelbyBlinkTime;
    NSInteger rand = arc4random() % [self.words count];
    self.text = self.words[rand];
    [self performSelector:@selector(startBlinking:) withObject:completionBlock afterDelay:kShelbyBlinkTime];
}

@end
