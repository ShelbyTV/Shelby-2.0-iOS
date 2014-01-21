//
//  BrowseChannelsHeaderView.m
//  Shelby.tv
//
//  Created by Dan Spinosa on 1/21/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "BrowseChannelsHeaderView.h"

@interface BrowseChannelsHeaderView()
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (assign, nonatomic) NSUInteger followCount;
@end

#define TARGET_FOLLOW_COUNT 3.0

@implementation BrowseChannelsHeaderView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {

    }
    return self;
}

- (void)awakeFromNib
{
    self.progressView.layer.cornerRadius = 5.f;
    self.progressView.clipsToBounds = YES;
}

- (BOOL)hitTargetFollowCount
{
    return self.followCount > TARGET_FOLLOW_COUNT;
}

- (void)resetFollowCount
{
    self.followCount = 0;
    [self followCountUpdated];
}

- (void)increaseFollowCount
{
    self.followCount++;
    [self followCountUpdated];
}

- (void)decreaseFollowCount
{
    self.followCount--;
    [self followCountUpdated];
}

- (void)followCountUpdated
{
    self.progressView.progress = MAX(1.0, self.followCount/TARGET_FOLLOW_COUNT);
    
    if ([self hitTargetFollowCount]) {
        self.label.text = @"Nice!  Head back to your stream to start watching.";
    } else {
        self.label.text = @"For great content, follow a few of our curated channels.";
    }
}

@end
