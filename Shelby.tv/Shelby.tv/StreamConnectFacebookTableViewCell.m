//
//  StreamConnectFacebookTableViewCell.m
//  Shelby.tv
//
//  Created by Dan Spinosa on 2/20/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "StreamConnectFacebookTableViewCell.h"
#import "ShelbyAnalyticsClient.h"

static NSString * const kStreamConnectFacebookUserWantsHidden = @"kStreamConnectFacebookUserWantsHidden";

@implementation StreamConnectFacebookTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

+ (CGFloat)cellHeight
{
    return 140.f;
}

+ (BOOL)userWantsHidden
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kStreamConnectFacebookUserWantsHidden];
}

- (IBAction)hideTapped:(id)sender {
    [ShelbyAnalyticsClient sendLocalyticsEvent:kLocalyticsTapHideFacebookInStream];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES
               forKey:kStreamConnectFacebookUserWantsHidden];
    [defaults synchronize];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kShelbyStreamConnectFacebookVisibilityChangeNotification object:self];
}

@end
