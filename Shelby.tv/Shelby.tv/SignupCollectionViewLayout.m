//
//  SignupCollectionViewLayout.m
//  Shelby.tv
//
//  Created by Keren on 7/8/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "SignupCollectionViewLayout.h"

#define kShelbySignupCollectionViewCellWidth 160
#define kShelbySignupCollectionViewCellHeight 160

@interface SignupCollectionViewLayout()

@property(nonatomic,strong) NSMutableArray* layoutAttributes;  // array of UICollectionViewLayoutAttributes
@end


@implementation SignupCollectionViewLayout
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

// TODO: assuming one section for now
#pragma mark - UICollectionViewLayout Methods
- (void)prepareLayout
{
    int count = [self numberOfCells];
    
    _layoutAttributes = [NSMutableArray arrayWithCapacity:count];
    
    int xOffset = 0;
    int yOffset = 0;
    
    for (int i = 0; i < count; i++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
        UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
        
        if (i % 2 == 0) {
            xOffset = 0;
        } else {
            xOffset = kShelbySignupCollectionViewCellWidth;
        }
        
        attributes.frame = CGRectMake(xOffset, yOffset, kShelbySignupCollectionViewCellWidth, kShelbySignupCollectionViewCellHeight);
        
        [self.layoutAttributes addObject:attributes];
        
        if (i % 2 != 0) {
            yOffset += kShelbySignupCollectionViewCellHeight;
        }
    }
}

- (CGSize)collectionViewContentSize
{
    NSInteger numberOfCells = [self numberOfCells];
    
    return CGSizeMake(kShelbySignupCollectionViewCellWidth * 2, kShelbySignupCollectionViewCellHeight * (numberOfCells / 2 + numberOfCells % 2));
}


- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    int index = indexPath.row;

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
