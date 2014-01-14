//
//  VideoOverlayView.m
//  Shelby.tv
//
//  Created by Dan Spinosa on 1/13/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "VideoOverlayView.h"
#import "Frame+Helper.h"
#import "User+Helper.h"

@interface VideoOverlayView()
@property (weak, nonatomic) IBOutlet UILabel *videoTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *userLabel;
@property (weak, nonatomic) IBOutlet UILabel *likesCountLabel;
@end

@implementation VideoOverlayView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setCurrentEntity:(id<ShelbyVideoContainer>)entity
{
    if (_currentEntity != entity) {
        _currentEntity = entity;
        [self updateViewForNewEntity];
    }
}

- (void)updateViewForNewEntity
{
    Frame *f = [Frame frameForEntity:self.currentEntity];
    
    // Title
    self.videoTitleLabel.text = f.video.title;
    
    //avatar badge + via network
    UIImage *badgeImage;
    NSString *viaNetwork = nil;
    if ([f typeOfFrame] == FrameTypeLightWeight) {
        badgeImage = [UIImage imageNamed:@"avatar-badge-heart"];
    } else if ([f.creator isNonShelbyFacebookUser]) {
        badgeImage = [UIImage imageNamed:@"avatar-badge-facebook"];
        viaNetwork = @"facebook";
    } else if ([f.creator isNonShelbyTwitterUser]) {
        badgeImage = [UIImage imageNamed:@"avatar-badge-twitter"];
        viaNetwork = @"twitter";
    } else {
        badgeImage = nil;
    }
    
    //TODO: show the badge (or kill it)
    
    //user
    self.userLabel.attributedText = [self usernameStringFor:f withNetwork:viaNetwork];
    
    //likes
    self.likesCountLabel.text = [NSString stringWithFormat:@"%i likes", [f.video.trackedLikerCount intValue]];
}

- (NSAttributedString *)usernameStringFor:(Frame *)f withNetwork:(NSString *)viaNetwork
{
    NSString *nick = f.creator.nickname ? f.creator.nickname : @"reco";
    NSString *baseString;
    if (f.typeOfFrame == FrameTypeLightWeight) {
        baseString = [NSString stringWithFormat:@"%@ liked this", f.creator.nickname];
    } else {
        baseString = nick;
    }
    
    if (viaNetwork) {
        baseString = [NSString stringWithFormat:@"%@ via %@", baseString, viaNetwork];
    }
    
    NSMutableAttributedString *usernameString = [[NSMutableAttributedString alloc] initWithString:baseString attributes:@{NSFontAttributeName: kShelbyBodyFont2, NSForegroundColorAttributeName: kShelbyColorWhite}];
    [usernameString addAttributes:@{NSFontAttributeName: kShelbyBodyFont2Bold}
                            range:[baseString rangeOfString:nick]];
    
    return usernameString;
}

//to allow touch events to pass through the background
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    return NO;
}

@end
