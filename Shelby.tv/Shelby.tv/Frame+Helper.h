//
//  Frame+Helper.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 4/25/13.
//  Copyright (c) 2013 Shelby TV. All rights reserved.
//

#import "Frame.h"
#import "ShelbyModel.h"
#import "ShelbyDuplicateContainer.h"
#import "ShelbyVideoContainer.h"

@interface Frame (Helper) <ShelbyModel, ShelbyDuplicateContainer, ShelbyVideoContainer>

+ (Frame *)frameForDictionary:(NSDictionary *)dict
                    inContext:(NSManagedObjectContext *)context;

+ (NSArray *)fetchAllLikesInContext:(NSManagedObjectContext *)context;

- (NSString *)creatorsInitialCommentWithFallback:(BOOL)canUseVideoTitle;
- (BOOL)isPlayable;
- (void)toggleLike;
@end
