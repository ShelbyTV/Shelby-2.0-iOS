//
//  ChannelsCollectionViewLayout.h
//  Shelby.tv
//
//  Created by Keren on 2/15/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kShelbyCollectionViewNumberOfCardsInMeSectionPage 4
#define kShelbyCollectionViewNumberOfCardsInChannelSectionPage 4

@interface CollectionViewChannelsLayout : UICollectionViewLayout

// Assuming 2 sections - Me and Channels
- (int)numberOfPages;

@end
