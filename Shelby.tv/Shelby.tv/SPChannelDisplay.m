//
//  SPChannelDisplay.m
//  Shelby.tv
//
//  Created by Keren on 4/17/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import "SPChannelDisplay.h"
@interface SPChannelDisplay()
@property (nonatomic, strong) UIColor *channelDisplayColor;
@property (nonatomic, strong) NSString *channelDisplayTitle;
@end

@implementation SPChannelDisplay

-(id)initWithChannelColor:(UIColor *)channelDisplayColor andChannelDisplayTitle:(NSString *)channelDisplayTitle
{
    self = [super init];
    if (self) {
        _channelDisplayColor = channelDisplayColor;
        _channelDisplayTitle = channelDisplayTitle;
    }
    
    return self;
}
@end
