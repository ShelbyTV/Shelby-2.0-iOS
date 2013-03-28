//
//  GroupTableViewCell.h
//  Shelby.tv
//
//  Created by Keren on 3/28/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GroupTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *groupDescription;
@property (weak, nonatomic) IBOutlet UILabel *groupTitle;

- (void)enableCard:(BOOL)enabled;

@end
