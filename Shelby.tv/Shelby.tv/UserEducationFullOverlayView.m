//
//  ShelbyUserEducationView.m
//  Shelby.tv
//
//  Created by Joshua Samberg on 3/26/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "UserEducationFullOverlayView.h"

static NSDictionary *typeToNibMap;

@implementation UserEducationFullOverlayView

+ (void)initialize {
    typeToNibMap =
        @{
          [NSNumber numberWithInteger:UserEducationFullOverlayViewTypeStream] : @"StreamUserEducationFullOverlay",
          [NSNumber numberWithInteger:UserEducationFullOverlayViewTypeChannels] : @"ChannelsUserEducationFullOverlay",
          [NSNumber numberWithInteger:UserEducationFullOverlayViewTypeTwoColumn] : @"TwoColumnUserEducationFullOverlay"
          };
}

+ (UserEducationFullOverlayView *)viewForType:(UserEducationFullOverlayViewType)overlayViewType
{
    NSString *nibName = [typeToNibMap objectForKey:[NSNumber numberWithInteger:overlayViewType]];
    if (nibName && ![UserEducationFullOverlayView isUserEducatedForType:overlayViewType]) {
        UserEducationFullOverlayView *view = [[NSBundle mainBundle] loadNibNamed:nibName owner:nil options:nil][0];
        view.overlayViewType = overlayViewType;
        return view;
    }

    return nil;
}

+ (BOOL)isUserEducatedForType:(UserEducationFullOverlayViewType)overlayViewType
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:[NSString stringWithFormat:@"%@%@", kShelbyUserEducationDefaultsKeyPrefix, [NSNumber numberWithInteger:overlayViewType]]];
}

+ (void)setUserIsEducatedForType:(UserEducationFullOverlayViewType)overlayViewType
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:[NSString stringWithFormat:@"%@%@", kShelbyUserEducationDefaultsKeyPrefix, [NSNumber numberWithInteger:overlayViewType]]];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

// if someone touches inside us, remove ourself and pass on to things underneath us
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    [self removeFromSuperview];
    // set user default to note that the user has seen this type of overlay and doesn't need to be educated again
    [UserEducationFullOverlayView setUserIsEducatedForType:self.overlayViewType];

    return NO;
}

@end
