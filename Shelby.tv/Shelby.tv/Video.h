//
//  Video.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 2/28/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Frame;

@interface Video : NSManagedObject

@property (nonatomic, retain) NSString * caption;
@property (nonatomic, retain) NSString * extractedURL;
@property (nonatomic, retain) NSString * offlineURL;
@property (nonatomic, retain) NSNumber * firstUnplayable;
@property (nonatomic, retain) NSNumber * lastUnplayable;
@property (nonatomic, retain) NSString * providerID;
@property (nonatomic, retain) NSString * providerName;
@property (nonatomic, retain) NSString * thumbnailURL;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * videoID;
@property (nonatomic, retain) NSSet *frame;
@end

@interface Video (CoreDataGeneratedAccessors)

- (void)addFrameObject:(Frame *)value;
- (void)removeFrameObject:(Frame *)value;
- (void)addFrame:(NSSet *)values;
- (void)removeFrame:(NSSet *)values;

@end
