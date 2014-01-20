//
//  TopLevelNavigationCell.h
//  Shelby.tv
//
//  Created by Dan Spinosa on 1/20/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TopLevelNavigationCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

- (void)setBadge:(NSUInteger)count;

@end
