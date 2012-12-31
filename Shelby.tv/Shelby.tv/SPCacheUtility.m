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
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            CoreDataUtility *asyncDataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_StoreVideoInCache];
            NSManagedObjectContext *asyncContext = [asyncDataUtility context];
            Frame *asyncVideoFrame = (Frame*)[asyncContext existingObjectWithID:[self.videoFrame objectID] error:nil];
            
            // Change test on button and disable button
            [self.overlayView.downloadButton setImage:[UIImage imageNamed:@"downloadButtonCaching"] forState:UIControlStateNormal];
            [self.overlayView.downloadButton setEnabled:NO];
            
            // Create videoFilename string
            NSString *videoFilename = [NSString stringWithFormat:@"%@-%@.mp4", asyncVideoFrame.video.providerID, asyncVideoFrame.video.title];
            
            // Perform request
            NSURLResponse *response = nil;
            NSError *requestError = nil;
            NSURL *requestURL = [NSURL URLWithString:asyncVideoFrame.video.extractedURL];
            NSURLRequest *request = [[NSURLRequest alloc] initWithURL:requestURL];
            NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&requestError];
            
            if ( requestError ) {
                
                DLog(@"Response %@", response);
                DLog(@"Request Error %@", requestError);
            }
            
            // Reference Cache Path
            NSError *fileManagerError = nil;
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSFileManager *fileManager = [NSFileManager defaultManager];
            [fileManager createDirectoryAtPath:[paths objectAtIndex:0]
                   withIntermediateDirectories:YES
                                    attributes:nil
                                         error:&fileManagerError];
            
            if ( fileManagerError ) {
                
                DLog(@"FileManager Error %@", requestError);
            }
            
            // Write video to path
            NSError *fileWriteError = nil;
            NSString *documentsDirectory = [paths objectAtIndex:0];
            NSString *path = [documentsDirectory stringByAppendingPathComponent:videoFilename];
            [data writeToFile:path atomically:YES];
            
            DLog(@"Video Cached at Location: %@", path);
            
            if ( fileWriteError ) {
                
                DLog(@"File Write Error %@", requestError);
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
            CoreDataUtility *syncDataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_StoreVideoInCache];
            NSManagedObjectContext *syncContext = [syncDataUtility context];
            Frame *syncVideoFrame = (Frame*)[syncContext existingObjectWithID:[self.videoFrame objectID] error:nil];
            
            syncVideoFrame.video.cachedURL = path;
            syncVideoFrame.isCached = [NSNumber numberWithBool:YES];
            [syncDataUtility saveContext:syncContext];
                
               self.videoPlayer.isDownloading = NO;
                
                if ( self.videoPlayer == self.videoReel.currentVideoPlayer ) { // If the currently displayed video is the one being downloaded
                    
                    // Change text on downloadButton and make sure button stays disabled
                    [self.overlayView.downloadButton setEnabled:YES];
                    [self.overlayView.downloadButton setImage:[UIImage imageNamed:@"downloadButtonRemove"] forState:UIControlStateNormal];
                    [self.overlayView.downloadButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
                    [self.overlayView.downloadButton addTarget:self.videoPlayer action:@selector(removeFromCache) forControlEvents:UIControlEventTouchUpInside];
                    
                    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
                    UIDatePicker *datePicker = [[UIDatePicker alloc] init];
                    localNotification.fireDate = [[datePicker date] dateByAddingTimeInterval:5];
                    localNotification.soundName = UILocalNotificationDefaultSoundName;
                    localNotification.alertAction = @"Finished Downloading Video!";
                    localNotification.alertBody = [NSString stringWithFormat:@"The video '%@' has been downloaded and cached.", syncVideoFrame.video.title];
                    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
                }
                
            });
        });
    }
}

- (void)removeVideoFrame:(Frame *)videoFrame fromVideoPlayer:(SPVideoPlayer *)videoPlayer inReel:(SPVideoReel *)videoReel
{
    
    self.videoFrame = videoFrame;
    self.videoPlayer = videoPlayer;
    self.videoReel = videoReel;
    self.overlayView = videoReel.overlayView;
    
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
    
    DLog(@"%@", contents);
    
    for (NSString *string in contents) {

        if ( [string isEqualToString:storedFilename] ) {
            
            NSError *error = nil;
            [fileManager removeItemAtPath:path error:&error];
            
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
                    
                }
                
            });
            
            DLog(@"Cache Video Removal Error: %@", error);
        }
        
    }
    
}

@end