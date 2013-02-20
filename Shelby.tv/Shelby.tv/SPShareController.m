//
//  SPShareController.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 2/20/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import "SPShareController.h"
#import "SPModel.h"
#import "SPVideoPlayer.h"
#import "SPShareLikeActivity.h"
#import "SPShareRollActivity.h"

@interface SPShareController ()

@property (weak, nonatomic) SPModel *model;
@property (weak, nonatomic) SPVideoPlayer *videoPlayer;
@property (nonatomic) UIPopoverController *sharePopOverController;

@end

@implementation SPShareController

- (id)initWithVideoPlayer:(SPVideoPlayer *)videoPlayer
{
    
    if ( self = [super init] ) {
        
        self.videoPlayer = videoPlayer;
        
    }
    
    return self;
}

- (void)share
{
    
    // Reference videoFrame
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    self.model = (SPModel *)[SPModel sharedInstance];
    NSManagedObjectContext *context = [appDelegate context];
    NSManagedObjectID *objectID = [self.videoPlayer.videoFrame objectID];
    Frame *videoFrame = (Frame *)[context existingObjectWithID:objectID error:nil];
    
    // Create request for short link
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:kShelbyAPIGetShortLink, videoFrame.frameID]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];
    
    // Perform shortLink fetch and present sharePopOver (on success and fail)
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        Frame *frame = (Frame *)[context existingObjectWithID:[videoFrame objectID] error:nil];
        NSString *shareLink = [[JSON valueForKey:@"result"] valueForKey:@"short_link"];
        NSString *shareMessage = [NSString stringWithFormat:@"Watch \"%@\": %@via via @Shelby", frame.video.title, shareLink];
        
        DLog(@"Succeeded fetching link for frame: %@", shareLink);
        
        SPShareRollActivity *rollActivity = [[SPShareRollActivity alloc] init];
        SPShareLikeActivity *likeActivity = [[SPShareLikeActivity alloc] init];
        likeActivity.frameID = frame.frameID;
        likeActivity.overlayView = [self.model overlayView];
        
        UIActivityViewController *shareController = [[UIActivityViewController alloc] initWithActivityItems:@[shareMessage]
                                                                                      applicationActivities:[NSArray arrayWithObjects:likeActivity, rollActivity, nil]];
        shareController.excludedActivityTypes = @[UIActivityTypeCopyToPasteboard];
        
        
        self.sharePopOverController = [[UIPopoverController alloc] initWithContentViewController:shareController];
        [self.sharePopOverController presentPopoverFromRect:[self.model.overlayView.shareButton frame]
                                                     inView:[self.model overlayView]
                                   permittedArrowDirections:UIPopoverArrowDirectionDown
                                                   animated:YES];
        
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
        // If short link fetch failed, use full_path
        Frame *frame = (Frame *)[context existingObjectWithID:[videoFrame objectID] error:nil];
        NSString *shareLink = [NSString stringWithFormat:kShelbyAPIGetLongLink, frame.video.providerName, frame.video.providerID, frame.frameID];
        NSString *shareMessage = [NSString stringWithFormat:@"Watch \"%@\" %@ /via @Shelby", videoFrame.video.title, shareLink];
        
        DLog(@"Problem fetching link for frame: %@", videoFrame.frameID);
        DLog(@"Using full pathawesom%@", shareLink);
        
        SPShareRollActivity *rollActivity = [[SPShareRollActivity alloc] init];
        SPShareLikeActivity *likeActivity = [[SPShareLikeActivity alloc] init];
        
        UIActivityViewController *shareController = [[UIActivityViewController alloc] initWithActivityItems:@[shareMessage]
                                                                                      applicationActivities:[NSArray arrayWithObjects:likeActivity, rollActivity, nil]];
        shareController.excludedActivityTypes = @[UIActivityTypeCopyToPasteboard];
        
        self.sharePopOverController = [[UIPopoverController alloc] initWithContentViewController:shareController];
        [self.sharePopOverController presentPopoverFromRect:[self.model.overlayView.shareButton frame]
                                                     inView:[self.model overlayView]
                                   permittedArrowDirections:UIPopoverArrowDirectionDown
                                                   animated:YES];
    }];
    
    [operation start];
}

@end
