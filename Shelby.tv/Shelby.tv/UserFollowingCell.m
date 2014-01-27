//
//  UserFollowingCell.m
//  Shelby.tv
//
//  Created by Dan Spinosa on 1/27/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "UserFollowingCell.h"
#import "AFNetworking.h"
#import "NSObject+NullHelper.h"

@interface UserFollowingCell()
@property (weak, nonatomic) IBOutlet UIImageView *thumbnailView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *detailLabel;

@end

@implementation UserFollowingCell

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

- (void)awakeFromNib
{
    self.thumbnailView.layer.cornerRadius = self.thumbnailView.bounds.size.width/2.f;
}

- (void)setRollFollowing:(NSDictionary *)rollFollowing
{
    if (_rollFollowing != rollFollowing) {
        _rollFollowing  =  rollFollowing;
        [self updateViewForData];
    }
}

- (void)updateViewForData
{
    self.titleLabel.text = [self.rollFollowing[@"creator_nickname"] nilOrSelfWhenNotNull];
    self.detailLabel.text = [self.rollFollowing[@"creator_name"] nilOrSelfWhenNotNull];
    self.thumbnailView.image = [UIImage imageNamed:@"default-blank-avatar"];
    
    //thumbnail...
    NSDictionary *rollFollowingAtRequestTime = self.rollFollowing;
    
    NSString *rollThumbnail = nil;
    if ([self.rollFollowing[@"creator_has_shelby_avatar"] boolValue]) {
        rollThumbnail = [NSString stringWithFormat:@"http://s3.amazonaws.com/shelby-gt-user-avatars/sq192x192/%@", self.rollFollowing[@"creator_id"]];
    }
    rollThumbnail = rollThumbnail ?: [self.rollFollowing[@"creator_image"] nilOrSelfWhenNotNull];
    rollThumbnail = rollThumbnail ?: [self.rollFollowing[@"thumbnail_url"] nilOrSelfWhenNotNull];
    
    if (rollThumbnail) {
        NSURLRequest *imageRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:rollThumbnail]];
        [[AFImageRequestOperation imageRequestOperationWithRequest:imageRequest imageProcessingBlock:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
            if (self.rollFollowing == rollFollowingAtRequestTime) {
                self.thumbnailView.image = image;
            }
        } failure:nil] start];
    }
}

@end
