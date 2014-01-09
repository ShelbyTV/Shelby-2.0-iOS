//
//  ShelbyStreamEntryCell.m
//  Shelby.tv
//
//  Created by Keren on 1/9/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyStreamEntryCell.h"
#import "Video.h"
#import "UIImageView+AFNetworking.h"

@interface ShelbyStreamEntryCell()
@property (nonatomic, strong) IBOutlet UILabel *videoTitle;
@property (nonatomic, strong) IBOutlet UIImageView *videoThumbnail;
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
    NSURLRequest *urlRequst = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:videoFrame.video.thumbnailURL]];
 
    __weak ShelbyStreamEntryCell *weakSelf = self;
    [self.videoThumbnail setImageWithURLRequest:urlRequst placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        weakSelf.videoThumbnail.image = image;
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        
    }];
}

@end
