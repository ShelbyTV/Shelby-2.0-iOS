//
//  Frame+Helper.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 4/25/13.
//  Copyright (c) 2013 Shelby TV. All rights reserved.
//

#import "Frame.h"
#import "ShelbyModel.h"
#import "ShelbyDuplicateContainer.h"
#import "ShelbyVideoContainer.h"

@interface Frame (Helper) <ShelbyModel, ShelbyDuplicateContainer, ShelbyVideoContainer>

+ (Frame *)frameForDictionary:(NSDictionary *)dict
               requireCreator:(BOOL)mustHaveCreator
                    inContext:(NSManagedObjectContext *)context;

//sorted in reverse-chron
+ (NSArray *)framesForRoll:(Roll *)roll
                 inContext:(NSManagedObjectContext *)moc;

+ (NSArray *)fetchAllLikesInContext:(NSManagedObjectContext *)context;

+ (BOOL)doesFrameWithVideoID:(NSString *)videoID
           existOnRollWithID:(NSString *)rollID
                   inContext:(NSManagedObjectContext *)moc;

+ (Frame *)frameWithVideoID:(NSString *)videoID
               onRollWithID:(NSString *)rollID
                  inContext:(NSManagedObjectContext *)moc;

//returns the Frame for a DashboardEntry or Frame in disguise
+ (Frame *)frameForEntity:(id<ShelbyVideoContainer>)entity;

- (NSString *)creatorsInitialCommentWithFallback:(BOOL)canUseVideoTitle;
- (NSString *)originNetwork;
- (BOOL)isPlayable;
//returns YES if the toggle should result in this frame being liked
- (BOOL)toggleLike;

//Is this frame, or another with same video, on the likes roll
//of the current user.  Or has it been offline liked.
- (BOOL)videoIsLiked;

// The fallback when shortlinking fails
- (NSString *)longLink;

@end
