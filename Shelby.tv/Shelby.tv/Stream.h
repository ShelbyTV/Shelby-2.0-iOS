//
//  Stream.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 12/19/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Frame;

@interface Stream : NSManagedObject

@property (nonatomic, retain) NSString * streamID;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) Frame *frame;

@end
