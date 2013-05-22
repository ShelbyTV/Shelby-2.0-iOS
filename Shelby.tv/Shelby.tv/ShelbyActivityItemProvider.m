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
        text = [NSString stringWithFormat:@"This video just blew my mind %@ via @Shelby TV", self.shareLink];
    } else if ([activityType isEqualToString:UIActivityTypeMail]) {
        text = [NSString stringWithFormat:@"I just watched \"%@\".\n\nCheck out this awesome video: %@\n\nAnd one last thing, watch video you'll love on Shelby TV. http://www.shelby.tv", self.shareText, self.shareLink];
    } else {  // SMS and everything else
        text = [NSString stringWithFormat:@"This video just blew my mind %@ via Shelby TV", self.shareLink];
    }
    
    return text;
}
- (id)activityViewControllerPlaceholderItem:(UIActivityViewController *)activityViewController
{
    return @"";
}



@end
