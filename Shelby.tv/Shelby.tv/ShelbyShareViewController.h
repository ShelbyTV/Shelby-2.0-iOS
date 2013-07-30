//
//  ShelbyShareViewController.h
//  Shelby.tv
//
//  Created by Keren on 7/29/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ShelbyViewController.h"
#import "SPShareController.h"

@interface ShelbyShareViewController : ShelbyViewController <UITextViewDelegate>

- (void)setupShareWith:(Frame *)frame
                  link:(NSString *)link
    andShareController:(SPShareController *)shareController;
@end
