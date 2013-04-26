//
//  CollectionViewGroupsLayout.h
//  Shelby.tv
//
//  Created by Keren on 2/15/13.
//  Copyright (c) 2013 Shelby TV. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kShelbyCollectionViewNumberOfCardsInMeSectionPage 4
#define kShelbyCollectionViewNumberOfCardsInGroupSectionPage 4

@interface CollectionViewGroupsLayout : UICollectionViewLayout

// Assuming 2 sections - Me and Channels
- (int)numberOfPages;
- (CGPoint)pointAtPage:(int)page;

@end
