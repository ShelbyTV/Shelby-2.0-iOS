//
//  NSObject+nilInsteadOfNull.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 5/22/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (NullHelper)

// Returns nil if self is [NSNull null], otherwise returns self.
//
// Useful when dealing with setting attributes on NSManagedObjects
// and you want to set them as nil but JSON translated to NSNull.
- (id) nilOrSelfWhenNotNull;

@end
