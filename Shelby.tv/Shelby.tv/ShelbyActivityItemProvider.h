//
//  ShelbyActivityItemProvider.h
//  Shelby.tv
//
//  Created by Keren on 5/20/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ShelbyActivityItemProvider : UIActivityItemProvider <UIActivityItemSource>
- (id)initWithShareText:(NSString *)shareText;
@end
