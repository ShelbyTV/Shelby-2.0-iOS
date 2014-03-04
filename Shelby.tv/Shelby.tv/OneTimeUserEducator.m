//
//  OneTimeUserEducator.m
//  Shelby.tv
//
//  Created by Joshua Samberg on 2/27/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "OneTimeUserEducator.h"
#import "User.h"
#import "Roll+Helper.h"

@implementation OneTimeUserEducator
+ (void)doOneTimeFollowingUserEducationForUser:(User *)user whenDidFollow:(BOOL)didFollow roll:(NSString *)rollID
{

    NSString *receivedEducationBoolKey;
    if (didFollow) {
        receivedEducationBoolKey = kShelbyUserReceivedFollowRollEducationBoolKey;
    } else {
        receivedEducationBoolKey = kShelbyUserReceivedUnfollowRollEducationBoolKey;
    }

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if (![userDefaults boolForKey:receivedEducationBoolKey]) {
        // get the title of the roll that was followed or unfollowed to be displayed in the education message
        Roll *roll = [Roll rollWithID:rollID inContext:user.managedObjectContext];
        NSString *rollTitle;
        if (roll.displayTitle) {
            rollTitle = roll.displayTitle;
        } else if (roll.title) {
            rollTitle = roll.title;
        } else {
            rollTitle = @"this source";
        }

        // build an alert view and show it
        UIAlertView *alert;
        if (didFollow) {
            alert = [[UIAlertView alloc] initWithTitle:@"Followed!" message:[NSString stringWithFormat:@"We'll add new videos from %@ to your stream.", rollTitle] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        } else {
            alert = [[UIAlertView alloc] initWithTitle:@"Unfollowed!" message:[NSString stringWithFormat:@"You won't get any more videos from %@.", rollTitle] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        }
        [alert show];
        [userDefaults setBool:YES forKey:receivedEducationBoolKey];
        [userDefaults synchronize];
    }
}

+ (void)doOneTimeVideoLikingUserEducation
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if (![userDefaults boolForKey:kShelbyUserReceivedVideoLikingEducationBoolKey]) {
        UIAlertView *alert;

        alert = [[UIAlertView alloc] initWithTitle:@"Liked!" message:@"We'll use your likes to recommend videos to you in the future." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alert show];
        [userDefaults setBool:YES forKey:kShelbyUserReceivedVideoLikingEducationBoolKey];
        [userDefaults synchronize];
    }
}
@end
