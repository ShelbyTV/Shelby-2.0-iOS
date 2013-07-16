//
//  BlinkingLabel.m
//  Shelby.tv
//
//  Created by Keren on 7/16/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "BlinkingLabel.h"

@implementation BlinkingLabel

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setWords:(NSArray *)words
{
    _words = words;
    [self startBlinking];
}


- (void)startBlinking
{
    NSInteger rand = arc4random() % [self.words count];
    self.text = self.words[rand];
    [self performSelector:@selector(startBlinking) withObject:nil afterDelay:0.5];
}

@end
