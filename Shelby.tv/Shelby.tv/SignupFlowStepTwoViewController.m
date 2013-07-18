//
//  SignupFlowStepTwoViewController.m
//  Shelby.tv
//
//  Created by Keren on 7/17/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "SignupFlowStepTwoViewController.h"
#import "SignupVideoTypeViewCell.h"

@interface SignupFlowStepTwoViewController ()
@end

@implementation SignupFlowStepTwoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString *)signupStepNumber
{
    return @"2";
}

- (void)markCellAtIndexPath:(NSIndexPath *)indexPath selected:(BOOL)selected
{
    UICollectionViewCell *cell = [self.videoTypes cellForItemAtIndexPath:indexPath];
    [self markCell:cell selected:selected];
}

- (void)markCell:(UICollectionViewCell *)cell selected:(BOOL)selected
{
    SignupVideoTypeViewCell *videoTypeCell = (SignupVideoTypeViewCell *)cell;
    
    videoTypeCell.overlay.hidden = !selected;
    
    if (selected) {
        cell.contentView.layer.borderColor = [UIColor greenColor].CGColor;
        cell.contentView.layer.borderWidth = 5;
    } else {
        cell.contentView.layer.borderWidth = 0;
    }
}

- (void)toggleCellSelectionForIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        //can't select the info section
        return;
    }
    
    BOOL selected = NO;
    SignupVideoTypeViewCell *cell = (SignupVideoTypeViewCell *)[self.videoTypes cellForItemAtIndexPath:indexPath];
    
    if (cell.title.text) {
        if ([self.selectedCellsTitlesArray containsObject:cell.title.text]) {
            selected = YES;
            [self.selectedCellsTitlesArray removeObject:cell.title.text];
        } else {
            [self.selectedCellsTitlesArray addObject:cell.title.text];
        }
        
        [self.videoTypes reloadData];
    }
    
    if ([self.selectedCellsTitlesArray count] > 2) {
        self.nextButton.enabled = YES;
    } else {
        self.nextButton.enabled = NO;
    }
    
    [self markCellAtIndexPath:indexPath selected:!selected];
}


#pragma mark - UICollectionViewDelegate Methods
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self toggleCellSelectionForIndexPath:indexPath];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self toggleCellSelectionForIndexPath:indexPath];
}

#pragma mark - UICollectionView Datasource
- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section
{
    if (section == 1) {
        return 10;
    }
    
    return 1;
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView
{
    return 2;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        SignupUserInfoCell *cell =  [cv dequeueReusableCellWithReuseIdentifier:@"SignupUserInfoCell" forIndexPath:indexPath];
        cell.backgroundView.backgroundColor = [UIColor clearColor];
        cell.contentView.backgroundColor = [UIColor clearColor];
        cell.backgroundColor = [UIColor clearColor];
        // TODO: need to make the cell clear
        cell.contentView.backgroundColor = [UIColor clearColor];
        if (self.avatarImage) {
            cell.avatar.image = self.avatarImage;
        }
        cell.name = self.fullname;
        cell.delegate = self;
        return cell;
    }
    
    SignupVideoTypeViewCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"VideoType" forIndexPath:indexPath];
    
    NSString *title;
    UIImage *image;
    if (indexPath.row == 0) {
        title = @"Buzzfeed";
        image = [UIImage imageNamed:@"buzzfeed"];
    } else if (indexPath.row == 1) {
        title = @"GoPro";
        image = [UIImage imageNamed:@"gopro"];
    } else if (indexPath.row == 2) {
        title = @"GQ";
        image = [UIImage imageNamed:@"gq"];
    } else if (indexPath.row == 3) {
        title = @"The New York Times";
        image = [UIImage imageNamed:@"nytimes"];
    } else if (indexPath.row == 4) {
        title = @"The Onion";
        image = [UIImage imageNamed:@"onion"];
    } else if (indexPath.row == 5) {
        title = @"PitchFork";
        image = [UIImage imageNamed:@"pitchfork"];
    } else if (indexPath.row == 6) {
        title = @"TED";
        image = [UIImage imageNamed:@"ted"];
    } else if (indexPath.row == 7) {
        title = @"Vice";
        image = [UIImage imageNamed:@"vice"];
    } else if (indexPath.row == 8) {
        title = @"Vogue";
        image = [UIImage imageNamed:@"vogue"];
    } else if (indexPath.row == 9) {
        title = @"Wired";
        image = [UIImage imageNamed:@"wired"];
    }
    
    cell.title.text = title;
    cell.thumbnail.image = image;
    
    BOOL selected = NO;
    if (title) {
        NSUInteger index = [self.selectedCellsTitlesArray indexOfObject:title];
        if (index != NSNotFound) {
            selected = YES;
            cell.selectionCounter.text = [NSString stringWithFormat:@"%u", index + 1];
        }
    }
    
    [self markCell:cell selected:selected];
    
    return cell;
}

#pragma mark - UICollectionViewFlowLayoutDelegate Methods
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        return CGSizeMake(320, 220);
    }
    
    return CGSizeMake(160, 160);
}


@end
