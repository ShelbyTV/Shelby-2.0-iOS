//
//  Group.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 2/5/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class GroupRoll;

@interface Group : NSManagedObject

@property (nonatomic, retain) NSString * titleID;
@property (nonatomic, retain) NSSet *groupRoll;
@end

@interface Group (CoreDataGeneratedAccessors)

- (void)addGroupRollObject:(GroupRoll *)value;
- (void)removeGroupRollObject:(GroupRoll *)value;
- (void)addGroupRoll:(NSSet *)values;
- (void)removeGroupRoll:(NSSet *)values;

@end
