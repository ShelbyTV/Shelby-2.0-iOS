//
//  User.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 7/25/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Frame;

@interface User : NSManagedObject

@property (nonatomic, retain) NSNumber * admin;
@property (nonatomic, retain) NSString * facebookName;
@property (nonatomic, retain) NSString * facebookNickname;
@property (nonatomic, retain) NSString * facebookUID;
@property (nonatomic, retain) NSString * likesRollID;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * nickname;
@property (nonatomic, retain) NSString * publicRollID;
@property (nonatomic, retain) NSString * token;
@property (nonatomic, retain) NSString * tumblrNickname;
@property (nonatomic, retain) NSString * tumblrUID;
@property (nonatomic, retain) NSString * twitterNickname;
@property (nonatomic, retain) NSString * twitterUID;
@property (nonatomic, retain) NSString * userID;
@property (nonatomic, retain) NSString * userImage;
@property (nonatomic, retain) NSNumber * userType;
@property (nonatomic, retain) NSNumber * hasShelbyAvatar;
@property (nonatomic, retain) NSSet *frames;
@property (nonatomic, retain) NSSet *upvoted;
@end

@interface User (CoreDataGeneratedAccessors)

- (void)addFramesObject:(Frame *)value;
- (void)removeFramesObject:(Frame *)value;
- (void)addFrames:(NSSet *)values;
- (void)removeFrames:(NSSet *)values;

- (void)addUpvotedObject:(Frame *)value;
- (void)removeUpvotedObject:(Frame *)value;
- (void)addUpvoted:(NSSet *)values;
- (void)removeUpvoted:(NSSet *)values;

@end
