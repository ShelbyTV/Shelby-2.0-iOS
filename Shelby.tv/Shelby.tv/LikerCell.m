//
//  LikerCell.m
//  Shelby.tv
//
//  Created by Keren on 12/3/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "LikerCell.h"
#import "User+Helper.h"
#import "UIImageView+AFNetworking.h"

@interface LikerCell()
@property (nonatomic, strong) User *user;
@property (nonatomic, weak) IBOutlet UIImageView *avatar;
@property (nonatomic, weak) IBOutlet UILabel *nickname;
@property (nonatomic, weak) IBOutlet UILabel *name;
@end

@implementation LikerCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setupCellForLiker:(User *)user
{
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    self.user = user;
    self.name.text = user.name;
    self.nickname.text = user.nickname;
    self.user = user;
    NSURL *url = [user avatarURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    UIImage *defaultAvatar = [UIImage imageNamed:@"avatar-blank.png"];
    __weak LikerCell *weakSelf =  self;
    [self.avatar setImageWithURLRequest:request placeholderImage:defaultAvatar success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        weakSelf.avatar.image = image;
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        //ignore for now
    }];
}

@end
