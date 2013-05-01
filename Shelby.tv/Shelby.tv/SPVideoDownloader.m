//
//  SPVideoDownloader.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 2/25/13.
//  Copyright (c) 2013 Shelby TV. All rights reserved.
//

#import "SPVideoDownloader.h"

@interface SPVideoDownloader ()

//djs
//@property (weak, nonatomic) AppDelegate *appDelegate;
@property (nonatomic) Video *video;

@end

@implementation SPVideoDownloader

#pragma mark - Initialization

- (id)initWithVideo:(Video *)video;
{
    self = [super init];
    if (self) {
        //djs we should be handed a video that we can use
        _video = video;
//        _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
//        
//        NSManagedObjectContext *context = [self.appDelegate context];
//        NSManagedObjectID *objectID = [video objectID];
//        _video = (Video *)[context existingObjectWithID:objectID error:nil];
    }
    
    return self;
}

#pragma mark - Instance Methods (Public)
- (void)startDownloading
{

//    djs this is very fucked up... we should not retain outselves... doesn't somebody love us enough to retain us???
//    // Retain this SPVideoDownloader instance 
//    [self.appDelegate addVideoDownloader:self];

//    djs also fucked up... our video should be okay to use
//    NSManagedObjectContext *context = [self.appDelegate context];
//    NSManagedObjectID *objectID = [self.video objectID];
//    self.video = (Video *)[context existingObjectWithID:objectID error:nil];
    
    if ( ![self.video offlineURL] ) { // Download video if not already stored.

        // Create videoFilename string
        NSString *videoFilename = [NSString stringWithFormat:@"%@.mp4", _video.videoID];
        
        // Perform request
        NSURL *requestURL = [NSURL URLWithString:_video.extractedURL];
        NSURLRequest *request = [[NSURLRequest alloc] initWithURL:requestURL];
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        
        [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
            
            if ( [data length] && !error ) {
                
                // Reference Cache Path
                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                NSFileManager *fileManager = [[NSFileManager alloc] init];
                [fileManager createDirectoryAtPath:[paths objectAtIndex:0]
                       withIntermediateDirectories:YES
                                        attributes:nil
                                             error:nil];
                
                // Write video to path
                NSString *documentsDirectory = [paths objectAtIndex:0];
                NSString *path = [documentsDirectory stringByAppendingPathComponent:videoFilename];
                [data writeToFile:path atomically:YES];
                
                // Store offlineURL path
//                djs don't need to store the offline path, if the path is deterministic
//                  just need to get/set path via a class method of SPVideoDownloader (and/or OfflineVideoManager)
//                NSManagedObjectContext *asyncContext = [self.appDelegate context];
//                NSManagedObjectID *asyncObjectID = [self.video objectID];
//                Video *asyncVideo = (Video *)[asyncContext existingObjectWithID:asyncObjectID error:nil];
//                asyncVideo.offlineURL = path;
//                
//                // Save modified video object to CoreData store
//                CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_VideoDownloaded];
//                [dataUtility saveContext:asyncContext];

                dispatch_async(dispatch_get_main_queue(), ^{

                    // Present local notification
//                    NSManagedObjectContext *notificationContext = [self.appDelegate context];
//                    NSManagedObjectID *objectID = [self.video objectID];
//                    Video *notificationVideo = (Video *)[notificationContext existingObjectWithID:objectID error:nil];

                    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
                    UIDatePicker *datePicker = [[UIDatePicker alloc] init];
                    localNotification.fireDate = [[datePicker date] dateByAddingTimeInterval:60];
                    localNotification.soundName = UILocalNotificationDefaultSoundName;
                    localNotification.alertAction = @"Finished Downloading Video!";
                    // djs adjusted to use the video we were given, not something pulled from a context
                    localNotification.alertBody = [NSString stringWithFormat:@"The video '%@' has been downloaded and cached.", self.video.title];
                    localNotification.hasAction = YES;
                    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];

                });
                
                //djs adjusted to use video we were given
                DLog(@"Video (%@) downloaded to location: %@", self.video.title, path);

//                djs not how we do memory management...
//                // Release this SPVideoDownloader instance
//                [self.appDelegate removeVideoDownloader:self];
                
            }
        }];
        
    } else { // Do nothing if video previously downloaded
        
        DLog(@"Video was previously downloaded.");

        // djs not how we do mem mgt...
//        // Release this SPVideoDownloader instance
//        [self.appDelegate removeVideoDownloader:self];
    }
    
}

- (void)deleteDownloadedVideo
{
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // Reference Filename
//        djs no need to pull video from context
//        NSManagedObjectContext *context = [self.appDelegate context];
//        NSManagedObjectID *objectID = [self.video objectID];
//        self.video = (Video *)[context existingObjectWithID:objectID error:nil];
        NSString *storedFilename = [NSString stringWithFormat:@"%@.mp4", _video.videoID];
        
        // Reference Cache Path
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *path = [documentsDirectory stringByAppendingPathComponent:storedFilename];
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        
        // Remove video
        [fileManager removeItemAtPath:path error:nil];
        
    });
}


#pragma mark - Class Methods (Public)
+ (void)deleteAllDownloadedVideos
{
    
    // Call this method AFTER emptying Core Data store
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    
        // Reference Cache Path
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        NSArray *contents = [fileManager contentsOfDirectoryAtPath:documentsDirectory error:NULL];
       
        // Empty entire cache
        for (NSString *string in contents) {
            
            NSString *path = [documentsDirectory stringByAppendingPathComponent:string];
            [fileManager removeItemAtPath:path error:nil];
            
        }
        
        DLog(@"Emptyed Downloaded Videos");
    
    });
}

+ (BOOL)canVideoBeLoadedFromDisk:(NSString *)offlineURL
{

    // Reference Cache Path
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:documentsDirectory error:NULL];
    offlineURL = [offlineURL lastPathComponent];
    
    return  ( [contents containsObject:offlineURL] ? YES : NO );

}

@end
