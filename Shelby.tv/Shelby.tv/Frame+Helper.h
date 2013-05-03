//
//  Frame+Helper.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 4/25/13.
//  Copyright (c) 2013 Shelby TV. All rights reserved.
//

#import "Frame.h"

@interface Frame (Helper)

+ (Frame *)frameForDictionary:(NSDictionary *)dict
                    inContext:(NSManagedObjectContext *)context;

- (NSString *)creatorsInitialCommentWithFallback:(BOOL)canUseVideoTitle;
- (BOOL)isPlayable;
@end
