//
//  User+Helper.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 4/30/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "User.h"

@interface User (Helper)

//return the current, authenticated User, or nil if user isn't logged in
+(User *)currentAuthenticatedUserInContext:(NSManagedObjectContext *)moc;

@end
