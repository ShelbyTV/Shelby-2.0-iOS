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
    }

    return video;
}

@end
