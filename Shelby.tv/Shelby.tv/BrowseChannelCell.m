//
//  BrowseChannelCell.m
//  Shelby.tv
//
//  Created by Dan Spinosa on 1/20/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "BrowseChannelCell.h"
#import "AFNetworking.h"
#import "Roll.h"

@interface BrowseChannelCell()
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImageView;
@property (assign, nonatomic) BOOL userIsFollowingRoll;
@property (weak, nonatomic) IBOutlet UIButton *followButton;
@end

@implementation BrowseChannelCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {

    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.followButton.backgroundColor = kShelbyColorGreen;
    self.followButton.layer.cornerRadius = self.followButton.bounds.size.height / 8.f;
    self.thumbnailImageView.layer.cornerRadius = self.thumbnailImageView.bounds.size.width / 2.f;
    self.thumbnailImageView.clipsToBounds = YES;
}

- (void)prepareForReuse
{
    self.thumbnailImageView.image = nil;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setRoll:(Roll *)roll
{
    if (_roll != roll) {
        _roll = roll;
        
        //visual updates
        self.titleLabel.text = roll.displayTitle;
        self.descriptionLabel.text = roll.displayDescription;
        [self updateFollowStatus];
        [self fetchThumbnail];
    }
}

- (void)setUser:(User *)user
{
    if (_user != user) {
        _user = user;
        [self updateFollowStatus];
    }
}

- (void)updateFollowStatus
{
    self.userIsFollowingRoll = self.user && self.roll && [self.user isFollowing:self.roll.rollID];
    if (self.userIsFollowingRoll) {
        //show unfollow
        [self.followButton setTitle:@"Unfollow" forState:UIControlStateNormal];
        self.followButton.backgroundColor = kShelbyColorLightGray;
    } else {
        //show follow
        [self.followButton setTitle:@"Follow" forState:UIControlStateNormal];
        self.followButton.backgroundColor = kShelbyColorGreen;
    }
}

- (void)fetchThumbnail
{
    Roll *rollAtRequestTime = self.roll;
    NSURLRequest *imageRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:self.roll.thumbnailURL]];
    [[AFImageRequestOperation imageRequestOperationWithRequest:imageRequest imageProcessingBlock:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        if (self.roll == rollAtRequestTime) {
            self.thumbnailImageView.image = image;
        } else {
            //cell has been reused, do nothing
        }
    } failure:nil] start];
}

@end
