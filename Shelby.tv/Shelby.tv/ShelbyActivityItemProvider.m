//
//  ShelbyActivityItemProvider.m
//  Shelby.tv
//
//  Created by Keren on 5/20/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyActivityItemProvider.h"

@interface ShelbyActivityItemProvider()
@property (nonatomic, strong) NSString *shareText;
@end


@implementation ShelbyActivityItemProvider
- (id)initWithShareText:(NSString *)shareText
{
    self = [super init];
    if (self) {
        _shareText = shareText;
    }
    return self;
}

- (id)activityViewController:(UIActivityViewController *)activityViewController
         itemForActivityType:(NSString *)activityType
{
    // KP KP: TODO: once we have the different share text per service do something... 
    NSString *text = self.shareText;
    if ([activityType isEqualToString:UIActivityTypePostToTwitter]) {
    } else if ([activityType isEqualToString:UIActivityTypeMail]) {
    } else if ([activityType isEqualToString:UIActivityTypePostToFacebook]) {
    } else if ([activityType isEqualToString:UIActivityTypePostToTwitter]) {
    } else { // Generic
        
    }
    
    return text;
}
- (id)activityViewControllerPlaceholderItem:(UIActivityViewController *)activityViewController
{
    return @"";
}



@end
