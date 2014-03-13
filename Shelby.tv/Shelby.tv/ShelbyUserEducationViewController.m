//
//  ShelbyUserEducationViewController.m
//  Shelby.tv
//
//  Created by Dan Spinosa on 1/21/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyUserEducationViewController.h"

static NSString * const kShelbyUserEducationDefaultsKeyPrefix = @"userEd-";

@interface ShelbyUserEducationViewController ()
@property (nonatomic, assign) BOOL hasSeenPlaybackEntityChange;
@property (nonatomic, assign) CGFloat nibAlpha;
@property (nonatomic, assign) CGPoint nibCenter;
@end

@implementation ShelbyUserEducationViewController

//used to prevent showing user education after video has played
static BOOL videoHasPlayed = NO;

+ (ShelbyUserEducationViewController *)newStreamUserEducationViewController
{
    static NSString *nibName = @"StreamUserEducationView";
    if ([ShelbyUserEducationViewController userIsEducatedFor:nibName] || videoHasPlayed) {
        return nil;
    } else {
        return [[ShelbyUserEducationViewController alloc] initWithNibName:nibName
                                                                   bundle:nil];
    }
}

+ (ShelbyUserEducationViewController *)newChannelsUserEducationViewController
{
    static NSString *nibName = @"ChannelsUserEducationView";
    if ([ShelbyUserEducationViewController userIsEducatedFor:nibName] || videoHasPlayed) {
        return nil;
    } else {
        return [[ShelbyUserEducationViewController alloc] initWithNibName:nibName
                                                                   bundle:nil];
    }
}

+ (ShelbyUserEducationViewController *)newExploreUserEducationViewController
{
    static NSString *nibName = @"ExploreUserEducationView";
    if ([ShelbyUserEducationViewController userIsEducatedFor:nibName] || videoHasPlayed) {
        return nil;
    } else {
        return [[ShelbyUserEducationViewController alloc] initWithNibName:nibName
                                                                   bundle:nil];
    }
}

+ (BOOL)userIsEducatedFor:(NSString *)educationNibName
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:[NSString stringWithFormat:@"%@%@", kShelbyUserEducationDefaultsKeyPrefix, educationNibName]];
}

+ (void)setVideoHasPlayed:(BOOL)played
{
    videoHasPlayed = played;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _hasSeenPlaybackEntityChange = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.nibAlpha = self.view.alpha;
    self.nibCenter = self.view.center;
    self.view.alpha = 0.f;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playbackEntityDidChangeNotification:)
                                                 name:kShelbyPlaybackEntityDidChangeNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)referenceView:(UIView *)referenceView willAppearAnimated:(BOOL)animated;
{
    if ([ShelbyUserEducationViewController userIsEducatedFor:self.nibName] || videoHasPlayed) {
        return;
    }
    
    [[[UIApplication sharedApplication] keyWindow].rootViewController.view addSubview:self.view];
    
    self.view.center = CGPointMake(self.nibCenter.x + referenceView.frame.size.width, self.nibCenter.y);
    
    [UIView animateWithDuration:.5 animations:^{
        self.view.alpha = self.nibAlpha;
    }];
}

- (void)referenceViewWillDisappear:(BOOL)animated
{
    [UIView animateWithDuration:.5 animations:^{
        self.view.alpha = 0.f;
    } completion:^(BOOL finished) {
        [self.view removeFromSuperview];
    }];
}

- (void)userHasBeenEducatedAndViewShouldHide:(BOOL)shouldHide
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES
               forKey:[NSString stringWithFormat:@"%@%@", kShelbyUserEducationDefaultsKeyPrefix, self.nibName]];
    [defaults synchronize];
    
    if (shouldHide) {
        [self referenceViewWillDisappear:YES];
    }
}

#pragma mark - Notifications

- (void)playbackEntityDidChangeNotification:(NSNotification *)note
{
    //if there was no pervious entity, ignore
    if (!self.hasSeenPlaybackEntityChange) {
        self.hasSeenPlaybackEntityChange = YES;
        return;
    }
    
    //always hide when a video starts to play
    //does not necessarily indicate user has been educated
    [self referenceViewWillDisappear:YES];
    [ShelbyUserEducationViewController setVideoHasPlayed:YES];
}

@end
