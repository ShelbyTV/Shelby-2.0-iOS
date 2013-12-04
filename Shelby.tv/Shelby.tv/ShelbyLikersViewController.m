//
//  ShelbyLikersViewController.m
//  Shelby.tv
//
//  Created by Keren on 12/2/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyLikersViewController.h"
#import "User+Helper.h"

@interface ShelbyLikersViewController ()
@property (nonatomic, strong) NSMutableArray *likers;
@property (nonatomic, weak) IBOutlet UITableView *likersTable;
@property (nonatomic, weak) IBOutlet UILabel *title;

- (IBAction)close:(id)sender;
@end

@implementation ShelbyLikersViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _likers = [@[] mutableCopy];
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.likersTable registerNib:[UINib nibWithNibName:@"LikerViewCell" bundle:nil] forCellReuseIdentifier:@"LikerViewCell"];
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
    _localLikers = localLikers;
    
    for (User *user in localLikers) {
        if (![self.likers containsObject:user]) {
            [self.likers addObject:user];
        }
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
}

@end
