//
//  ShelbyUserFollowingViewController.m
//  Shelby.tv
//
//  Created by Dan Spinosa on 1/23/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyUserFollowingViewController.h"
#import "ShelbyDataMediator.h"
#import "ShelbyStreamInfoViewController.h"
#import "User+Helper.h"
#import "UserFollowingCell.h"

@interface ShelbyUserFollowingViewController ()
@property (strong, nonatomic) NSArray *rawRollFollowings;
@property (strong, nonatomic) UIActivityIndicatorView *spinner;
@end

@implementation ShelbyUserFollowingViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.spinner = ({
        UIActivityIndicatorView *v = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        v.hidesWhenStopped = YES;
        [v startAnimating];
        v;
    });
    [self.view addSubview:self.spinner];
}

- (void)viewDidAppear:(BOOL)animated
{
    self.spinner.center = CGPointMake(self.view.bounds.size.width/2.f, -20);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setUser:(User *)user
{
    if (_user != user) {
        _user = user;
        
        if (user){
            self.tableView.contentInset = UIEdgeInsetsMake(50, 0, 0, 0);
            [self.spinner startAnimating];
            [[ShelbyDataMediator sharedInstance] fetchRollFollowingsForUser:user withCompletion:^(User *user, NSArray *rawRollFollowings, NSError *error) {
                if (!error) {
                    NSMutableArray *following = [NSMutableArray arrayWithArray:rawRollFollowings];
                    // When viewing own user profile, filter out user's watch later and public roll
                    NSMutableArray *removeUserRolls = [NSMutableArray new];
                    for (NSDictionary *rollDictionary in following) {
                        if ([rollDictionary[@"roll_type"] isEqualToNumber:@(13)]) { // 13 = watch later roll type
                            [removeUserRolls addObject:rollDictionary];
                        } else if ([rollDictionary[@"id"] isEqualToString:self.user.publicRollID]) {
                            [removeUserRolls addObject:rollDictionary];
                        }
                    }
                    [following removeObjectsInArray:removeUserRolls];
                    self.rawRollFollowings = [NSArray arrayWithArray:following];
                    [self.tableView reloadData];
                } else {
                    DLog(@"ERROR on roll following fetch %@", error);
                }
                [self.spinner stopAnimating];
                [self.tableView setContentInset:UIEdgeInsetsZero];
            }];
        }
    }
}

- (void)setRawRollFollowings:(NSArray *)rawRollFollowings
{
    NSMutableDictionary *uniqueFollowings = [[NSMutableDictionary alloc] initWithCapacity:[rawRollFollowings count]];
    for (NSDictionary *rollInfo in rawRollFollowings) {
        if (rollInfo[@"creator_id"] && rollInfo[@"creator_nickname"]) {
            uniqueFollowings[rollInfo[@"creator_id"]] = rollInfo;
        }
    }
    _rawRollFollowings = [uniqueFollowings allValues];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.rawRollFollowings.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"UserFollowingCell";
    UserFollowingCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.rollFollowing = self.rawRollFollowings[indexPath.row];
    return cell;
}

#pragma mark - UITableViewCellDelegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.delegate userProfileWasTapped:self.rawRollFollowings[indexPath.row][@"creator_id"]];
}

@end
