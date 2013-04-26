//
//  SPTutorialView.m
//  Shelby.tv
//
//  Created by Keren on 4/19/13.
//  Copyright (c) 2013 Shelby TV. All rights reserved.
//

#import "SPTutorialView.h"
@interface SPTutorialView()
@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UILabel *text;
@end


@implementation SPTutorialView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}
- (void)setupWithImage:(NSString *)image andText:(NSString *)text
{
    [self.imageView setImage:[UIImage imageNamed:image]];
    [self.text setText:text];
}

@end
