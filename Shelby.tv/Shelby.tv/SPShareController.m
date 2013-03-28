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
#import "SPVideoReel.h"

@interface SPShareController ()

@property (weak, nonatomic) SPModel *model;
@property (weak, nonatomic) AppDelegate *appDelegate;
@property (weak, nonatomic) SPVideoPlayer *videoPlayer;
@property (nonatomic) SPShareRollView *rollView;
@property (nonatomic) UIPopoverController *sharePopOverController;
@property (assign, nonatomic) BOOL facebookConnected;
@property (assign, nonatomic) BOOL twitterConnected;

/// Setup Methods
- (void)setup;

/// UI Methods
- (void)toggleSocialButtonStatesOnRollViewLaunch;
- (void)removeKeyboard:(NSNotification *)notification;

/// Action Methods
- (void)shareWithFrame:(Frame *)frame message:(NSString *)message andLink:(NSString *)link;
- (void)roll;

@end

@implementation SPShareController


#pragma mark - Memory Management
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kShelbySPUserDidSwipeToNextVideo object:nil];
}

#pragma mark - Initialization
- (id)initWithVideoPlayer:(SPVideoPlayer *)videoPlayer
{
    self = [super init];
    if (self) {
        _videoPlayer = videoPlayer;
    }
    
    return self;
}

#pragma mark - Setup Methods
- (void)setup
{
    
    // Reference AppDelegate
    self.appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    // Add Observer
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(removeKeyboard:)
                                                 name:kShelbySPUserDidSwipeToNextVideo
                                               object:nil];
    
    // Reference social connection status
    if ( [[NSUserDefaults standardUserDefaults] boolForKey:kShelbyDefaultUserAuthorized] ) {
     
        CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
        User *user = [dataUtility fetchUser];
        self.facebookConnected = [[user facebookConnected] boolValue];
        self.twitterConnected = [[user twitterConnected] boolValue];
        
    }
    
}

#pragma mark - UI Methods (Public)
- (void)share
{
    [self setup];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // Reference videoFrame
        self.model = (SPModel *)[SPModel sharedInstance];
        NSManagedObjectContext *context = [self.appDelegate context];
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
            NSString *shareMessage = [NSString stringWithFormat:@"Watch \"%@\": %@ via @Shelby", frame.video.title, shareLink];
            
            DLog(@"Succeeded fetching link for frame: %@", shareLink);
            [self shareWithFrame:frame message:shareMessage andLink:shareLink];
            
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
            
            // If short link fetch failed, use full_path
            Frame *frame = (Frame *)[context existingObjectWithID:[videoFrame objectID] error:nil];
            NSString *shareLink = [NSString stringWithFormat:kShelbyAPIGetLongLink, frame.video.providerName, frame.video.providerID, frame.frameID];
            NSString *shareMessage = [NSString stringWithFormat:@"Watch \"%@\" %@ /via @Shelby", videoFrame.video.title, shareLink];
    
            DLog(@"Failed getting awe.sm short_url. Using full path %@", shareLink);
            [self shareWithFrame:frame message:shareMessage andLink:shareLink];
            
        }];
        
        [operation start];

        
    });
    
}

- (void)showRollView
{
    
    // Instantiate rollView
    NSArray *nib = nil;
    if (DEVICE_IPAD) {
        nib = [[NSBundle mainBundle] loadNibNamed:@"SPShareRollView" owner:self options:nil];
    } else {
        nib = [[NSBundle mainBundle] loadNibNamed:@"SPShareRollView-iPhone" owner:self options:nil];
    }
    
    if (![nib isKindOfClass:[NSArray class]] || [nib count] == 0 || ![nib[0] isKindOfClass:[UIView class]]) {
        return;
    }

    self.rollView = nib[0];
    
    // Reference videoFrame in current thread
    NSManagedObjectContext *context = [self.appDelegate context];
    NSManagedObjectID *objectID = [self.videoPlayer.videoFrame objectID];
    Frame *videoFrame = (Frame *)[context existingObjectWithID:objectID error:nil];
    
    // Set Video Title
    [self.rollView.videoTitleLabel setText:[videoFrame.video title]];
    
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
    [self.videoPlayer.view addSubview:_rollView];
    
    [UIView animateWithDuration:0.5f
                     animations:^{
                         
                         [self.rollView setFrame:CGRectMake(xOrigin,
                                                            yOrigin,
                                                            _rollView.frame.size.width,
                                                            _rollView.frame.size.height)];
                         
                     } completion:^(BOOL finished) {
                         
                         [self.rollView.rollTextView becomeFirstResponder];
                         [self.videoPlayer pause];
                         
                     }];
}

- (void)hideRollView
{
    [UIView animateWithDuration:0.5
                     animations:^{
                         
                         CGFloat xOrigin = self.videoPlayer.view.frame.size.width/2.0f - _rollView.frame.size.width/2.0f;
                         
                         [self.rollView setFrame:CGRectMake(xOrigin,
                                                            self.videoPlayer.view.frame.size.height,
                                                            _rollView.frame.size.width,
                                                            _rollView.frame.size.height)];
                         
                     } completion:^(BOOL finished) {
                         
                         [self.rollView.rollTextView resignFirstResponder];
                         [self.rollView removeFromSuperview];
                         [self.videoPlayer play];
                         
                     }];
}

#pragma mark - UI Methods (Private)
- (void)toggleSocialButtonStatesOnRollViewLaunch
{
    
    // Facebook Button State
    ( _facebookConnected ) ? [self.rollView.facebookButton setSelected:YES] : [self.rollView.facebookButton setEnabled:NO];
    
    // Twitter Button State
    ( _twitterConnected ) ? [self.rollView.twitterButton setSelected:YES] : [self.rollView.twitterButton setEnabled:NO];
    
}

- (void)removeKeyboard:(NSNotification *)notification
{
    if ( _rollView ) {
        
        if ( [_rollView.rollTextView isFirstResponder] ) {
            
            [self.rollView.rollTextView resignFirstResponder];
            
        }
    }
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
    
    if ( sender == _rollView.facebookButton ) {
        
        ( [self.rollView.facebookButton isSelected] ) ? [self.rollView.facebookButton setSelected:NO] : [self.rollView.facebookButton setSelected:YES];
        
    } else if ( sender == _rollView.twitterButton ) {
        
        ( [self.rollView.twitterButton isSelected] ) ? [self.rollView.twitterButton setSelected:NO] : [self.rollView.twitterButton setSelected:YES];
        
    } else {
        
        // Do nothing (condition should not be entered)

    }
    
}

#pragma mark - Action Methods (Private)
- (void)shareWithFrame:(Frame *)frame message:(NSString *)message andLink:(NSString *)link
{

    NSManagedObjectContext *context = [self.appDelegate context];
    NSManagedObjectID *objectID = [frame objectID];
    frame = (Frame *)[context existingObjectWithID:objectID error:nil];
    
    UIActivityViewController *activityController = nil;
    if ( [[NSUserDefaults standardUserDefaults] boolForKey:kShelbyDefaultUserAuthorized] ) { // Logged In
        
        SPShareRollActivity *rollActivity = [[SPShareRollActivity alloc] init];
        rollActivity.shareController = self;
        
        SPShareLikeActivity *likeActivity = [[SPShareLikeActivity alloc] init];
        likeActivity.videoFrame = frame;
        likeActivity.overlayView = [self.model overlayView];
        
        if ( GroupType_Likes == [self.model groupType] ) {
            
            activityController = [[UIActivityViewController alloc] initWithActivityItems:@[message]
                                                                   applicationActivities:[NSArray arrayWithObjects:rollActivity, nil]];
            activityController.excludedActivityTypes = @[UIActivityTypeCopyToPasteboard];
            
        } else if ( GroupType_PersonalRoll == [self.model groupType] ) {
            
            activityController = [[UIActivityViewController alloc] initWithActivityItems:@[message]
                                                                   applicationActivities:[NSArray arrayWithObjects:likeActivity, nil]];
            activityController.excludedActivityTypes = @[UIActivityTypeCopyToPasteboard];
            
        } else {
            
            activityController = [[UIActivityViewController alloc] initWithActivityItems:@[message]
                                                                   applicationActivities:[NSArray arrayWithObjects:likeActivity, rollActivity, nil]];
            activityController.excludedActivityTypes = @[UIActivityTypeCopyToPasteboard];
            
        }
        
    } else { // Logged Out
        
        SPShareLikeActivity *likeActivity = [[SPShareLikeActivity alloc] init];
        likeActivity.videoFrame = frame;
        likeActivity.overlayView = [self.model overlayView];
        
        activityController = [[UIActivityViewController alloc] initWithActivityItems:@[message]
                                                               applicationActivities:[NSArray arrayWithObjects:likeActivity, nil]];
        activityController.excludedActivityTypes = @[UIActivityTypeCopyToPasteboard];
    }
    

    // Send event to Google Analytics
    id defaultTracker = [GAI sharedInstance].defaultTracker;
    [defaultTracker sendEventWithCategory:kGAICategoryShare
                               withAction:@"User did tap share button to %@"
                                withLabel:[[SPModel sharedInstance].videoReel groupTitle]
                                withValue:nil];
    
    [activityController setCompletionHandler:^(NSString *activityType, BOOL completed) {
        if (completed && ![activityType isEqualToString:kShelbySPActivityTypeRoll]) {
            
            // Send event to Google Analytics
            id defaultTracker = [GAI sharedInstance].defaultTracker;
            [defaultTracker sendEventWithCategory:kGAICategoryShare
                                       withAction:[NSString stringWithFormat:@"User did successfully share to %@", activityType]
                                        withLabel:[[SPModel sharedInstance].videoReel groupTitle]
                                        withValue:nil];
            
        }
    }];
    
    if (DEVICE_IPAD) {
        self.sharePopOverController = [[UIPopoverController alloc] initWithContentViewController:activityController];
        [self.sharePopOverController setDelegate:self];
        [self.sharePopOverController presentPopoverFromRect:[self.model.overlayView.shareButton frame]
                                                     inView:[self.model overlayView]
                                   permittedArrowDirections:UIPopoverArrowDirectionDown
                                                   animated:YES];
    } else {
        [self.videoPlayer presentViewController:activityController animated:YES completion:nil];
    }
}

- (void)roll
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // Fetch User
        CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
        User *user = [dataUtility fetchUser];
        NSString *authToken = [user token];
        NSString *rollID = [user personalRollID];
        
        // Fetch videoFrame
        NSManagedObjectContext *context = [self.appDelegate context];
        NSManagedObjectID *objectID = [self.videoPlayer.videoFrame objectID];
        Frame *videoFrame = (Frame *)[context existingObjectWithID:objectID error:nil];
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
        id defaultTracker = [GAI sharedInstance].defaultTracker;
        [defaultTracker sendEventWithCategory:kGAICategoryShare
                                   withAction:@"User did successfully roll video"
                                    withLabel:[[SPModel sharedInstance].videoReel groupTitle]
                                    withValue:nil];
        
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

#pragma mark - UIPopoverControllerDelegate
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    [self.model rescheduleOverlayTimer];
}

@end
