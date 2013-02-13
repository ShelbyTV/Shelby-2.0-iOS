//
//  Creator.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 2/13/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Frame;

@interface Creator : NSManagedObject

@property (nonatomic, retain) NSString * creatorID;
@property (nonatomic, retain) NSString * nickname;
@property (nonatomic, retain) NSString * userImage;
@property (nonatomic, retain) NSSet *frame;
@end

@interface Creator (CoreDataGeneratedAccessors)

- (void)addFrameObject:(Frame *)value;
- (void)removeFrameObject:(Frame *)value;
- (void)addFrame:(NSSet *)values;
- (void)removeFrame:(NSSet *)values;

@end
