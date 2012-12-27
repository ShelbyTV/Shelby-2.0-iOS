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

@interface SPCacheUtility ()

@property (strong, nonatomic) Frame *videoFrame;
@property (strong, nonatomic) SPOverlayView *overlayView;
@property (strong, nonatomic) SPVideoPlayer *videoPlayer;

@end

@implementation SPCacheUtility
@synthesize videoFrame = _videoFrame;
@synthesize overlayView = _overlayView;
@synthesize videoPlayer = _videoPlayer;

#pragma mark - Singleton Methods
static SPCacheUtility *sharedInstance = nil;

+ (SPCacheUtility *)sharedInstance
{
    if (sharedInstance == nil) {
        sharedInstance = [[super allocWithZone:NULL] init];
    }
    return sharedInstance;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [self sharedInstance];
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

#pragma mark - Public Methods
- (void)addVideoFrame:(Frame *)videoFrame fromVideoPlayer:(SPVideoPlayer *)videoPlayer inOverlay:(SPOverlayView *)overlayView
{
    
    self.videoFrame = videoFrame;
    self.overlayView = overlayView;
    self.videoPlayer = videoPlayer;
    
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_StoreVideoInCache];
    NSManagedObjectContext *context = [dataUtility context];
    self.videoFrame = (Frame*)[context existingObjectWithID:[self.videoFrame objectID] error:nil];
    
    if ( _videoFrame.video.extractedURL ) {
        
        // Change test on button and disable button
        [self.overlayView.downloadButton setTitle:@"Caching..." forState:UIControlStateNormal];
        [self.overlayView.downloadButton setEnabled:NO];
        
        // Create videoFilename string
        NSString *videoFilename = [NSString stringWithFormat:@"%@-%@.mp4", _videoFrame.video.providerID, _videoFrame.video.title];
        
        // Perform request
        NSURLResponse *response = nil;
        NSError *requestError = nil;
        NSURL *requestURL = [NSURL URLWithString:_videoFrame.video.extractedURL];
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
        [data writeToFile:path options:0 error:&fileWriteError];
        
        DLog(@"Video Cached at Location: %@", path);
        
        if ( fileWriteError ) {
            
            DLog(@"File Write Error %@", requestError);
        }
        
        // Store path in Core Data
        self.videoFrame.video.cachedURL = path;
        self.videoFrame.isCached = [NSNumber numberWithBool:YES];
        [dataUtility saveContext:context];
        
        // Change text on downloadButton and make sure button stays disabled
        [self.overlayView.downloadButton setTitle:@"Remove" forState:UIControlStateNormal];
        [self.overlayView.downloadButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
        [self.overlayView.downloadButton addTarget:self action:@selector(removeVideoFrameFromCache) forControlEvents:UIControlEventTouchUpInside];
        
    }
}

- (void)removeVideoFrame:(Frame *)videoFrame fromVideoPlayer:(SPVideoPlayer *)videoPlayer inOverlay:(SPOverlayView *)overlayView
{
    
    self.videoFrame = videoFrame;
    self.overlayView = overlayView;
    self.videoPlayer = videoPlayer;
    
    // Reference Filename
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_StoreVideoInCache];
    NSManagedObjectContext *context = [dataUtility context];
    self.videoFrame = (Frame*)[context existingObjectWithID:[self.videoFrame objectID] error:nil];
    NSString *storedFilename = [NSString stringWithFormat:@"%@-%@.mp4", _videoFrame.video.providerID, _videoFrame.video.title];
    
    // Reference Cache Path
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:storedFilename];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:NULL];
    
    for (NSString *string in contents) {

        if ( [string isEqualToString:storedFilename] ) {
            
            NSError *error = nil;
            [fileManager removeItemAtPath:path error:&error];
            
            // Remove path from Core Data
            self.videoFrame.video.cachedURL = [NSString coreDataNullTest:nil];
            self.videoFrame.isCached = [NSNumber numberWithBool:NO];
            [dataUtility saveContext:context];
            
            // Change text on downloadButton and make sure button stays disabled
            [self.overlayView.downloadButton setTitle:@"Download" forState:UIControlStateNormal];
            [self.overlayView.downloadButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [self.overlayView.downloadButton addTarget:self action:@selector(removeVideoFrameFromCache) forControlEvents:UIControlEventTouchUpInside];
            
            
            DLog(@"Cache Video Removal Error: %@", error);
        }
        
    }
    
}

@end