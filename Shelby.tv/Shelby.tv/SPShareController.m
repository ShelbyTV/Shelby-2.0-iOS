//
//  SPShareController.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 2/20/13.
//  Copyright (c) 2013 Shelby TV. All rights reserved.
//

#import "SPShareController.h"
//djs
//#import "SPModel.h"
#import "SPShareRollView.h"
#import "SPVideoReel.h"
#import "FacebookHandler.h"
#import "TwitterHandler.h"
#import "User+Helper.h"
//djs holy shit, a file that actually should talk directly to the API client!
#import "ShelbyAPIClient.h"

//djs XXX do we need AFNEtworking in here?  Should probably just do all via API
#import "AFNetworking.h"
//djs XXX

@interface SPShareController ()

//djs
//@property (weak, nonatomic) SPModel *model;
//djs
//@property (weak, nonatomic) AppDelegate *appDelegate;
@property (weak, nonatomic) SPVideoPlayer *videoPlayer;
@property (nonatomic, assign) CGRect fromFrame;
@property (nonatomic) SPShareRollView *rollView;
@property (strong, nonatomic) UIPopoverController *sharePopOverController;
@property (assign, nonatomic) BOOL facebookConnected;
@property (assign, nonatomic) BOOL twitterConnected;
@property (strong, nonatomic) UIView *mask;

/// Setup Methods
- (void)setupMaskView;
- (void)updateFacebookToggle;
- (void)updateTwitterToggle;

/// UI Methods
- (void)toggleSocialButtonStatesOnRollViewLaunch;

/// Action Methods
- (void)shareWithFrame:(Frame *)frame message:(NSString *)message andLink:(NSString *)link;
- (void)roll;

@end

@implementation SPShareController

#pragma mark - Initialization
- (id)initWithVideoPlayer:(SPVideoPlayer *)videoPlayer
{
    self = [super init];
    if (self) {
        _videoPlayer = videoPlayer;
        //djs
//        _model = (SPModel *)[SPModel sharedInstance];
        //djs
//        _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    }
    
    return self;
}

- (id)initWithVideoPlayer:(SPVideoPlayer *)videoPlayer fromRect:(CGRect)frame
{
    self = [super init];
     if (self) {
         _videoPlayer = videoPlayer;
         _fromFrame = frame;
     }
     
     return self;
}

#pragma mark - Setup Methods
- (void)updateFacebookToggle
{
    if (self.rollView && self.rollView.facebookButton && [self.rollView.facebookButton isKindOfClass:[UIButton class]]) {
        [self.rollView.facebookButton setSelected:([[FacebookHandler sharedInstance] allowPublishActions] && self.facebookConnected)];
    }
}

- (void)updateTwitterToggle
{
    if (self.rollView && self.rollView.twitterButton && [self.rollView.twitterButton isKindOfClass:[UIButton class]]) {
        //djs TODO: probably shouldn't get our context this way, should be getting it during init
        User *user = [User currentAuthenticatedUserInContext:self.videoPlayer.videoFrame.managedObjectContext];
//        CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
//        User *user = [dataUtility fetchUser];
        BOOL connected = user.twitterConnected;
        [self.rollView.twitterButton setSelected:(connected)];
    }
}

- (void)setupMaskView
{
    
    // Reference social connection status
    if ( [[NSUserDefaults standardUserDefaults] boolForKey:kShelbyDefaultUserAuthorized] ) {
        //djs TODO: shouldn't get our context this way, should be getting it during init
        User *user = [User currentAuthenticatedUserInContext:self.videoPlayer.videoFrame.managedObjectContext];
        //        CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
        //        User *user = [dataUtility fetchUser];
        self.facebookConnected = [[user facebookConnected] boolValue];
        self.twitterConnected = [[user twitterConnected] boolValue];
        
    }
    
    CGRect videoPlayerFrame = self.videoPlayer.view.frame;
    _mask = [[UIView alloc] initWithFrame:CGRectMake(videoPlayerFrame.origin.x, videoPlayerFrame.origin.y, videoPlayerFrame.size.width, videoPlayerFrame.size.height)];
    [self.mask setBackgroundColor:[UIColor blackColor]];
    [self.mask setAlpha:0.0f];
    //djs
//    [self.model.overlayView addSubview:self.mask];
    [self.mask setUserInteractionEnabled:YES];
//    [self.model.overlayView bringSubviewToFront:self.mask];
}

#pragma mark - UI Methods (Public)
- (void)share
{
    [self setupMaskView];
    
    [UIView animateWithDuration:0.5f
                     animations:^{
                         [self.mask setAlpha:0.7];
                     }];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // Reference videoFrame
        //djs
//        self.model = (SPModel *)[SPModel sharedInstance];
//        NSManagedObjectContext *context = [self.appDelegate context];
//        NSManagedObjectID *objectID = [self.videoPlayer.videoFrame objectID];
//        Frame *videoFrame = (Frame *)[context existingObjectWithID:objectID error:nil];
//        djs just use the current video frame, it's context ought to be be fine
        Frame *videoFrame = self.videoPlayer.videoFrame;
        
        // Create request for short link
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:kShelbyAPIGetShortLink, videoFrame.frameID]];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        [request setHTTPMethod:@"GET"];
        
        // Perform shortLink fetch and present sharePopOver (on success and fail)
        AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
 
//            Frame *frame = (Frame *)[context existingObjectWithID:[videoFrame objectID] error:nil];
            //djs XXX using the videoFrame from outside these blocks... make sure that's okay
            NSString *shareLink = [[JSON valueForKey:@"result"] valueForKey:@"short_link"];
            NSString *shareMessage = [NSString stringWithFormat:@"Watch \"%@\": %@ via @Shelby", videoFrame.video.title, shareLink];
            
            DLog(@"Succeeded fetching link for frame: %@", shareLink);
            [self shareWithFrame:videoFrame message:shareMessage andLink:shareLink];
            
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
            
            // If short link fetch failed, use full_path
//            Frame *frame = (Frame *)[context existingObjectWithID:[videoFrame objectID] error:nil];
            //djs XXX using the videoFrame from outside these blocks... make sure that's okay
            NSString *shareLink = [NSString stringWithFormat:kShelbyAPIGetLongLink, videoFrame.video.providerName, videoFrame.video.providerID, videoFrame.frameID];
            NSString *shareMessage = [NSString stringWithFormat:@"Watch \"%@\" %@ /via @Shelby", videoFrame.video.title, shareLink];
    
            DLog(@"Failed getting awe.sm short_url. Using full path %@", shareLink);
            [self shareWithFrame:videoFrame message:shareMessage andLink:shareLink];
            
        }];
        
        [operation start];

        
    });
    
}

- (void)showRollView
{
    [self setupMaskView];
    
    // Instantiate rollView
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SPShareRollView" owner:self options:nil];
    if (![nib isKindOfClass:[NSArray class]] || [nib count] == 0 || ![nib[0] isKindOfClass:[UIView class]]) {
        return;
    }

    self.rollView = nib[0];
    
//    // Reference videoFrame in current thread
//    NSManagedObjectContext *context = [self.appDelegate context];
//    NSManagedObjectID *objectID = [self.videoPlayer.videoFrame objectID];
//    Frame *videoFrame = (Frame *)[context existingObjectWithID:objectID error:nil];
//    djs should be able to use the frame from video player, context ought to be okay
    Frame *videoFrame = self.videoPlayer.videoFrame;
    [self.rollView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"rollingContainer.png"]]];
    
    // Load Thumbnail
    [AsynchronousFreeloader loadImageFromLink:videoFrame.video.thumbnailURL
                                 forImageView:_rollView.videoThumbnailView
                              withPlaceholder:nil
                               andContentMode:UIViewContentModeScaleAspectFill];
    
    // Set proper states for buttons
    [self toggleSocialButtonStatesOnRollViewLaunch];
    

    
    CGFloat xOrigin = self.videoPlayer.view.frame.size.width/2.0f - _rollView.frame.size.width/2.0f;
    CGFloat yOrigin = self.videoPlayer.view.frame.size.height/5.0f - _rollView.frame.size.height/4.0f;
    
    [self.rollView setFrame:CGRectMake(xOrigin,
                                       _videoPlayer.view.frame.size.height,
                                       _rollView.frame.size.width,
                                       _rollView.frame.size.height)];
    //djs find a better way to get this on screen
//    [self.model.overlayView addSubview:_rollView];
//    [self.model.overlayView bringSubviewToFront:self.self.rollView];
    
    [UIView animateWithDuration:0.5f
                     animations:^{
                         [self.mask setAlpha:0.7];
                         [self.rollView setFrame:CGRectMake(xOrigin,
                                                            yOrigin,
                                                            _rollView.frame.size.width,
                                                            _rollView.frame.size.height)];
                         
                     } completion:^(BOOL finished) {
                         
                         [self.rollView.rollTextView becomeFirstResponder];
                         [self.videoPlayer pause];
                         
                     }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                                selector:@selector(updateFacebookToggle)
                                                    name:kShelbyNotificationFacebookAuthorizationCompleted object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateTwitterToggle)
                                                 name:kShelbyNotificationTwitterAuthorizationCompleted object:nil];

}

- (void)hideRollView
{
    [UIView animateWithDuration:0.5
                     animations:^{
                         
                         CGFloat xOrigin = self.videoPlayer.view.frame.size.width/2.0f - _rollView.frame.size.width/2.0f;
                         [self.mask setAlpha:0];
                         [self.rollView setFrame:CGRectMake(xOrigin,
                                                            self.videoPlayer.view.frame.size.height,
                                                            _rollView.frame.size.width,
                                                            _rollView.frame.size.height)];
                         
                     } completion:^(BOOL finished) {
                         [self.mask removeFromSuperview];
                         [self.rollView.rollTextView resignFirstResponder];
                         [self.rollView removeFromSuperview];
                         [self.videoPlayer play];
                         
                     }];
}

#pragma mark - UI Methods (Private)
- (void)toggleSocialButtonStatesOnRollViewLaunch
{
    // Facebook Button State
    [self.rollView.facebookButton setSelected:(self.facebookConnected && [[FacebookHandler sharedInstance] allowPublishActions])];
    
    // Twitter Button State
    [self.rollView.twitterButton setSelected:self.twitterConnected];
}

#pragma mark - Action Methods (Public)
- (IBAction)cancelButtonAction:(id)sender
{
    [self hideRollView];
}

- (IBAction)rollButtonAction:(id)sender
{
    
    [self roll];
}

- (IBAction)toggleSocialButtonStates:(id)sender
{
    if (sender == self.rollView.facebookButton || sender == self.rollView.twitterButton) {
        [sender setSelected:![sender isSelected]];
    }
    
    if (sender == _rollView.facebookButton && [sender isSelected] && ![[FacebookHandler sharedInstance] allowPublishActions]) {
        [[FacebookHandler sharedInstance] askForPublishPermissions];
    }
}

#pragma mark - Action Methods (Private)
- (void)shareWithFrame:(Frame *)frame message:(NSString *)message andLink:(NSString *)link
{
    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:@[message]
                                                           applicationActivities:nil];
    activityController.excludedActivityTypes = @[UIActivityTypeCopyToPasteboard];
    // Send event to Google Analytics
    //djs TODO: add the GA back
//    id defaultTracker = [GAI sharedInstance].defaultTracker;
//    [defaultTracker sendEventWithCategory:kGAICategoryShare
//                               withAction:kGAIShareActionShareButton
//                                withLabel:[[SPModel sharedInstance].videoReel groupTitle]
//                                withValue:nil];
    
    [activityController setCompletionHandler:^(NSString *activityType, BOOL completed) {
        if (completed && ![activityType isEqualToString:kShelbySPActivityTypeRoll]) {
            
            // Send event to Google Analytics
            //djs TODO: add back GA
//            id defaultTracker = [GAI sharedInstance].defaultTracker;
//            [defaultTracker sendEventWithCategory:kGAICategoryShare
//                                       withAction:[NSString stringWithFormat:kGAIShareActionShareSuccess, activityType]
//                                        withLabel:[[SPModel sharedInstance].videoReel groupTitle]
//                                        withValue:nil];
            
        }
    }];

    if ( ![self sharePopOverController] ) {
        self.sharePopOverController = [[UIPopoverController alloc] initWithContentViewController:activityController];
        [self.sharePopOverController setDelegate:self];
        //djs
        [self.sharePopOverController presentPopoverFromRect:self.fromFrame
                                                     inView:self.videoPlayer.view
                                   permittedArrowDirections:UIPopoverArrowDirectionDown
                                                   animated:YES];
    }

}

- (void)roll
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        //djs TODO: shouldn't get our context this way, should be getting it during init
        User *user = [User currentAuthenticatedUserInContext:self.videoPlayer.videoFrame.managedObjectContext];
//        // Fetch User
//        CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
//        User *user = [dataUtility fetchUser];
        NSString *authToken = [user token];
        NSString *rollID = [user publicRollID];
        
//        // Fetch videoFrame
//        NSManagedObjectContext *context = [self.appDelegate context];
//        NSManagedObjectID *objectID = [self.videoPlayer.videoFrame objectID];
//        Frame *videoFrame = (Frame *)[context existingObjectWithID:objectID error:nil];
        //djs player's frame ought to be fine
        Frame *videoFrame = self.videoPlayer.videoFrame;
        NSString *frameID = [videoFrame frameID];
        
        // Create web safe string
        NSString *message = [self.rollView.rollTextView.text stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
        
        // Roll videoFrame
        NSString *rollString = [NSString stringWithFormat:kShelbyAPIPostFrameToPersonalRoll, rollID, frameID, authToken, message];
        [ShelbyAPIClient postFrameToPersonalRoll:rollString];

        // Share videoFrame
        if ( [_rollView.twitterButton isSelected] && [_rollView.facebookButton isSelected] ) { // Share to Facebook and Twitter
            
            NSString *socialString = [NSString stringWithFormat:kShelbyAPIPostFrameToAllSocial, frameID, authToken, message];
            [ShelbyAPIClient postShareFrameToSocialNetworks:socialString];
            
        } else if ( ![_rollView.twitterButton isSelected] && [_rollView.twitterButton isSelected] ) { // Share to Facebook
            
            NSString *facebookString = [NSString stringWithFormat:kShelbyAPIPostFrameToFacebook, frameID, authToken, message];
            [ShelbyAPIClient postShareFrameToSocialNetworks:facebookString];
            
        } else if ( [_rollView.twitterButton isSelected] && ![_rollView.facebookButton isSelected] ) { // Share to Twitter
            
            NSString *twitterString = [NSString stringWithFormat:kShelbyAPIPostFrameToTwitter, frameID, authToken, message];
            [ShelbyAPIClient postShareFrameToSocialNetworks:twitterString];
            
        } else { // Don't share to any network
            
            // Do nothing
        }
       
        // Send event to Google Analytics
        //djs TODO send data to GA
//        id defaultTracker = [GAI sharedInstance].defaultTracker;
//        [defaultTracker sendEventWithCategory:kGAICategoryShare
//                                   withAction:kGAIShareActionRollSuccess
//                                    withLabel:[[SPModel sharedInstance].videoReel groupTitle]
//                                    withValue:nil];
        
        // Dismiss rollView
        [self performSelectorOnMainThread:@selector(hideRollView) withObject:nil waitUntilDone:NO];
        
    });
    
}

#pragma mark - UITextViewDelegate Methods
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ( [text isEqualToString:@"\n"] && [textView.text length] > 0 ) {
        [self.rollView.rollTextView resignFirstResponder];
        return NO;
    }
    
    return YES;
}

#pragma mark - UIPopoverControllerDelegate Methods
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    [UIView animateWithDuration:0.5
                     animations:^{
                         [self.mask setAlpha:0.0f];
                     } completion:^(BOOL finished) {
                         [self.mask removeFromSuperview];
                     }];
    
    //djs
//    [self.model rescheduleOverlayTimer];
}

@end
