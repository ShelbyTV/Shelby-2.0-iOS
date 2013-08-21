//
//  ShelbyAirPlayController.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 8/21/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SPVideoPlayer.h"

@protocol ShelbyAirPlayControllerDelegate;

@interface ShelbyAirPlayController : NSObject
@property (nonatomic, weak) id<ShelbyAirPlayControllerDelegate> delegate;

- (BOOL)isAirPlayActive;
- (void)playEntity:(id<ShelbyVideoContainer>)entity;
@end

@protocol ShelbyAirPlayControllerDelegate <NSObject>
- (void)airPlayControllerDidBeginAirPlay:(ShelbyAirPlayController *)airPlayController;
- (void)airPlayControllerDidEndAirPlay:(ShelbyAirPlayController *)airPlayController;
@end