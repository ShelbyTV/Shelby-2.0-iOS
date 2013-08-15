//
//  Video+Helper.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 5/2/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "Video.h"
#import "ShelbyVideoContainer.h"

@interface Video (Helper) <ShelbyVideoContainer>

+ (Video *)videoForDictionary:(NSDictionary *)dict
                    inContext:(NSManagedObjectContext *)context;
- (BOOL)isPlayable;

- (NSURL *)maxResThumbnailURL;

@end
