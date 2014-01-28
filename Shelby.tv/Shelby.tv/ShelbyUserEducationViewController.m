//
//  ShelbyUserEducationViewController.m
//  Shelby.tv
//
//  Created by Dan Spinosa on 1/21/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyUserEducationViewController.h"
//for the constant kShelbyVideoReelDidChangePlaybackEntityNotification :-/
#import "SPVideoReel.h"

static NSString * const kShelbyUserEducationDefaultsKeyPrefix = @"userEd-";

@interface ShelbyUserEducationViewController ()

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

+ (BOOL)userIsEducatedFor:(NSString *)educationNibName
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:[NSString stringWithFormat:@"%@%@", kShelbyUserEducationDefaultsKeyPrefix, educationNibName]];
}

+ (void)setVideoHasPlayed:(BOOL)played
{
    videoHasPlayed = played;
}

+ (void)reset
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    for (NSString *defaultsKey in [[defaults dictionaryRepresentation] keyEnumerator]) {
        if ([defaultsKey rangeOfString:kShelbyUserEducationDefaultsKeyPrefix].location != NSNotFound) {
            [defaults removeObjectForKey:defaultsKey];
        }
    }
    [defaults synchronize];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.alpha = 0.f;
    [[[UIApplication sharedApplication] keyWindow].rootViewController.view addSubview:self.view];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playbackEntityDidChangeNotification:)
                                                 name:kShelbyVideoReelDidChangePlaybackEntityNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)referenceViewWillAppear:(CGRect)referenceViewFrame animated:(BOOL)animated
{
    if ([ShelbyUserEducationViewController userIsEducatedFor:self.nibName] || videoHasPlayed) {
        return;
    }
    
    self.view.center = CGPointMake(self.view.center.x + referenceViewFrame.size.width, self.view.center.y);
    
    [UIView animateWithDuration:.5 animations:^{
        self.view.alpha = 1.0f;
    }];
}

- (void)referenceViewWillDisappear:(BOOL)animated
{
    [UIView animateWithDuration:.5 animations:^{
        self.view.alpha = 0.f;
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
    //always hide when a video starts to play
    //does not necessarily indicate user has been educated
    [self referenceViewWillDisappear:YES];
    [ShelbyUserEducationViewController setVideoHasPlayed:YES];
}

@end
