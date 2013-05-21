//
//  ShelbyActivityItemProvider.m
//  Shelby.tv
//
//  Created by Keren on 5/20/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyActivityItemProvider.h"

#ifdef SHELBY_ENTERPRISE
#define kShelbyDownloadLink @"http://shl.by/downloadApp"
#else
// KP KP: TODO: need short link for App Store.
#define kShelbyDownloadLink @"http://shl.by/downloadApp"
#endif

@interface ShelbyActivityItemProvider()
@property (nonatomic, strong) NSString *shareText;
@property (nonatomic, strong) NSString *shareLink;
@end


@implementation ShelbyActivityItemProvider
- (id)initWithShareText:(NSString *)shareText andShareLink:(NSString *)shareLink
{
    self = [super init];
    if (self) {
        _shareText = shareText;
        _shareLink = shareLink;
    }
    return self;
}

- (id)activityViewController:(UIActivityViewController *)activityViewController
         itemForActivityType:(NSString *)activityType
{
    // KP KP: TODO: once we have the different share text per service do something... 
    NSString *text = nil;
    if ([activityType isEqualToString:UIActivityTypePostToTwitter]) {
        text = [NSString stringWithFormat:@"I just watched an awesome video on @Shelby TV %@", self.shareLink];
    } else if ([activityType isEqualToString:UIActivityTypeMail]) {
        text = [NSString stringWithFormat:@"I just watched \"%@\" on Shelby TV.\n\nWatch this awesome video: %@\n\n--\n\nShelby TV is your hub for videos that matter to you, your friends and the world around you.", self.shareText, self.shareLink];
    } else {  // SMS and everything else
        text = [NSString stringWithFormat:@"I just watched an awesome video on Shelby TV %@", self.shareLink];
    }
    
    return text;
}
- (id)activityViewControllerPlaceholderItem:(UIActivityViewController *)activityViewController
{
    return @"";
}



@end
