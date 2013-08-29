//
//  WelcomeViewController.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 8/28/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "WelcomeViewController.h"
#import "WelcomeLoginView.h"
#import "WelcomeScrollHolderView.h"

NSString * const kShelbyWelcomeStatusKey = @"welcome_status";

typedef NS_ENUM(NSInteger, ShelbyWelcomeStatus)
{
    ShelbyWelcomeStatusUnstarted, // 0
    ShelbyWelcomeStatusComplete
};

@interface WelcomeViewController ()
@property (weak, nonatomic) IBOutlet UIScrollView *welcomeScrollScroller;
@property (nonatomic, strong) WelcomeLoginView *welcomeLoginView;
@property (nonatomic, strong) WelcomeScrollHolderView *welcomeScrollHolderView;
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

    //add the scroller view above the login view
    self.welcomeScrollHolderView = [[NSBundle mainBundle] loadNibNamed:@"WelcomeScrollHolderView" owner:self options:nil][0];
    self.welcomeScrollHolderView.frame = self.view.bounds;
    self.welcomeScrollHolderView.scrollViewDelegate = self;
    //adding the scroller within our own proramatic scroller (used to slide it out of the way)
    self.welcomeScrollScroller.contentSize = CGSizeMake(self.view.bounds.size.width, self.view.bounds.size.height*2);
    self.welcomeScrollScroller.frame = self.view.frame;
    self.welcomeScrollScroller.scrollEnabled = NO;
    [self.welcomeScrollScroller addSubview:self.welcomeScrollHolderView];

    //add the login view at bottom of scroller
    self.welcomeLoginView = [[NSBundle mainBundle] loadNibNamed:@"WelcomeLoginView" owner:self options:nil][0];
    self.welcomeLoginView.frame = CGRectMake(0, self.view.bounds.size.height, self.view.bounds.size.width, self.view.bounds.size.height);
    [self.welcomeScrollScroller addSubview:self.welcomeLoginView];
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
    //XXX
    return NO;
    //TODO: uncomment the following
//    return [[NSUserDefaults standardUserDefaults] integerForKey:kShelbyWelcomeStatusKey] == ShelbyWelcomeStatusComplete;
}

#pragma mark - WelcomeLoginView's IBActions

- (IBAction)createAccountTapped:(id)sender {
    [WelcomeViewController sendEventWithCategory:kAnalyticsCategoryWelcome
                                      withAction:kAnalyticsWelcomeTapSignup
                                       withLabel:nil];
    [self welcomeComplete];
    [self.delegate welcomeDidTapSignup:self];
}

- (IBAction)loginTapped:(id)sender {
    [WelcomeViewController sendEventWithCategory:kAnalyticsCategoryWelcome
                                      withAction:kAnalyticsWelcomeTapLogin
                                       withLabel:nil];
    [self welcomeComplete];
    [self.delegate welcomeDidTapLogin:self];
}

- (IBAction)previewTapped:(id)sender {
    [WelcomeViewController sendEventWithCategory:kAnalyticsCategoryWelcome
                                      withAction:kAnalyticsWelcomeTapPreview
                                       withLabel:nil];
    [self welcomeComplete];
    [self.delegate welcomeDidTapPreview:self];
}

#pragma mark - Helpers

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
