//
//  Video+Helper.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 5/2/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "Video+Helper.h"

@implementation Video (Helper)

+ (Video *)videoForDictionary:(NSDictionary *)dict inContext:(NSManagedObjectContext *)context
{
    //look for existing Video
    NSString *videoID = dict[@"id"];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kShelbyCoreDataEntityVideo];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"videoID == %@", videoID];
    request.predicate = pred;
    request.fetchLimit = 1;
    NSError *error;
    NSArray *fetchedVideos = [context executeFetchRequest:request error:&error];
    if(error || !fetchedVideos){
        return nil;
    }
    
    Video *video = nil;
    if([fetchedVideos count] == 1){
        video = fetchedVideos[0];
    } else {
        video = [NSEntityDescription insertNewObjectForEntityForName:kShelbyCoreDataEntityVideo
                                              inManagedObjectContext:context];
        video.videoID = videoID;
        video.caption = OBJECT_OR_NIL(dict[@"description"]);
        video.providerName = dict[@"provider_name"];
        video.providerID = dict[@"provider_id"];
        video.thumbnailURL = dict[@"thumbnail_url"];
        video.title = dict[@"title"];
        video.firstUnplayable =  OBJECT_OR_NIL(dict[@"first_unplayable_at"]);
        video.lastUnplayable = OBJECT_OR_NIL(dict[@"last_unplayable_at"]);
 
        if (![Video isSupportedProviderName:video.providerName andID:video.providerID] ||
            ![Video isPlayableVideo:video.firstUnplayable andLastUnplayable:video.lastUnplayable]) {
            [context deleteObject:video];
            return nil;
        }
    }

    return video;
}

+ (BOOL)isSupportedProviderName:(NSString *)providerName andID:(NSString *)providerID
{
    if ([providerName isEqualToString:@"youtube"] || [providerName isEqualToString:@"dailymotion"] || ([providerName isEqualToString:@"vimeo"] && [providerID length] >= 6)) {
        return YES;
    }
    
    return NO;
}

+ (BOOL)isPlayableVideo:(NSNumber *)firstUnplayable andLastUnplayable:(NSNumber *)lastUnplayable
{
    if (firstUnplayable && [firstUnplayable longLongValue] != 0) {
        // Check if a video is marked unplayable for over 2 days
        if (lastUnplayable && [lastUnplayable longLongValue] != 0) {
            float unplayableTime = (float)([lastUnplayable longLongValue] - [firstUnplayable longLongValue]) / (1000 * 60 * 60);
            if (unplayableTime > 48) {
                return NO;
            }
        }
        
        // Check if a video was marked unplayable in the last 1 hour
        double currentSeconds = [[NSDate date] timeIntervalSince1970];
        float unplayableTimeSinceFirst = (currentSeconds - [lastUnplayable longLongValue] / 1000.0) / (60 * 60);
        if (unplayableTimeSinceFirst < 1) {
            return NO;
        }
    }
    
    return YES;
}

@end
