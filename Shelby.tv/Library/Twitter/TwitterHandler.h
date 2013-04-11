//
//  TwitterHandler.h
//  TwitterHandler
//
//  Created by Arthur Ariel Sabintsev on 4/18/12.
//  Copyright (c) 2012 ArtSabintsev. All rights reserved.
//

#define kShelbyTwitterConsumerKey       @"5DNrVZpdIwhQthCJJXCfnQ"
#define kShelbyTwitterConsumerSecret    @"Tlb35nblFFTZRidpu36Uo3z9mfcvSVv1MuZZ19SHaU"

@interface TwitterHandler : NSObject

- (id)initWithViewController:(UIViewController *)viewController;
- (void)authenticate;

@end
