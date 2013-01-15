//
//  Constants.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 10/17/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import "APIConstants.h"
#import "CoreDataConstants.h"
#import "Structures.h"
#import "SPConstants.h"

// Misc.
#define kCurrentVersion                     [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleVersionKey]

// NSUserDefault Constants
#define kUserAuthorizedDefault              @"Shelby User Authorization Stored Default"

// Colors
#define kColorBlack                         [UIColor colorWithRed:51.0f/255.0f green:51.0f/255.0f blue:51.0f/255.0f alpha:1.0f]
#define kColorGray                          [UIColor colorWithRed:173.0f/255.0f green:173.0f/255.0f blue:173.0f/255.0f alpha:1.0f]
#define kColorGreen                         [UIColor colorWithRed:103.0f/255.0f green:189.0f/255.0f blue:87.0f/255.0f alpha:1.0f]
#define kColorWhite                         [UIColor colorWithRed:238.0f/255.0f green:238.0f/255.0f blue:238.0f/255.0f alpha:1.0f]