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
#define kColorBlack                         [UIColor colorWithHex:@"333" andAlpha:1.0f]
#define kColorGray                          [UIColor colorWithHex:@"adadad" andAlpha:1.0f]
#define kColorGreen                         [UIColor colorWithHex:@"6fbe47" andAlpha:1.0f]
#define kColorWhite                         [UIColor colorWithHex:@"eee" andAlpha:1.0f]
