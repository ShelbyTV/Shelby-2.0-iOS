//
//  ShelbyLikersViewController.m
//  Shelby.tv
//
//  Created by Keren on 12/2/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyLikersViewController.h"
#import "User+Helper.h"
#import "ShelbyDataMediator.h"

@interface ShelbyLikersViewController ()
@property (nonatomic, strong) NSMutableOrderedSet *likers;
@property (nonatomic, weak) IBOutlet UITableView *likersTable;
@property (nonatomic, weak) IBOutlet UILabel *videoTitle;
@property (nonatomic, weak) IBOutlet UIView *noLikersView;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *loadingSpinner;
@property (nonatomic, weak) IBOutlet UIView *topbar;

- (IBAction)close:(id)sender;
@end

@implementation ShelbyLikersViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _likers = [[NSMutableOrderedSet alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [ShelbyAnalyticsClient trackScreen:kAnalyticsScreenLikersList];
    
    [self.likersTable registerNib:[UINib nibWithNibName:@"LikerViewCell" bundle:nil] forCellReuseIdentifier:@"LikerViewCell"];
    
    self.topbar.backgroundColor =  [UIColor colorWithPatternImage:[UIImage imageNamed:@"top-nav-bkgd.png"]];

    [self updateViewPerLikerCount];
}

- (void)updateViewPerLikerCount
{
    if ([self.likers count]) {
        self.noLikersView.hidden = YES;
        self.likersTable.hidden = NO;
    } else {
        self.noLikersView.hidden = NO;
        self.likersTable.hidden = YES;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)close:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)setLocalLikers:(NSMutableOrderedSet *)localLikers
{
    if (_localLikers != localLikers) {
        [self willChangeValueForKey:@"localLikers"];
        _localLikers = localLikers;
        [self.likers unionOrderedSet:localLikers];
        [self didChangeValueForKey:@"localLikers"];
    }

}

- (void)setLikedVideo:(Video *)likedVideo
{
    if (_likedVideo != likedVideo) {
        [self willChangeValueForKey:@"likedVideo"];
        _likedVideo = likedVideo;
        [self didChangeValueForKey:@"likedVideo"];
        
        self.videoTitle.text =   [NSString stringWithFormat:@"Likes: %@", _likedVideo.title];
        
        [self.loadingSpinner startAnimating];
        [[ShelbyDataMediator sharedInstance] fetchAllLikersOfVideo:likedVideo completion:^(NSArray *users) {
            [self.loadingSpinner stopAnimating];
            [self.likers addObjectsFromArray:users];
            [self updateViewPerLikerCount];
            [self.likersTable reloadData];
        }];
    }
}

#pragma mark - LikerCellDelegate Method
- (void)toggleFollowForUser:(User *)user
{
    BOOL isFollowing = [self.currentUser isFollowing:user.publicRollID];
    
    if (isFollowing) {
        [self.delegate unfollowRoll:user.publicRollID];
    } else {
        [self.delegate followRoll:user.publicRollID];
    }
}

#pragma mark - UITableViewDataSource Delegate Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.likers count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    LikerCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LikerViewCell" forIndexPath:indexPath];
    
    cell.delegate = self;

    User *user = self.likers[indexPath.row];
    [cell setupCellForLiker:user];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    User *user = self.likers[indexPath.row];
    
    [self.delegate userProfileWasTapped:user.userID];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [ShelbyAnalyticsClient sendEventWithCategory:kAnalyticsCategoryPrimaryUX
                                          action:kAnalyticsUXTapLikerListLiker
                                 nicknameAsLabel:YES];
    
    [ShelbyAnalyticsClient sendLocalyticsEvent:kLocalyticsTapLikerListLiker];
}

@end
