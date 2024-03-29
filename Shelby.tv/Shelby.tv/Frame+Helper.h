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

//KVO
extern NSString * const kFramePathClientLikedAt;
extern NSString * const kFramePathUpvoters;

typedef NS_ENUM(NSInteger, FrameType){
    //traditional shares
    FrameTypeHeavyWeight,
    //new "like" shares (without comment)
    FrameTypeLightWeight
};

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

//also checks that clientUnliked is not YES
+ (BOOL)doesLikedFrameWithVideoID:(NSString *)videoID
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
- (BOOL)isNotification;

- (BOOL)doLike;
- (BOOL)doUnlike;

//Is this frame, or another with same video, on the likes roll
//of the current user.  Or has it been offline liked.
- (BOOL)videoIsLikedBy:(User *)user;
//this is slower, it needs to fetch current user
- (BOOL)videoIsLikedByCurrentUser;

// The fallback when shortlinking fails
- (NSString *)longLink;

- (FrameType)typeOfFrame;

@end
