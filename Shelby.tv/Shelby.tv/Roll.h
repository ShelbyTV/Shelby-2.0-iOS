//
//  Roll.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 5/2/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class DisplayChannel, Frame;

@interface Roll : NSManagedObject

@property (nonatomic, retain) NSString * creatorID;
@property (nonatomic, retain) NSString * displayColor;
@property (nonatomic, retain) NSString * displayDescription;
@property (nonatomic, retain) NSNumber * displayTag;
@property (nonatomic, retain) NSString * displayThumbnailURL;
@property (nonatomic, retain) NSString * displayTitle;
@property (nonatomic, retain) NSNumber * frameCount;
@property (nonatomic, retain) NSNumber * isChannel;
@property (nonatomic, retain) NSString * rollID;
@property (nonatomic, retain) NSString * thumbnailURL;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) DisplayChannel *displayChannel;
@property (nonatomic, retain) NSSet *frame;
@end

@interface Roll (CoreDataGeneratedAccessors)

- (void)addFrameObject:(Frame *)value;
- (void)removeFrameObject:(Frame *)value;
- (void)addFrame:(NSSet *)values;
- (void)removeFrame:(NSSet *)values;

@end
