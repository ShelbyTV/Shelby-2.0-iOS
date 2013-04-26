//
//  SPVideoItemView.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 12/7/12.
//  Copyright (c) 2012 Shelby TV. All rights reserved.
//

@interface SPVideoItemView : UIView

@property (weak, nonatomic) IBOutlet TopAlignedLabel *videoTitleLabel;
@property (weak, nonatomic) IBOutlet TopAlignedLabel *videoSharerLabel;
@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImageView;

+ (CGFloat)width;
+ (CGFloat)height;

@end
