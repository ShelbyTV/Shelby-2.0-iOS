//
//  Video.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/27/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Frame;

@interface Video : NSManagedObject

@property (nonatomic, retain) NSString * caption;
@property (nonatomic, retain) NSString * providerID;
@property (nonatomic, retain) NSString * providerName;
@property (nonatomic, retain) NSString * sourceURL;
@property (nonatomic, retain) NSString * thumbnailURL;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * videoID;
@property (nonatomic, retain) NSString * extractedURL;
@property (nonatomic, retain) NSSet *frame;
@end

@interface Video (CoreDataGeneratedAccessors)

- (void)addFrameObject:(Frame *)value;
- (void)removeFrameObject:(Frame *)value;
- (void)addFrame:(NSSet *)values;
- (void)removeFrame:(NSSet *)values;

@end
