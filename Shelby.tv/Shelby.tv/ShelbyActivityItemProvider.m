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
        text = [NSString stringWithFormat:@"Just watched this video on @Shelby TV for iPad %@", self.shareLink];
    } else if ([activityType isEqualToString:UIActivityTypeMail]) {
        text = [NSString stringWithFormat:@"I just watched \"%@\" on Shelby TV.\n\nWatch it now: %@\n\n--\n\nWatch videos you'll love - www.shelby.tv\n\n on the iPad too - %@\n\n\nShelby TV is your hub for videos that matter to you, your friends and the world around you.", self.shareText, self.shareLink, kShelbyDownloadLink];
    } else {  // SMS and everything else
        text = [NSString stringWithFormat:@"Just watched this video on Shelby TV for iPad %@", self.shareLink];
    }
    
    return text;
}
- (id)activityViewControllerPlaceholderItem:(UIActivityViewController *)activityViewController
{
    return @"";
}



@end
