//
//  StreamEntry.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 4/21/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Frame;

@interface StreamEntry : NSManagedObject

@property (nonatomic, retain) NSString * streamEntryID;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) Frame *frame;

@end
