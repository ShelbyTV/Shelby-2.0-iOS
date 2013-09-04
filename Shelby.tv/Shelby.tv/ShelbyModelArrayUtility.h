//
//  ShelbyModelArrayUtility.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 9/3/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//
//  Designed to help when merging newly obtained model objects (ie. from the API)
//  with a given existing set.  Use the factory method
//  determineHowToMergePossiblyNew:intoExisting: to create a new utility
//  and have it immediately determine how to merge in the new array.
//  Then use the properies actuallyNewEntities and actuallyNewEntitiesShouldBeAppended
//  to begin merging the new stuff.
//
//  Object equality per isEqual: which is based on objectID for NSManagedObjects
//
//  *Does not consider duplicates*

#import <Foundation/Foundation.h>

@interface ShelbyModelArrayUtility : NSObject

//arrays must not be nil, may be empty
//all array elements must responsd to @selector(shelbyID)
+ (id)determineHowToMergePossiblyNew:(NSArray *)possiblyNewEntities intoExisting:(NSArray *)existingEntities;

//use these properties to access the results of the merge computation
@property (readonly) NSArray *actuallyNewEntities;
@property (readonly) BOOL actuallyNewEntitiesShouldBeAppended;

@end
