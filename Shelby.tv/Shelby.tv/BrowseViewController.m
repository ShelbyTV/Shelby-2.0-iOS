//
//  BrowseViewController.m
//  Shelby.tv
//
//  Created by Keren on 2/13/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import "BrowseViewController.h"
#import "ChannelViewCell.h"
#import "MeViewController.h"

@interface BrowseViewController ()

@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@end

@implementation BrowseViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - View Lifecycle Methods
- (void)viewDidLoad
{
    [super viewDidLoad];

    UINib *cellNib = [UINib nibWithNibName:@"ChannelViewCell" bundle:nil];
    [self.collectionView registerNib:cellNib forCellWithReuseIdentifier:@"ChannelViewCell"];

    [self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"Default-Landscape.png"]]];
    
    [self.versionLabel setFont:[UIFont fontWithName:@"Ubuntu-Bold" size:_versionLabel.font.pointSize]];
    [self.versionLabel setText:[NSString stringWithFormat:@"Shelby.tv for iPad v%@", kShelbyCurrentVersion]];
    [self.versionLabel setTextColor:kShelbyColorBlack];
}

// TODO: factor the data source delegete methods to a model class.
#pragma mark - UICollectionView Datasource
- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section
{
    
    if (section == 0) {
        return 4;
    } else {
        return 8;
    }

}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView
{
    return 2;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ChannelViewCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"ChannelViewCell" forIndexPath:indexPath];

    NSString *name = nil;
    NSString *description = nil;
    int row = indexPath.row;
    if (indexPath.section == 0) {
        if (row == 0) {
            name = @"Likes";
            description = @"Add videos to your likes so you can come back to them and watch them in Shelby at a later time.";
        } else if (row == 2) {
            name = @"My Roll";
            description = @"Ever want to curate your own channel? Now you can with Shelby. Roll Videos to your .TV today.";
        } else if (row == 1) {
            name = @"Stream";
            description = @"Watch videos from the people in your Shelby, Facebook, and Twitter networks";
        } else if (row == 3) {
            name = @"Login";
            description = @"Ain't nothin' but a gangsta party!";
        }
    } else {
        name = [NSString stringWithFormat:@"Channel %d", row];
        description = [NSString stringWithFormat:@"Channel %d description", row];
    }
    
    [cell.channelName setText:name];
    [cell.channelDescription setText:description];
    
    return cell;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    // TODO: Select Item
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    // TODO: Deselect item
}


@end
