//
//  SPVideoDownloader.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 2/25/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import "SPVideoDownloader.h"
#import "SPVideoPlayer.h"

@interface SPVideoDownloader ()

@property (weak, nonatomic) AppDelegate *appDelegate;
@property (nonatomic) Video *video;
@property (nonatomic) SPVideoPlayer *player;

@end

@implementation SPVideoDownloader

#pragma mark - Initialization

- (id)initWithVideo:(Video *)video inPlayer:(SPVideoPlayer *)player
{
    
    if ( self = [super init] ) {
        
        
        self.appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        self.player = player;
        
        NSManagedObjectContext *context = [self.appDelegate context];
        NSManagedObjectID *objectID = [video objectID];
        self.video = (Video *)[context existingObjectWithID:objectID error:nil];
        
        
    }
    
    return self;
}

#pragma mark - Instance Methods (Public)
- (void)downloadVideo
{

    NSManagedObjectContext *context = [self.appDelegate context];
    NSManagedObjectID *objectID = [self.video objectID];
    self.video = (Video *)[context existingObjectWithID:objectID error:nil];
    
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
                NSManagedObjectContext *asyncContext = [self.appDelegate context];
                NSManagedObjectID *asyncObjectID = [self.video objectID];
                Video *video = (Video *)[asyncContext existingObjectWithID:asyncObjectID error:nil];
                video.offlineURL = path;
                
                // Save modified video object to CoreData store
                CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_ActionUpdate];
                [dataUtility saveContext:asyncContext];

                dispatch_async(dispatch_get_main_queue(), ^{

                    // Present local notification
                    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
                    UIDatePicker *datePicker = [[UIDatePicker alloc] init];
                    localNotification.fireDate = [[datePicker date] dateByAddingTimeInterval:60];
                    localNotification.soundName = UILocalNotificationDefaultSoundName;
                    localNotification.alertAction = @"Finished Downloading Video!";
                    localNotification.alertBody = [NSString stringWithFormat:@"The video '%@' has been downloaded and cached.", video.title];
                    localNotification.hasAction = YES;
                    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];

                });
                
                DLog(@"Video stored at Location: %@", path);
                
            }
        }];
        
    } else { // Do nothing if video previously downloaded
        
        DLog(@"Video was previously cached.");
    }
    
}

- (void)deleteDownloadedVideo
{
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // Reference Filename
        NSManagedObjectContext *context = [self.appDelegate context];
        NSManagedObjectID *objectID = [self.video objectID];
        self.video = (Video *)[context existingObjectWithID:objectID error:nil];
        NSString *storedFilename = [NSString stringWithFormat:@"%@.mp4", _video.videoID];
        
        // Reference Cache Path
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *path = [documentsDirectory stringByAppendingPathComponent:storedFilename];
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        NSArray *contents = [fileManager contentsOfDirectoryAtPath:documentsDirectory error:NULL];
        
        // Remove video
        [fileManager removeItemAtPath:path error:nil];
        
        DLog(@"Cached Objects: %@", contents);
        
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
        
        DLog(@"Emptyed Cached Videos");
    
    });
}

+ (void)listAllVideos
{
 
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // Reference Cache Path
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        NSArray *contents = [fileManager contentsOfDirectoryAtPath:documentsDirectory error:NULL];
        DLog(@"Directory: %@", documentsDirectory);
        DLog(@"Contents: %@", contents);
        
    });
}

@end
