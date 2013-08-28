//
//  WelcomeViewController.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 8/28/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "WelcomeViewController.h"
#import "WelcomeScrollHolderView.h"

NSString * const kShelbyWelcomeStatusKey = @"welcome_status";

typedef NS_ENUM(NSInteger, ShelbyWelcomeStatus)
{
    ShelbyWelcomeStatusUnstarted, // 0
    ShelbyWelcomeStatusComplete
};

@interface WelcomeViewController ()
@property (nonatomic, strong) WelcomeScrollHolderView *welcomeScrollHolderView;
@property (weak, nonatomic) IBOutlet UIScrollView *welcomeScrollScroller;
@end

@implementation WelcomeViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        //init
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.trackedViewName = @"Welcome v2";

    [WelcomeViewController sendEventWithCategory:kAnalyticsCategoryWelcome
                                      withAction:kAnalyticsWelcomeStart
                                       withLabel:nil];

    //TODO: add the login view at the lowest level (hooked up to my actions)

    //add the scorller view above the login view
    self.welcomeScrollHolderView = [[WelcomeScrollHolderView alloc] initWithFrame:self.view.bounds];
    self.welcomeScrollHolderView.scrollViewDelegate = self;
    //adding the scroller within our own proramatic scroller (used to slide it out of the way)
    self.welcomeScrollScroller.contentSize = CGSizeMake(self.view.bounds.size.width, self.view.bounds.size.height*2);
    self.welcomeScrollScroller.scrollEnabled = NO;
    [self.welcomeScrollScroller addSubview:self.welcomeScrollHolderView];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (BOOL)shouldAutorotate
{
    return NO;
}

+ (bool)isWelcomeComplete
{
    return NO;
    //XXX
//    return [[NSUserDefaults standardUserDefaults] integerForKey:kShelbyWelcomeStatusKey] == ShelbyWelcomeStatusComplete;
}

// -- old IBActions ---
// these may come from a sub view now...

- (IBAction)signupWasTapped:(id)sender
{
    [WelcomeViewController sendEventWithCategory:kAnalyticsCategoryWelcome
                                      withAction:kAnalyticsWelcomeTapSignup
                                       withLabel:nil];
    [self welcomeComplete];
    [self.delegate welcomeDidTapSignup:self];
}

- (IBAction)loginWasTapped:(id)sender
{
    [WelcomeViewController sendEventWithCategory:kAnalyticsCategoryWelcome
                                      withAction:kAnalyticsWelcomeTapLogin
                                       withLabel:nil];
    [self welcomeComplete];
    [self.delegate welcomeDidTapLogin:self];
}

- (IBAction)previewWasTapped:(id)sender
{
    [WelcomeViewController sendEventWithCategory:kAnalyticsCategoryWelcome
                                      withAction:kAnalyticsWelcomeTapPreview
                                       withLabel:nil];
    [self welcomeComplete];
    [self.delegate welcomeDidTapPreview:self];
}

- (void)welcomeComplete
{
    [WelcomeViewController sendEventWithCategory:kAnalyticsCategoryWelcome
                                      withAction:kAnalyticsWelcomeFinish
                                       withLabel:nil];
    [[NSUserDefaults standardUserDefaults] setInteger:ShelbyWelcomeStatusComplete forKey:kShelbyWelcomeStatusKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat overPull = scrollView.contentOffset.y - (scrollView.contentSize.height - scrollView.bounds.size.height);
    DLog(@"offsetY: %f, sizeH:%f, overpull:%f", scrollView.contentOffset.y, scrollView.contentSize.height, overPull);
    if (overPull > 0) {
        self.welcomeScrollScroller.contentOffset = CGPointMake(0, self.welcomeScrollScroller.contentOffset.y + overPull);
        scrollView.contentOffset = CGPointMake(0, scrollView.contentOffset.y - overPull);
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    //this works decently
    //XXX i'm sure i'm not using velocity correctly, but this works well enought that i'm moving on (for now) -ds
    DLog(@"velocity: %@, offset: %@", NSStringFromCGPoint(velocity), NSStringFromCGPoint(*targetContentOffset));
    DLog(@"offsetY: %f, needed:%f", self.welcomeScrollScroller.contentOffset.y, (self.welcomeScrollScroller.bounds.size.height/2.f)/velocity.y);

    if (self.welcomeScrollScroller.contentOffset.y > fabsf((self.welcomeScrollScroller.bounds.size.height/2.f)/velocity.y)) {
        DLog(@"SCROLL AWAY!");
        //we could use velocity to better
        [self.welcomeScrollScroller setContentOffset:CGPointMake(0, self.welcomeScrollScroller.bounds.size.height) animated:YES];
        self.welcomeScrollScroller.scrollEnabled = YES;
    } else {
        DLog(@"FAIL and FALL back DOWN");
        [self.welcomeScrollScroller setContentOffset:CGPointMake(0, 0) animated:YES];
        self.welcomeScrollScroller.scrollEnabled = NO;
    }

}

@end
