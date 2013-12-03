//
//  ShelbyLikersViewController.m
//  Shelby.tv
//
//  Created by Keren on 12/2/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyLikersViewController.h"
#import "User+Helper.h"
#import "UIImageView+AFNetworking.h"

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
    [self.delegate followUser:user.publicRollID];
}

#pragma mark - UITableViewDataSource Delegate Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.likers count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    LikerCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LikerViewCell" forIndexPath:indexPath];
    
    User *user = self.likers[indexPath.row];
    
    cell.name.text = user.name;
    cell.nickname.text = user.nickname;
    cell.user = user;
    cell.delegate = self;
    NSURL *url = [user avatarURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    UIImage *defaultAvatar = [UIImage imageNamed:@"avatar-blank.png"];
    __weak LikerCell *weakCell =  cell;
    [cell.avatar setImageWithURLRequest:request placeholderImage:defaultAvatar success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        weakCell.avatar.image = image;
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        //ignore for now
    }];

    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    User *user = self.likers[indexPath.row];
    
    [self.delegate userProfileWasTapped:user.userID];
}

@end
