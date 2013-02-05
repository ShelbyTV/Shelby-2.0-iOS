//
//  Stream.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 2/5/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Frame;

@interface Stream : NSManagedObject

@property (nonatomic, retain) NSString * streamID;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) Frame *frame;

@end
