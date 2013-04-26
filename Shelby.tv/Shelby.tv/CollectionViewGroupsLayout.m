//
//  CollectionViewGroupsLayout.m
//  Shelby.tv
//
//  Created by Keren on 2/15/13.
//  Copyright (c) 2013 Shelby TV. All rights reserved.
//

// The Layout works as follows:
// Two columns per screen, 4 in first section, rest in second section.
/// Indexes:
//  0 2 4 6 8 10
//  1 3 5 7 9 11 ...

#import "CollectionViewGroupsLayout.h"

#define kShelbyCollectionViewPageWidth 1024
#define kShelbyCollectionViewPageHeight 714

#define kShelbyCollectionViewCellWidth 482
#define kShelbyCollectionViewCellHeight 318
#define kShelbyCollectionViewCellSpacing 20

#define kShelbyCollectionViewFirstRowYOffset 34
#define kShelbyCollectionViewSecondRowYOffset 372

@interface CollectionViewGroupsLayout ()

@property(nonatomic,strong) NSMutableArray* layoutAttributes;  // array of UICollectionViewLayoutAttributes

- (int)numberOfCells;

@end


@implementation CollectionViewGroupsLayout


#pragma mark - Public Methods
// Assuming 2 sections - Me and Channels
- (int)numberOfPages
{
    int pages = 0;
    int meSectionCount = [self.collectionView numberOfItemsInSection:0];
    if (meSectionCount % kShelbyCollectionViewNumberOfCardsInMeSectionPage != 0) {
        pages++;
    }
    pages += meSectionCount / kShelbyCollectionViewNumberOfCardsInMeSectionPage;
    
    int channelSectionCount = [self.collectionView numberOfItemsInSection:1];
    if (channelSectionCount % kShelbyCollectionViewNumberOfCardsInGroupSectionPage != 0) {
        pages++;
    }
    pages += channelSectionCount / kShelbyCollectionViewNumberOfCardsInGroupSectionPage;
    
    return pages;
}


- (CGPoint)pointAtPage:(int)page
{
    return CGPointMake((kShelbyCollectionViewPageWidth * page), 0);
}

#pragma mark - Private Methods
- (int)numberOfCells
{
    int count = 0;
    int numberOfSections = [self.collectionView numberOfSections];
    for (int i = 0; i < numberOfSections; i++) {
        count += [self.collectionView numberOfItemsInSection:i];
    }
    
    return count;
}

#pragma mark - Memory Management Methods
- (void)dealloc
{
    [_layoutAttributes removeAllObjects];
    _layoutAttributes = nil;
}

#pragma mark - UICollectionViewLayout Methods
- (void)prepareLayout
{
    int count = [self numberOfCells];

    _layoutAttributes = [NSMutableArray arrayWithCapacity:count];
    
    int screen = 0;
    
    int xOffset = 0;
    int yOffset = kShelbyCollectionViewFirstRowYOffset;

    for (int i = 0; i < count; i++) {
        if (i != 0 && (i - kShelbyCollectionViewNumberOfCardsInMeSectionPage) % kShelbyCollectionViewNumberOfCardsInGroupSectionPage == 0) {
            screen += kShelbyCollectionViewPageWidth;
        }
        int row = 0;
        int section = 0;
        if (i < kShelbyCollectionViewNumberOfCardsInMeSectionPage) {
            row = i;
        } else {
            row = i - kShelbyCollectionViewNumberOfCardsInMeSectionPage;
            section = 1;
        }
 
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:row inSection:section];
        UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
        
        if (i % 2 == 1) {
            yOffset = kShelbyCollectionViewSecondRowYOffset;
        } else if (i != 0) {
            xOffset += kShelbyCollectionViewCellWidth + kShelbyCollectionViewCellSpacing;
            yOffset = kShelbyCollectionViewFirstRowYOffset;
        }
        
        if ((i - kShelbyCollectionViewNumberOfCardsInMeSectionPage) % kShelbyCollectionViewNumberOfCardsInGroupSectionPage  == 0) {
            xOffset += kShelbyCollectionViewCellSpacing;
        }
        
        attributes.frame = CGRectMake(xOffset, yOffset, kShelbyCollectionViewCellWidth, kShelbyCollectionViewCellHeight);
        
        [self.layoutAttributes addObject:attributes];
    }
}

- (CGSize)collectionViewContentSize
{
    return CGSizeMake(kShelbyCollectionViewPageWidth * [self numberOfPages], kShelbyCollectionViewPageHeight);
}


- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    int index = indexPath.row;
    if (indexPath.section == 1) {
        index += kShelbyCollectionViewNumberOfCardsInMeSectionPage;
    }
    
    return self.layoutAttributes[index];
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{ 
    return [self.layoutAttributes filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(UICollectionViewLayoutAttributes *evaluatedObject, NSDictionary *bindings) {
        return CGRectIntersectsRect(rect, [evaluatedObject frame]);
    }]];
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    return NO;
}

@end

