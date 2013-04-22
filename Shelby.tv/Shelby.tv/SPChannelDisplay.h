//
//  SPChannelDisplay.h
//  Shelby.tv
//
//  Created by Keren on 4/17/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SPChannelDisplay : NSObject
@property (readonly) UIColor *channelDisplayColor;
@property (readonly) NSString *channelDisplayTitle;

-(id)initWithChannelColor:(UIColor *)channelDisplayColor andChannelDisplayTitle:(NSString *)channelDisplayTitle;
@end
