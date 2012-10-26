//
//  FirstViewController.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 10/17/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StreamViewController : UIViewController
<
UICollectionViewDataSource,
UICollectionViewDelegate,
UICollectionViewDelegateFlowLayout // Also references UICollectionViewDelegate
>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@end
