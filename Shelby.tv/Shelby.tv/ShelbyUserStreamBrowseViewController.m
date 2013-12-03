//
//  ShelbyUserStreamBrowseViewController.m
//  Shelby.tv
//
//  Created by Keren on 11/29/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyUserStreamBrowseViewController.h"
#import "ShelbyUserProfileCell.h"

@interface ShelbyUserStreamBrowseViewController ()

@end

@implementation ShelbyUserStreamBrowseViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // KP KP: Will be needed when we have 2 sections
//    self.collectionView.pagingEnabled = NO;

//    [self.collectionView registerClass:[ShelbyUserProfileCell class] forCellWithReuseIdentifier:@"ShelbyUserProfileCell"];

    // KP KP: Will be needed when we have 2 sections
//    [self.collectionView registerNib:[UINib nibWithNibName:@"ShelbyUserProfileCell" bundle:nil] forCellWithReuseIdentifier:@"ShelbyUserProfileCell"];

}

- (void)setUser:(User *)user
{
    _user = user;
   
    // KP KP: Will be needed when we have 2 sections
//    [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
}

// KP KP: Will be needed when we have 2 sections
/*
- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section
{
    
    if (section == 1) {
       return [super collectionView:view numberOfItemsInSection:section];
    } else {
        return 1;
    }
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView
{
    return 2;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1) {
        return [super collectionView:cv cellForItemAtIndexPath:indexPath];
    }
    
    ShelbyUserProfileCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"ShelbyUserProfileCell" forIndexPath:indexPath];
    
    cell.name.text = self.currentUser.name;
    cell.nickname.text = self.currentUser.nickname;
    
    return cell;
}

- (NSInteger)sectionForVideoCards
{
    return 1;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1) {
        return [super collectionView:collectionView layout:collectionViewLayout sizeForItemAtIndexPath:indexPath];
    }
    
    return CGSizeMake(320, 140);
}
 
 */

@end
