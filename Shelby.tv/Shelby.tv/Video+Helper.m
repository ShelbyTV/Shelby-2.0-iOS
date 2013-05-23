//
//  Video+Helper.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 5/2/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "Video+Helper.h"

#import "NSManagedObject+Helper.h"
#import "NSObject+NullHelper.h"

NSString * const kShelbyCoreDataEntityVideo = @"Video";
NSString * const kShelbyCoreDataEntityVideoIDPredicate = @"videoID == %@";

@implementation Video (Helper)

+ (Video *)videoForDictionary:(NSDictionary *)dict inContext:(NSManagedObjectContext *)context
{
    NSString *videoID = dict[@"id"];
    Video *video = [self fetchOneEntityNamed:kShelbyCoreDataEntityVideo
                             withIDPredicate:kShelbyCoreDataEntityVideoIDPredicate
                                       andID:videoID
                                   inContext:context];
    
    if (!video) {
        video = [NSEntityDescription insertNewObjectForEntityForName:kShelbyCoreDataEntityVideo
                                              inManagedObjectContext:context];
        video.videoID = videoID;
        video.caption = [dict[@"description"] nilOrSelfWhenNotNull];
        video.providerName = [dict[@"provider_name"] nilOrSelfWhenNotNull];
        video.providerID = [dict[@"provider_id"] nilOrSelfWhenNotNull];
        video.thumbnailURL = [dict[@"thumbnail_url"] nilOrSelfWhenNotNull];
        video.title = [dict[@"title"] nilOrSelfWhenNotNull];
        video.firstUnplayable =  [dict[@"first_unplayable_at"] nilOrSelfWhenNotNull];
        video.lastUnplayable = [dict[@"last_unplayable_at"] nilOrSelfWhenNotNull];
    }

    return video;
}


- (BOOL)isPlayable
{
    if ([self isSupportedProvider] && [self isPlayableVideo]) {
        return YES;
    }
    
    return NO;
}

- (BOOL)isSupportedProvider
{
    if ([self.providerName isEqualToString:@"youtube"] || [self.providerName isEqualToString:@"dailymotion"] || ([self.providerName isEqualToString:@"vimeo"] && [self.providerID length] >= 6)) {
        return YES;
    }
    
    return NO;
}

- (BOOL)isPlayableVideo
{
    if (self.firstUnplayable && [self.firstUnplayable longLongValue] != 0) {
        // Check if a video is marked unplayable for over 2 days
        if (self.lastUnplayable && [self.lastUnplayable longLongValue] != 0) {
            float unplayableTime = (float)([self.lastUnplayable longLongValue] - [self.firstUnplayable longLongValue]) / (1000 * 60 * 60);
            if (unplayableTime > 48) {
                return NO;
            }
        }
        
        // Check if a video was marked unplayable in the last 1 hour
        double currentSeconds = [[NSDate date] timeIntervalSince1970];
        float unplayableTimeSinceFirst = (currentSeconds - [self.lastUnplayable longLongValue] / 1000.0) / (60 * 60);
        if (unplayableTimeSinceFirst < 1) {
            return NO;
        }
    }
    
    return YES;
}

- (Video *)containedVideo
{
    return self;
}

@end
