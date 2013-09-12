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
    NSString *text = nil;
    if ([activityType isEqualToString:UIActivityTypePostToTwitter]) {
        text = [NSString stringWithFormat:@"Check it out: %@ via @Shelby TV", self.shareLink];
    } else if ([activityType isEqualToString:UIActivityTypeMail]) {
        text = [NSString stringWithFormat:@"Thought you'd be interested in \"%@\".\n\nCheck it out: %@\n\n\n--\nTry Shelby, it's like a TV channel personalized for you: http://shelby.tv", self.shareText, self.shareLink];
    } else {  // SMS and everything else
        text = [NSString stringWithFormat:@"Check it out: %@ via Shelby TV", self.shareLink];
    }
    
    return text;
}

- (NSString *)activityViewController:(UIActivityViewController *)activityViewController subjectForActivityType:(NSString *)activityType
{
    if ([activityType isEqualToString:UIActivityTypeMail]) {
        return [NSString stringWithFormat:@"video: %@", self.shareText];
    }
    return nil;
}

- (id)activityViewControllerPlaceholderItem:(UIActivityViewController *)activityViewController
{
    return @"";
}



@end
