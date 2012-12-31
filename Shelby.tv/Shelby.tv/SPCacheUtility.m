//
//  SPCacheUtility.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 12/26/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import "SPCacheUtility.h"
#import "SPOverlayView.h"
#import "SPVideoPlayer.h"
#import "SPVideoReel.h"

@interface SPCacheUtility ()

@property (strong, nonatomic) Frame *videoFrame;
@property (strong, nonatomic) SPOverlayView *overlayView;
@property (strong, nonatomic) SPVideoPlayer *videoPlayer;
@property (strong, nonatomic) SPVideoReel *videoReel;

@end

@implementation SPCacheUtility
@synthesize videoFrame = _videoFrame;
@synthesize overlayView = _overlayView;
@synthesize videoPlayer = _videoPlayer;
@synthesize videoReel = _videoReel;

#pragma mark - Public Class Methods
+ (void)emptyCache
{
    // Reference Cache Path
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:NULL];
    
    for (NSString *string in contents) {
        
        NSString *path = [documentsDirectory stringByAppendingPathComponent:string];
        [fileManager removeItemAtPath:path error:nil];
        
    }
    
    DLog(@"Emptyed Cached Videos");
}

#pragma mark - Public Instance Methods
- (void)addVideoFrame:(Frame *)videoFrame fromVideoPlayer:(SPVideoPlayer *)videoPlayer inReel:(SPVideoReel *)videoReel
{
    
    self.videoFrame = videoFrame;
    
    self.videoPlayer = videoPlayer;
    self.videoPlayer.isDownloading = YES;
    
    self.videoReel = videoReel;
    self.overlayView = videoReel.overlayView;
    
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_StoreVideoInCache];
    NSManagedObjectContext *context = [dataUtility context];
    self.videoFrame = (Frame*)[context existingObjectWithID:[self.videoFrame objectID] error:nil];
    
    if ( _videoFrame.video.extractedURL ) {

            // Change test on button and disable button
            [self.overlayView.downloadButton setImage:[UIImage imageNamed:@"downloadButtonCaching"] forState:UIControlStateNormal];
            [self.overlayView.downloadButton setEnabled:NO];
            
            // Create videoFilename string
            NSString *videoFilename = [NSString stringWithFormat:@"%@-%@.mp4", _videoFrame.video.providerID, _videoFrame.video.title];
            
            // Perform request
            NSURL *requestURL = [NSURL URLWithString:_videoFrame.video.extractedURL];
            NSURLRequest *request = [[NSURLRequest alloc] initWithURL:requestURL];
            NSOperationQueue *queue = [[NSOperationQueue alloc] init];
            
            [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                
                if ( data && !error ) {
                    
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

                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        CoreDataUtility *syncDataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_ActionUpdate];
                        NSManagedObjectContext *syncContext = [syncDataUtility context];
                        Frame *syncVideoFrame = (Frame*)[syncContext existingObjectWithID:[self.videoFrame objectID] error:nil];
                        
                        syncVideoFrame.video.cachedURL = path;
                        syncVideoFrame.isCached = [NSNumber numberWithBool:YES];
                        [syncDataUtility saveContext:syncContext];
                        
                        DLog(@"Video Cached at Location: %@", path);
                        self.videoPlayer.isDownloading = NO;
                        
                        if ( self.videoPlayer == self.videoReel.currentVideoPlayer ) { // If the currently displayed video is the one being downloaded
                            
                            // Change text on downloadButton and make sure button stays disabled
                            [self.overlayView.downloadButton setEnabled:YES];
                            [self.overlayView.downloadButton setImage:[UIImage imageNamed:@"downloadButtonRemove"] forState:UIControlStateNormal];
                            [self.overlayView.downloadButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
                            [self.overlayView.downloadButton addTarget:self.videoPlayer action:@selector(removeFromCache) forControlEvents:UIControlEventTouchUpInside];
                            
                            UILocalNotification *localNotification = [[UILocalNotification alloc] init];
                            UIDatePicker *datePicker = [[UIDatePicker alloc] init];
                            localNotification.fireDate = [[datePicker date] dateByAddingTimeInterval:60];
                            localNotification.soundName = UILocalNotificationDefaultSoundName;
                            localNotification.alertAction = @"Finished Downloading Video!";
                            localNotification.alertBody = [NSString stringWithFormat:@"The video '%@' has been downloaded and cached.", syncVideoFrame.video.title];
                            localNotification.hasAction = YES;
                            [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];

                        };
                    });
                }
            }];
    }
}

- (void)removeVideoFrame:(Frame *)videoFrame fromVideoPlayer:(SPVideoPlayer *)videoPlayer inReel:(SPVideoReel *)videoReel
{
    
    self.videoFrame = videoFrame;
    self.videoPlayer = videoPlayer;
    self.videoReel = videoReel;
    self.overlayView = videoReel.overlayView;
    
    [self.videoPlayer pause];
    
    // Reference Filename
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_ActionUpdate];
    NSManagedObjectContext *context = [dataUtility context];
    self.videoFrame = (Frame*)[context existingObjectWithID:[self.videoFrame objectID] error:nil];
    NSString *storedFilename = [NSString stringWithFormat:@"%@-%@.mp4", _videoFrame.video.providerID, _videoFrame.video.title];
    
    // Reference Cache Path
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:storedFilename];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:NULL];
    
    DLog(@"Cached Objects: %@", contents);
    
    for (NSString *string in contents) {

        if ( [string isEqualToString:storedFilename] ) {
            
            [fileManager removeItemAtPath:path error:nil];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                // Remove path from Core Data
                CoreDataUtility *syncDataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_StoreVideoInCache];
                NSManagedObjectContext *syncContext = [syncDataUtility context];
                Frame *syncVideoFrame = (Frame*)[syncContext existingObjectWithID:[self.videoFrame objectID] error:nil];
                
                syncVideoFrame.video.cachedURL = [NSString coreDataNullTest:nil];
                syncVideoFrame.isCached = [NSNumber numberWithBool:NO];
                [dataUtility saveContext:syncContext];
                
                if ( self.videoPlayer == self.videoReel.currentVideoPlayer ) { // If the currently displayed video is the one being downloaded
                    
                    // Change text on downloadButton and make sure button stays disabled
                    [self.overlayView.downloadButton setImage:[UIImage imageNamed:@"downloadButtonCache"] forState:UIControlStateNormal];
                    [self.overlayView.downloadButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
                    [self.overlayView.downloadButton addTarget:self.videoPlayer action:@selector(addToCache) forControlEvents:UIControlEventTouchUpInside];
                    
                    // To avoid crashes in Cached Videos SPVideoReel instance, remove the instance once the video is removed from cache. 
                    if ( self.videoReel.categoryType == CategoryType_Cached ) {
                        
                        [self.videoReel homeButtonAction:nil];
                        
                    }
                    
                }
                
            });
        }
    }
}

@end