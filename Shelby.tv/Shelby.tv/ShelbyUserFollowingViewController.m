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
    [super awakeFromNib];
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
    [super viewWillAppear:animated];
    
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
    [super viewDidAppear:animated];

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
            [self.tableView setContentInset:UIEdgeInsetsMake(self.tableView.contentInset.top + 50,
                                                             self.tableView.contentInset.left,
                                                             self.tableView.contentInset.bottom,
                                                             self.tableView.contentInset.right)];
            [self.spinner startAnimating];
            [[ShelbyDataMediator sharedInstance] fetchRollFollowingsForUser:user withCompletion:^(User *user, NSArray *rawRollFollowings, NSError *error) {
                if (!error) {
                    self.rawRollFollowings = rawRollFollowings;
                    self.showNoContentView = ([self.rawRollFollowings count] == 0);
                    [self.tableView reloadData];
                } else {
                    DLog(@"ERROR on roll following fetch %@", error);
                }
                [self.spinner stopAnimating];
                [self.tableView setContentInset:UIEdgeInsetsMake(self.tableView.contentInset.top - 50,
                                                                 self.tableView.contentInset.left,
                                                                 self.tableView.contentInset.bottom,
                                                                 self.tableView.contentInset.right)];
            }];
        }
    }
}

- (void)setRawRollFollowings:(NSArray *)rawRollFollowings
{
    //when current user is viewing own profile, we don't want to show them as a follower of themself
    User *currentUser = [[ShelbyDataMediator sharedInstance] fetchAuthenticatedUserOnMainThreadContext];
    NSString *creatorIdToIgnore = (self.user == currentUser) ? self.user.userID : nil;
    
    NSMutableDictionary *uniqueFollowings = [[NSMutableDictionary alloc] initWithCapacity:[rawRollFollowings count]];
    for (NSDictionary *rollInfo in rawRollFollowings) {
        //skip watch_later rolls (type 13), roll types > 16, and current user's own public roll (when viewing current user's rolls)
        if ([@(13) isEqualToNumber:rollInfo[@"roll_type"]] ||
            ([@(16) compare:rollInfo[@"roll_type"]] == NSOrderedAscending) ||
            [creatorIdToIgnore isEqualToString:rollInfo[@"creator_id"]]) {
            continue;
        }
        
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
    id rollFollowing = self.rawRollFollowings[indexPath.row];
    [self.delegate userProfileWasTapped:rollFollowing[@"creator_id"]];
    [ShelbyAnalyticsClient sendLocalyticsEvent:kLocalyticsEventNameUserProfileView
                                withAttributes:@{
                                                 kLocalyticsAttributeNameFromOrigin : kLocalyticsAttributeValueFromOriginFollowedRollsItem,
                                                 kLocalyticsAttributeNameUsername : rollFollowing[@"creator_nickname"]
                                                 }];
}

@end
