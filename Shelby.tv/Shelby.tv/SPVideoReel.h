//
//  SPVideoReel
//  ShelbyPlayer
//
//  Created by Arthur Ariel Sabintsev on 11/1/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

@interface SPVideoReel : UIViewController <UIScrollViewDelegate>

@property (strong, nonatomic) UIScrollView *scrollView;

- (id)initWithVideoFrames:(NSArray*)videoFrames;

@end