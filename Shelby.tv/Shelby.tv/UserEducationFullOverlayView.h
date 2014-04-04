//
//  ShelbyUserEducationView.h
//  Shelby.tv
//
//  Created by Joshua Samberg on 3/26/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

// the different types of user education full overlay views
// that are available
typedef NS_ENUM(NSInteger, UserEducationFullOverlayViewType) {
    UserEducationFullOverlayViewTypeStream,
    UserEducationFullOverlayViewTypeChannels
};

@interface UserEducationFullOverlayView : UIView
// class factory method for constructing and obtaining view instances
+ (UserEducationFullOverlayView *)viewForType:(UserEducationFullOverlayViewType)type;
// class method for finding out whether a user has already seen a particular education overlay
+ (BOOL)isUserEducatedForType:(UserEducationFullOverlayViewType)overlayViewType;

// the type of user education overlay view encapsulated by an instance
@property (nonatomic) UserEducationFullOverlayViewType overlayViewType;
@end
