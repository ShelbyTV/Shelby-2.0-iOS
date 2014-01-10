//
//  ShelbyStreamEntryCell.m
//  Shelby.tv
//
//  Created by Keren on 1/9/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyStreamEntryCell.h"
#import "Frame+Helper.h"
#import "UIImageView+AFNetworking.h"
#import "User+Helper.h"
#import "Video.h"

@interface ShelbyStreamEntryCell()
@property (nonatomic, weak) IBOutlet UILabel *videoTitle;
@property (nonatomic, weak) IBOutlet UIImageView *videoThumbnail;
@property (nonatomic, weak) IBOutlet UIImageView *userAvatar;
@property (nonatomic, weak) IBOutlet UILabel *description;

- (IBAction)shareVideo:(id)sender;
- (IBAction)toggleLike:(id)sender;
- (IBAction)openUserProfile:(id)sender;
@end

@implementation ShelbyStreamEntryCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
    }
    return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setVideoFrame:(Frame *)videoFrame
{
    _videoFrame = videoFrame;
    
    self.videoTitle.text = self.videoFrame.video.title;
    NSString *captionText = [videoFrame creatorsInitialCommentWithFallback:YES];
    self.description.text = captionText;
    NSURLRequest *thumbnailURLRequst = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:videoFrame.video.thumbnailURL]];
 
    __weak ShelbyStreamEntryCell *weakSelf = self;
    [self.videoThumbnail setImageWithURLRequest:thumbnailURLRequst placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        weakSelf.videoThumbnail.image = image;
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        
    }];
    
    NSURLRequest *avatarURLRequst = [[NSURLRequest alloc] initWithURL:[videoFrame.creator avatarURL]];
    [self.userAvatar setImageWithURLRequest:avatarURLRequst placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        weakSelf.userAvatar.image = image;
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        
    }];
    
}

- (IBAction)shareVideo:(id)sender
{
    [self.delegate shareVideoWasTappedForFrame:self.videoFrame];
}

- (IBAction)toggleLike:(id)sender
{
    [self.delegate toggleLikeForFrame:self.videoFrame];
}

- (IBAction)openUserProfile:(id)sender
{
    [self.delegate userProfileWasTapped:self.videoFrame.creator.userID];
}


@end
