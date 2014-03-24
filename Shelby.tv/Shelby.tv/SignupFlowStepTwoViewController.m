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
    
    if (self.facebookSignup) {
        self.navigationItem.leftBarButtonItem.enabled = NO;
    }
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
        return 43;
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
        title = @"VICE";
        rollID = @"4f907a9b9a725b46010005c7";
        image = [UIImage imageNamed:@"vice"];
    } else if (indexPath.row == 1) {
        title = @"The Onion";
        rollID = @"4fc532169a725b2999000354";
        image = [UIImage imageNamed:@"theonion"];
    } else if (indexPath.row == 2) {
        title = @"New York Times";
        rollID = @"50522466b415cc5b81002080";
        image = [UIImage imageNamed:@"newyorktimes"];
    } else if (indexPath.row == 3) {
        title = @"Pitchfork";
        rollID = @"4fa3e6309a725b3689001792";
        image = [UIImage imageNamed:@"pitchfork"];
    } else if (indexPath.row == 4) {
        title = @"Comedy Central";
        rollID = @"4f95c8ec88ba6b4d7e0138e9";
        image = [UIImage imageNamed:@"comedycentral"];
    } else if (indexPath.row == 5) {
        title = @"TED";
        rollID = @"4fa054ff88ba6b09c8000e93";
        image = [UIImage imageNamed:@"ted"];
    } else if (indexPath.row == 6) {
        title = @"NetworkA";
        rollID = @"4f987e9188ba6b58500122da";
        image = [UIImage imageNamed:@"networka"];
    } else if (indexPath.row == 7) {
        title = @"The Verge";
        rollID = @"4fa1591f88ba6b78da0008b7";
        image = [UIImage imageNamed:@"theverge"];
    } else if (indexPath.row == 8) {
        title = @"Jamie Oliver's Food Tube";
        rollID = @"4f9d9c1a88ba6b56aa00150f";
        image = [UIImage imageNamed:@"jamieoliversfoodtube"];
    } else if (indexPath.row == 9) {
        title = @"Buzzfeed";
        rollID = @"4f9577c488ba6b15ec0084c7";
        image = [UIImage imageNamed:@"buzzfeed"];
    } else if (indexPath.row == 10) {
        title = @"Wired";
        rollID = @"4f9a08909a725b43ad00f798";
        image = [UIImage imageNamed:@"wired"];
    } else if (indexPath.row == 11) {
        title = @"GQ";
        rollID = @"519bac7cb415cc01910000af";
        image = [UIImage imageNamed:@"gq"];
    } else if (indexPath.row == 12) {
        title = @"The Daily What";
        rollID = @"4fa28d849a725b79c9000228";
        image = [UIImage imageNamed:@"thedailywhat"];
    } else if (indexPath.row == 13) {
        title = @"MTV";
        rollID = @"4fa0a50a88ba6b448f000dd4";
        image = [UIImage imageNamed:@"mtv"];
    } else if (indexPath.row == 14) {
        title = @"Vogue";
        rollID = @"4fa062869a725b0c2c0010fc";
        image = [UIImage imageNamed:@"vogue"];
    } else if (indexPath.row == 15) {
        title = @"Glamour";
        rollID = @"4fc64bfd9a725b24af0014db";
        image = [UIImage imageNamed:@"glamour"];
    } else if (indexPath.row == 16) {
        title = @"IGN";
        rollID = @"4f987a5e9a725b032b002f13";
        image = [UIImage imageNamed:@"ign"];
    } else if (indexPath.row == 17) {
        title = @"Machinima";
        rollID = @"52419d90b415cc3493000007";
        image = [UIImage imageNamed:@"machinima"];
    } else if (indexPath.row == 18) {
        title = @"PBS Idea Channel";
        rollID = @"4faabca99a725b5cd50026a2";
        image = [UIImage imageNamed:@"pbsideachannel"];
    } else if (indexPath.row == 19) {
        title = @"Crash Course";
        rollID = @"4f95f29f88ba6b72c2004aed";
        image = [UIImage imageNamed:@"crashcourse"];
    } else if (indexPath.row == 20) {
        title = @"College Humor";
        rollID = @"4f9009d9b415cc466a000466";
        image = [UIImage imageNamed:@"collegehumor"];
    } else if (indexPath.row == 21) {
        title = @"Above Average";
        rollID = @"50951b06b415cc567800aa16";
        image = [UIImage imageNamed:@"aboveaverage"];
    } else if (indexPath.row == 22) {
        title = @"Blank on Blank";
        rollID = @"4fa41c4f88ba6b0d4e00130f";
        image = [UIImage imageNamed:@"blankonblank"];
    } else if (indexPath.row == 23) {
        title = @"Reserve Channel";
        rollID = @"5005b00e9a725b0e150178fa";
        image = [UIImage imageNamed:@"reservechannel"];
    } else if (indexPath.row == 24) {
        title = @"Red Bull";
        rollID = @"4fb413bb9a725b650900195a";
        image = [UIImage imageNamed:@"redbull"];
    } else if (indexPath.row == 25) {
        title = @"iamOTHER";
        rollID = @"519baa7eb415cc0191000007";
        image = [UIImage imageNamed:@"iamother"];
    } else if (indexPath.row == 26) {
        title = @"Life+Times";
        rollID = @"519bab29b415cc0191000077";
        image = [UIImage imageNamed:@"lifetimes"];
    } else if (indexPath.row == 27) {
        title = @"GoPro";
        rollID = @"4f91700d88ba6b2aab000fba";
        image = [UIImage imageNamed:@"gopro"];
    } else if (indexPath.row == 28) {
        title = @"Teton Gravity Research";
        rollID = @"512d1f15b415cc5d8c0001cf";
        image = [UIImage imageNamed:@"tetongravityresearch"];
    } else if (indexPath.row == 29) {
        title = @"THNKR";
        rollID = @"4fc8f77f88ba6b0881000995";
        image = [UIImage imageNamed:@"thnkr"];
    } else if (indexPath.row == 30) {
        title = @"Smart History";
        rollID = @"4fb6344d9a725b2d6a0011b0";
        image = [UIImage imageNamed:@"smarthistory"];
    } else if (indexPath.row == 31) {
        title = @"Sci Show";
        rollID = @"4f9731be88ba6b5309025c59";
        image = [UIImage imageNamed:@"scishow"];
    } else if (indexPath.row == 32) {
        title = @"Sesame Street";
        rollID = @"4fa2931f88ba6b68b6000ba9";
        image = [UIImage imageNamed:@"sesamestreet"];
    } else if (indexPath.row == 33) {
        title = @"RIDE";
        rollID = @"4f9ee11b9a725b6605001713";
        image = [UIImage imageNamed:@"ride"];
    } else if (indexPath.row == 34) {
        title = @"Creators Project";
        rollID = @"4fbbc4211c1cf42b91002eac";
        image = [UIImage imageNamed:@"creatorsproject"];
    } else if (indexPath.row == 35) {
        title = @"Drive";
        rollID = @"4f99e5069a725b1c7501c038";
        image = [UIImage imageNamed:@"drive"];
    } else if (indexPath.row == 36) {
        title = @"SpikeTV";
        rollID = @"4f957feb88ba6b17c100e88c";
        image = [UIImage imageNamed:@"spiketv"];
    } else if (indexPath.row == 37) {
        title = @"EpicMealTime";
        rollID = @"4f92e08f9a725b23ec001068";
        image = [UIImage imageNamed:@"epicmealtime"];
    } else if (indexPath.row == 38) {
        title = @"Grantland";
        rollID = @"519bada3b415cc01910000e5";
        image = [UIImage imageNamed:@"grantland"];
    } else if (indexPath.row == 39) {
        title = @"Pategonia";
        rollID = @"4f95f25488ba6b70ed0080e3";
        image = [UIImage imageNamed:@"patagonia"];
    } else if (indexPath.row == 40) {
        title = @"VH1";
        rollID = @"4f907d3f9a725b45e50009ad";
        image = [UIImage imageNamed:@"vh1"];
    } else if (indexPath.row == 41) {
        title = @"Nova Online";
        rollID = @"512d1e55b415cc5d8c00013f";
        image = [UIImage imageNamed:@"novaonline"];
    } else if (indexPath.row == 42) {
        title = @"Khan Academy";
        rollID = @"4fa39bd89a725b1f920008f3";
        image = [UIImage imageNamed:@"khanacademy"];
    }

    cell.title.text = title;
    cell.thumbnail.image = image;
    cell.rollID = rollID;
    
    BOOL selected = NO;
    if (title) {
        NSUInteger index = 0;
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
        return CGSizeMake(320, 265);
    }
    
    return CGSizeMake(160, 160);
}


@end
