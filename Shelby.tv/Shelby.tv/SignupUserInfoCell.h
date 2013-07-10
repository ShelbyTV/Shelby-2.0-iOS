//
//  SignupUserInfoCell.h
//  Shelby.tv
//
//  Created by Keren on 7/10/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol SignupUserInfoDelegate
- (void)assignAvatar;
@end

@interface SignupUserInfoCell : UICollectionViewCell
@property (nonatomic, weak) IBOutlet UIImageView *avatar;
@property (nonatomic, weak) IBOutlet UILabel *name;
@property (nonatomic, weak) id<SignupUserInfoDelegate> delegate;

@end
