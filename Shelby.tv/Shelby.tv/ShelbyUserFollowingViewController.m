//
//  ShelbyUserFollowingViewController.m
//  Shelby.tv
//
//  Created by Dan Spinosa on 1/23/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyUserFollowingViewController.h"
#import "NoContentView.h"
#import "ShelbyDataMediator.h"
#import "ShelbyStreamInfoViewController.h"
#import "User+Helper.h"
#import "UserFollowingCell.h"

#define SECTION_COUNT 2
#define SECTION_FOR_NO_CONTENT 0
#define SECTION_FOR_FOLLOWINGS 1

@interface ShelbyUserFollowingViewController ()
@property (strong, nonatomic) NSArray *rawRollFollowings;
@property (strong, nonatomic) UIActivityIndicatorView *spinner;
@property (nonatomic, assign) BOOL showNoContentView;
@end

@implementation ShelbyUserFollowingViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)awakeFromNib
{
    [self commonInit];
}

- (void)commonInit
{
    _showNoContentView = NO;
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
                    self.showNoContentView = ([self.rawRollFollowings count] == 0);
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
    return SECTION_COUNT;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == SECTION_FOR_NO_CONTENT) {
        return self.showNoContentView ? 1 : 0;
        
    } else if (section == SECTION_FOR_FOLLOWINGS) {
        return self.rawRollFollowings.count;
        
    } else {
        STVAssert(NO, @"unhandled section");
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == SECTION_FOR_NO_CONTENT) {
        return [NoContentView noFollowingsView];
        
    } else if (indexPath.section == SECTION_FOR_FOLLOWINGS) {
        static NSString *CellIdentifier = @"UserFollowingCell";
        UserFollowingCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        cell.rollFollowing = self.rawRollFollowings[indexPath.row];
        return cell;
        
    } else {
        STVAssert(NO, @"unhandled section");
        return nil;
    }
}

#pragma mark - UITableViewCellDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == SECTION_FOR_NO_CONTENT) {
        return tableView.bounds.size.height;
        
    } else if (indexPath.section == SECTION_FOR_FOLLOWINGS) {
        return tableView.rowHeight;
        
    } else {
        STVAssert(NO, @"unhandled section");
        return 0;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.delegate userProfileWasTapped:self.rawRollFollowings[indexPath.row][@"creator_id"]];
}

@end
