//
//  DashboardEntry+Helper.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 5/2/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "DashboardEntry+Helper.h"

#import "Frame+Helper.h"
#import "NSManagedObject+Helper.h"

NSString * const kShelbyCoreDataEntityDashboardEntry = @"DashboardEntry";
NSString * const kShelbyCoreDataEntityDashboardEntryIDPredicate = @"dashboardEntryID == %@";

@implementation DashboardEntry (Helper)

@dynamic duplicateOf;
@dynamic duplicates;

+ (DashboardEntry *)dashboardEntryForDictionary:(NSDictionary *)dict
                                  withDashboard:(Dashboard *)dashboard
                                      inContext:(NSManagedObjectContext *)context
{
    NSString *dashboardEntryID = dict[@"id"];
    DashboardEntry *dashboardEntry = [self fetchOneEntityNamed:kShelbyCoreDataEntityDashboardEntry
                                               withIDPredicate:kShelbyCoreDataEntityDashboardEntryIDPredicate
                                                         andID:dashboardEntryID
                                                     inContext:context];
    
    if (!dashboardEntry) {
        dashboardEntry = [NSEntityDescription insertNewObjectForEntityForName:kShelbyCoreDataEntityDashboardEntry
                                                       inManagedObjectContext:context];
        dashboardEntry.dashboardEntryID = dashboardEntryID;
        dashboardEntry.dashboard = dashboard;
    }

    //NB: intentionally not duplicating timestamp out of BSON id
    NSDictionary *frameDict = dict[@"frame"];
    if([frameDict isKindOfClass:[NSDictionary class]]){
        dashboardEntry.frame = [Frame frameForDictionary:frameDict inContext:context];
    }
    if (!dashboardEntry.frame) {
        [context deleteObject:dashboardEntry];
        return nil;
    }
    NSString *action = dict[@"action"];
    if (action) {
        dashboardEntry.action = @([action intValue]);
//        DLog(@"action: %@/%@", action, dashboardEntry.action);
//        if ([dashboardEntry typeOfEntry] == (DashboardEntryTypeVideoGraphRecommendation | DashboardEntryTypeEntertainmentGraphRecommendation)) {
//            DLog(@"RECO!");
//        }
//        if ([dashboardEntry typeOfEntry] == DashboardEntryTypeEntertainmentGraphRecommendation) {
//            DLog(@"--RECO A!");
//        }
//        if ([dashboardEntry typeOfEntry] == DashboardEntryTypeVideoGraphRecommendation) {
//            DLog(@"--RECO B!");
//        }
    }
    
    return dashboardEntry;
}

+ (NSArray *)entriesForDashboard:(Dashboard *)dashboard inContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kShelbyCoreDataEntityDashboardEntry];
    NSPredicate *entriesInDashboard = [NSPredicate predicateWithFormat:@"dashboard == %@", dashboard];
    request.predicate = entriesInDashboard;
    //Mongo IDs are prefixed with timestamp, so this gives us reverse-chron
    NSSortDescriptor *sortById = [NSSortDescriptor sortDescriptorWithKey:@"dashboardEntryID" ascending:NO];
    request.sortDescriptors = @[sortById];
    
    NSError *err;
    NSArray *results = [context executeFetchRequest:request error:&err];
    STVAssert(!err, @"couldn't fetch dashboard entries!");
    return results;
}

- (BOOL)isPlayable
{
    if (self.frame) {
        return [self.frame isPlayable];
    }
    
    return NO;
}

- (DashboardEntryType)typeOfEntry
{
    //From API business logic model: dashboard_entry.rb
    switch ([self.action intValue]) {
        case 0:
            return DashboardEntryTypeSocialFrame;
        case 1:
            return DashboardEntryTypeBookmarkFrame;
        case 2:
            return DashboardEntryTypeInAppFrame;
        case 3:
            return DashboardEntryTypeGeniusFrame;
        case 4:
            return DashboardEntryTypeHashtagFrame;
        case 5:
            return DashboardEntryTypeEmailHookFrame;
        case 6:
            return DashboardEntryTypeCommunityFrame;
        case 8:
            return DashboardEntryTypeReRoll;
        case 9:
            return DashboardEntryTypeWatch;
        case 10:
            return DashboardEntryTypeComment;
        case 30:
            return DashboardEntryTypePrioritizedFrame;
        case 31:
            return DashboardEntryTypeVideoGraphRecommendation;
        case 32:
            return DashboardEntryTypeEntertainmentGraphRecommendation;
        default:
            return DashboardEntryTypeSocialFrame;
    }
}

- (NSString *)shelbyID
{
    return self.dashboardEntryID;
}

- (Video *)containedVideo
{
    return self.frame.video;
}

@end
