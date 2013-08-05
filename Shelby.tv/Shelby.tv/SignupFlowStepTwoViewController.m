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
// Initiate Segues
- (IBAction)gotoSocialNetworks:(id)sender;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
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

    self.nextButton.enabled = NO;
    self.videoTypes.backgroundColor = self.view.backgroundColor;

    self.collectionView.contentInset = UIEdgeInsetsMake(44, 0, 0, 0);
    self.collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(44, 0, 0, 0);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.videoTypes && [self.selectedCellsTitlesArray count] > 2) {
        self.nextButton.enabled = YES;
    }
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [super prepareForSegue:segue sender:sender];
    [SignupFlowViewController sendEventWithCategory:kAnalyticsCategorySignup
                                         withAction:kAnalyticsSignupStep2Complete
                                          withLabel:nil
                                          withValue:@([self.selectedCellsTitlesArray count])];
}

- (IBAction)gotoSocialNetworks:(id)sender
{
    [self performSegueWithIdentifier:@"SocialNetworks" sender:self];
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
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"title = %@", cell.title.text];
        NSArray *match = [self.selectedCellsTitlesArray filteredArrayUsingPredicate:predicate];
        
        if ([match count] == 1) {
            selected = YES;
            [self.selectedCellsTitlesArray removeObject:match[0]];
        } else {
            [self.selectedCellsTitlesArray addObject:@{@"title": cell.title.text, @"rollID" : cell.rollID}];
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
    [SignupFlowViewController sendEventWithCategory:kAnalyticsCategorySignup
                                         withAction:kAnalyticsSignupSelectSourceToFollow
                                          withLabel:nil];
    [self toggleCellSelectionForIndexPath:indexPath];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [SignupFlowViewController sendEventWithCategory:kAnalyticsCategorySignup
                                         withAction:kAnalyticsSignupDeselectSourceToFollow
                                          withLabel:nil];
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

        if (self.avatarImage) {
            cell.avatar.image = self.avatarImage;
            cell.avatar.layer.masksToBounds = YES;
            cell.avatar.layer.cornerRadius = 5;
        }
        cell.name = self.fullname;
        cell.delegate = self;
        return cell;
    }
    
    SignupVideoTypeViewCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"VideoType" forIndexPath:indexPath];
    
    NSString *title, *rollID;
    UIImage *image;
    if (indexPath.row == 0) {
        title = @"Buzzfeed";
        rollID = @"4f9577c488ba6b15ec0084c7";
        image = [UIImage imageNamed:@"buzzfeed"];
    } else if (indexPath.row == 1) {
        title = @"GoPro";
        rollID = @"4f91700d88ba6b2aab000fba";
        image = [UIImage imageNamed:@"gopro"];
    } else if (indexPath.row == 2) {
        title = @"GQ";
        rollID = @"519bac7cb415cc01910000af";
        image = [UIImage imageNamed:@"gq"];
    } else if (indexPath.row == 3) {
        title = @"The New York Times";
        rollID = @"50522466b415cc5b81002080";
        image = [UIImage imageNamed:@"nytimes"];
    } else if (indexPath.row == 4) {
        title = @"The Onion";
        rollID = @"4fc532169a725b2999000354";
        image = [UIImage imageNamed:@"onion"];
    } else if (indexPath.row == 5) {
        title = @"PitchFork";
        rollID = @"4fa41cfa88ba6b0dcf001a65";
        image = [UIImage imageNamed:@"pitchfork"];
    } else if (indexPath.row == 6) {
        title = @"TED";
        rollID = @"4fa054ff88ba6b09c8000e93";
        image = [UIImage imageNamed:@"ted"];
    } else if (indexPath.row == 7) {
        title = @"Vice";
        rollID = @"4f907a9b9a725b46010005c7";
        image = [UIImage imageNamed:@"vice"];
    } else if (indexPath.row == 8) {
        title = @"Vogue";
        rollID = @"4fa062869a725b0c2c0010fc";
        image = [UIImage imageNamed:@"vogue"];
    } else if (indexPath.row == 9) {
        title = @"Wired";
        rollID = @"4f9a08909a725b43ad00f798";
        image = [UIImage imageNamed:@"wired"];
    }

    cell.title.text = title;
    cell.thumbnail.image = image;
    cell.rollID = rollID;
    
    BOOL selected = NO;
    if (title) {
        NSInteger index = 0;
        for (NSDictionary *rollInfo in self.selectedCellsTitlesArray) {
            if ([title isEqualToString:rollInfo[@"title"]]) {
                selected = YES;
                cell.selectionCounter.text = [NSString stringWithFormat:@"%u", index + 1];
                break;
            }
            index++;
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
