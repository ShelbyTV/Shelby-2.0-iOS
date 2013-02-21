//
//  SPShareController.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 2/20/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import "SPShareController.h"
#import "SPModel.h"
#import "SPShareRollView.h"
#import "SPShareLikeActivity.h"
#import "SPShareRollActivity.h"

@interface SPShareController ()

@property (weak, nonatomic) SPModel *model;
@property (weak, nonatomic) SPVideoPlayer *videoPlayer;
@property (nonatomic) SPShareRollView *rollView;
@property (nonatomic) UIPopoverController *sharePopOverController;
@property (assign, nonatomic) BOOL facebookConnected;
@property (assign, nonatomic) BOOL twitterConnected;

/// Setup Methods
- (void)setupSocialConnectionStatuses;

/// UI Methods
- (void)toggleSocialButtonStatesOnLaunch;

@end

#pragma mark - Initialization
@implementation SPShareController

- (id)initWithVideoPlayer:(SPVideoPlayer *)videoPlayer
{
    
    if ( self = [super init] ) {
        
        self.videoPlayer = videoPlayer;
        
        [self setupSocialConnectionStatuses];
        
    }
    
    return self;
}

#pragma mark - Setup Methods
- (void)setupSocialConnectionStatuses
{
    
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    User *user = [dataUtility fetchUser];
    
    self.facebookConnected = [[user facebookConnected] boolValue];
    self.twitterConnected = [[user twitterConnected] boolValue];
    
}

#pragma mark - UI Methods (Public)
- (void)share
{
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
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
            rollActivity.shareController = self;
            
            SPShareLikeActivity *likeActivity = [[SPShareLikeActivity alloc] init];
            likeActivity.frameID = frame.frameID;
            likeActivity.overlayView = [self.model overlayView];
            
            UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:@[shareMessage]
                                                                                             applicationActivities:[NSArray arrayWithObjects:likeActivity, rollActivity, nil]];
            activityController.excludedActivityTypes = @[UIActivityTypeCopyToPasteboard];
            
            
            self.sharePopOverController = [[UIPopoverController alloc] initWithContentViewController:activityController];
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
            
            UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:@[shareMessage]
                                                                                             applicationActivities:[NSArray arrayWithObjects:likeActivity, rollActivity, nil]];
            activityController.excludedActivityTypes = @[UIActivityTypeCopyToPasteboard];
            
            self.sharePopOverController = [[UIPopoverController alloc] initWithContentViewController:activityController];
            [self.sharePopOverController presentPopoverFromRect:[self.model.overlayView.shareButton frame]
                                                         inView:[self.model overlayView]
                                       permittedArrowDirections:UIPopoverArrowDirectionDown
                                                       animated:YES];
        }];
        
        [operation start];

        
    });
    
}

- (void)showRollView
{
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SPShareRollView" owner:self options:nil];
    self.rollView = nib[0];
    
    [self toggleSocialButtonStatesOnLaunch];
    
    CGFloat xOrigin = self.videoPlayer.view.frame.size.width/4.0f - _rollView.frame.size.width/4.0f;
    CGFloat yOrigin = self.videoPlayer.view.frame.size.height/5.0f - _rollView.frame.size.height/4.0f;
    
    [self.rollView setFrame:CGRectMake(xOrigin,
                                       _videoPlayer.view.frame.size.height,
                                       _rollView.frame.size.width,
                                       _rollView.frame.size.height)];
    [self.videoPlayer.view addSubview:_rollView];
    
    [UIView animateWithDuration:0.5f
                     animations:^{
                         
                         [self.rollView setFrame:CGRectMake(xOrigin,
                                                            yOrigin,
                                                            _rollView.frame.size.width,
                                                            _rollView.frame.size.height)];
                         
                     } completion:^(BOOL finished) {
                         
                         [self.rollView.rollTextView becomeFirstResponder];
                         
                     }];
}

- (void)hideRollView
{
    
}

#pragma mark - UI Methods (Private)
- (void)toggleSocialButtonStatesOnLaunch
{
    
    ( _facebookConnected ) ? [self.rollView.facebookButton setSelected:YES] : [self.rollView.facebookButton setHidden:YES];
    ( _twitterConnected ) ? [self.rollView.twitterButton setSelected:YES] : [self.rollView.twitterButton setHidden:YES];
    
}

#pragma mark - Action Methods (Public)
- (IBAction)toggleSocialButtonStates:(id)sender
{
    
    if ( sender == _rollView.facebookButton ) {
        
        ( [self.rollView.facebookButton isSelected] ) ? [self.rollView.facebookButton setSelected:NO] : [self.rollView.facebookButton setSelected:YES];
        
    } else if ( sender == _rollView.twitterButton ) {
        
        ( [self.rollView.twitterButton isSelected] ) ? [self.rollView.twitterButton setSelected:NO] : [self.rollView.twitterButton setSelected:YES];
        
    } else {
        
        // Do nothing (condition should not be entered)

    }
    
}


#pragma mark - UITextViewDelegate Methods


@end
