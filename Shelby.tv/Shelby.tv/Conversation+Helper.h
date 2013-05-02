//
//  Conversation+Helper.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 5/2/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "Conversation.h"

@interface Conversation (Helper)

+ (Conversation *)conversationForDictionary:(NSDictionary *)dict
                                  inContext:(NSManagedObjectContext *)context;

@end
