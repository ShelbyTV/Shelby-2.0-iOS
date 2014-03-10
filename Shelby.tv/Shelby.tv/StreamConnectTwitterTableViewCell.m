//
//  StreamConnectTwitterTableViewCell.m
//  Shelby.tv
//
//  Created by Dan Spinosa on 3/3/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "StreamConnectTwitterTableViewCell.h"
#import "ShelbyAnalyticsClient.h"

static NSString * const kStreamConnectTwitterUserWantsHidden = @"kStreamConnectTwitterUserWantsHidden";

@implementation StreamConnectTwitterTableViewCell

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
    return [[NSUserDefaults standardUserDefaults] boolForKey:kStreamConnectTwitterUserWantsHidden];
}

- (IBAction)hideTapped:(id)sender {
    [ShelbyAnalyticsClient sendLocalyticsEvent:kLocalyticsTapHideTwitterInStream];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES
               forKey:kStreamConnectTwitterUserWantsHidden];
    [defaults synchronize];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kShelbyStreamConnectTwitterVisibilityChangeNotification object:self];
}

@end
