//
//  SPOverlayController.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/28/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

@class SPVideoReel;

@interface SPOverlayController : UIViewController

@property (strong, nonatomic) NSMutableArray *videoFrames;
@property (weak, nonatomic) IBOutlet UIButton *homeButton;

- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil
            videoReel:(SPVideoReel*)videoReel
       videoFrames:(NSMutableArray*)videoFrames;

@end