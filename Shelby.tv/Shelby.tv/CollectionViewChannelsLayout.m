//
//  ChannelsCollectionViewLayout.m
//  Shelby.tv
//
//  Created by Keren on 2/15/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

// The Layout works as follows:
// Two columns per screen, 4 in first section, rest in second section.
/// Indexes:
//  0 2 4 6 8 10
//  1 3 5 7 9 11 ...

#import "CollectionViewChannelsLayout.h"
@interface CollectionViewChannelsLayout()

@property(nonatomic,strong) NSMutableArray* layoutAttributes;  // array of UICollectionViewLayoutAttributes

@end


@implementation CollectionViewChannelsLayout


#pragma mark - Memory Management Methods
- (void)dealloc
{
    [_layoutAttributes removeAllObjects];
    _layoutAttributes = nil;
}

#pragma mark - UICollectionViewLayout Methods
- (void)prepareLayout
{
    int count = 12; // TODO: should not hardcode
    _layoutAttributes = [NSMutableArray arrayWithCapacity:count];
    
    int screen = 0;
    
    int xOffset = 0;
    int yOffset = 34;

    for (int i = 0; i < count; i++) {
        if (i != 0 && (i % 4 == 0)) {
            screen += 1024;
        }
        int row = 0;
        int section = 0;
        if (i < 4) {
            row = i;
        } else {
            row = i - 4;
            section = 1;
        }
 
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:row inSection:section];
        UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
        
        if (i % 2 == 1) {
            yOffset = 372;
        } else if (i != 0) {
            xOffset += 502;
            yOffset = 34;
        }
        
        if (i % 4 == 0) {
            xOffset += 20;
        }
        
        attributes.frame = CGRectMake(xOffset, yOffset, 482, 318);
        
        [self.layoutAttributes addObject:attributes];
    }
}

- (CGSize)collectionViewContentSize
{
    return CGSizeMake(1024 * 3, 714);
}


- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    int index = indexPath.row;
    if (indexPath.section == 1) {
        index += 4;
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

