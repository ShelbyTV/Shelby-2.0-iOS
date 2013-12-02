//
//  ShelbyUserProfileCell.h
//  Shelby.tv
//
//  Created by Keren on 11/29/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ShelbyUserProfileCell : UICollectionViewCell
@property (nonatomic, weak) IBOutlet UIImageView *avatar;
@property (nonatomic, weak) IBOutlet UILabel *name;
@property (nonatomic, weak) IBOutlet UILabel *nickname;
@end
