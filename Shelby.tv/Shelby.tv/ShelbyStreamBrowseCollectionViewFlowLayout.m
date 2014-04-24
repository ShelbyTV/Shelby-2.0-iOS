//
//  ShelbyStreamBrowseCollectionViewFlowLayout.m
//  Shelby.tv
//
//  Created by Joshua Samberg on 4/15/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyStreamBrowseCollectionViewFlowLayout.h"

@implementation ShelbyStreamBrowseCollectionViewFlowLayout

- (NSArray *)indexPathsToBeShown
{
    if (!_indexPathsToBeShown) {
        _indexPathsToBeShown = [[NSArray alloc] init];
    }

    return _indexPathsToBeShown;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes *attributes = [super layoutAttributesForItemAtIndexPath:indexPath];

    attributes.size = self.collectionView.frame.size;
    if ([self.indexPathsToBeShown count]) {

        attributes.hidden = YES;

        for (NSIndexPath *visibleIndexPath in self.indexPathsToBeShown) {
            if (visibleIndexPath.section == attributes.indexPath.section && visibleIndexPath.item == attributes.indexPath.item) {
                attributes.hidden = NO;
                break;
            }
        }
    } else {
        attributes.hidden = NO;
    }

    return attributes;
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSArray *attributesArray = [super layoutAttributesForElementsInRect:rect];

    for (UICollectionViewLayoutAttributes *attributes in attributesArray) {
        attributes.size = self.collectionView.frame.size;
        if ([self.indexPathsToBeShown count]) {
            attributes.hidden = YES;
            
            for (NSIndexPath *visibleIndexPath in self.indexPathsToBeShown) {
                if (visibleIndexPath.section == attributes.indexPath.section && visibleIndexPath.item == attributes.indexPath.item) {
                    attributes.hidden = NO;
                    break;
                }
            }
        } else {
            attributes.hidden = NO;
        }
    }

    return attributesArray;
}

@end
