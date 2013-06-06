//
//  TriageViewController.m
//  Shelby.tv
//
//  Created by Keren on 6/3/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "TriageViewController.h"
#import "AFNetworking.h"
#import "DashboardEntry.h"
#import "DeduplicationUtility.h"
#import "Frame+Helper.h"
#import "SPTriageCell.h"
#import "Video.h"
#import "User.h"

@interface TriageViewController ()
@property (nonatomic, strong) NSArray *entries;
@property (nonatomic, strong) NSArray *deduplicatedEntries;

@property (nonatomic, weak) IBOutlet UITableView *triageTable;
@end

@implementation TriageViewController

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
    
    self.view.frame = CGRectMake(0, 20+44, kShelbyFullscreenWidth, kShelbyFullscreenHeight-20-44);
    self.triageTable.frame = self.view.frame;
    
    // Register Cell Nibs
    [self.triageTable registerNib:[UINib nibWithNibName:@"SPTriageViewCell" bundle:nil] forCellReuseIdentifier:@"SPTriageCell"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Setters & Getters
- (void)setEntries:(NSArray *)entries forChannel:(DisplayChannel *)channel
{
    _channel = channel;
    if (entries) {
        _entries = entries;
        _deduplicatedEntries = [DeduplicationUtility deduplicatedCopy:entries];
    } else {
        _entries = @[];
        _deduplicatedEntries = @[];
    }
    
    [self.triageTable reloadData];
}

- (void)addEntries:(NSArray *)newChannelEntries toEnd:(BOOL)shouldAppend ofChannel:(DisplayChannel *)channel
{
    STVAssert(self.channel == channel, @"cannot add entries for a different channel");
    
    NSMutableArray *indexPathsForInsert, *indexPathsForDelete, *indexPathsForReload;
    
    if(shouldAppend){
        self.entries = [self.entries arrayByAddingObjectsFromArray:newChannelEntries];
        self.deduplicatedEntries = [DeduplicationUtility deduplicatedArrayByAppending:newChannelEntries
                                                                       toDedupedArray:self.deduplicatedEntries
                                                                            didInsert:&indexPathsForInsert
                                                                            didDelete:&indexPathsForDelete
                                                                            didUpdate:&indexPathsForReload];
    } else {
        self.entries = [newChannelEntries arrayByAddingObjectsFromArray:self.entries];
        self.deduplicatedEntries = [DeduplicationUtility deduplicatedArrayByPrepending:newChannelEntries
                                                                        toDedupedArray:self.deduplicatedEntries
                                                                             didInsert:&indexPathsForInsert
                                                                             didDelete:&indexPathsForDelete
                                                                             didUpdate:&indexPathsForReload];
    }
    
    // The index paths returned by DeduplicationUtility are relative to the original array.
    // So we group them within beginUpdates ... endUpdates
    [self.triageTable beginUpdates];
    [self.triageTable insertRowsAtIndexPaths:indexPathsForInsert withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.triageTable deleteRowsAtIndexPaths:indexPathsForDelete withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.triageTable reloadRowsAtIndexPaths:indexPathsForReload withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.triageTable endUpdates];
}

- (NSArray *)deduplicatedEntriesForChannel:(DisplayChannel *)channel
{
    STVAssert(self.channel == channel, @"These aren't the droid you're looking for.");
    return self.deduplicatedEntries;
}

#pragma mark - UITableViewDataSource Methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.deduplicatedEntries count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SPTriageCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SPTriageCell" forIndexPath:indexPath];
    id entry = self.deduplicatedEntries[indexPath.row];
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    // Swipable Cell Settings
     //slightly right = Like
    [cell setFirstStateIconName:@"like_for_table.png"
                     firstColor:kShelbyColorLikesRed
     //far right = Share
            secondStateIconName:@"share_for_table.png"
                    secondColor:[UIColor colorWithHex:@"0590c4" andAlpha:1.0]
     //slightly left = DVR
                  thirdIconName:@"dvr_for_table.png"
                     thirdColor:kShelbyColorGreen
     //far right - unused
                 fourthIconName:@"unlike_for_table.png"
                    fourthColor:[UIColor colorWithHex:@"f1f1f1" andAlpha:1.0]];
    [cell setMode:MCSwipeTableViewCellModeSwitch];
    [cell setDelegate:self];
    
    // We need to set a background to the content view of the cell
    [cell.contentView setBackgroundColor:[UIColor whiteColor]];

    
    Frame *videoFrame = nil;
    if ([entry isKindOfClass:[DashboardEntry class]]) {
        videoFrame = ((DashboardEntry *)entry).frame;
    } else if([entry isKindOfClass:[Frame class]]) {
        videoFrame = entry;
    } else {
        STVAssert(false, @"Expected a DashboardEntry or Frame");
    }
    if (videoFrame && videoFrame.video) {
        cell.shelbyFrame = videoFrame;
        Video *video = videoFrame.video;
        if (video && video.thumbnailURL) {
            NSURLRequest *imageRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:video.thumbnailURL]];
            [[AFImageRequestOperation imageRequestOperationWithRequest:imageRequest
                                                  imageProcessingBlock:nil
                                                               success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                                                   if (cell.shelbyFrame == videoFrame && cell.thumbnailImageView.image == nil) {
                                                                       cell.thumbnailImageView.image = image;
                                                                   } else {
                                                                       //cell has been reused, do nothing
                                                                   }
                                                               }
                                                               failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                                                   //ignoring for now
                                                               }] start];
        }
        
        if (videoFrame && videoFrame.creator && videoFrame.creator.userImage) {
            NSURLRequest *imageRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:videoFrame.creator.userImage]];
            [[AFImageRequestOperation imageRequestOperationWithRequest:imageRequest
                                                  imageProcessingBlock:nil
                                                               success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                                                   if (cell.shelbyFrame == videoFrame && cell.userImageView.image == nil) {
                                                                       cell.userImageView.image = image;
                                                                   } else {
                                                                       //cell has been reused, do nothing
                                                                   }
                                                               }
                                                               failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                                                   //ignoring for now
                                                               }] start];
        }
        
        cell.nicknameLabel.text = videoFrame.creator.nickname;
        [cell.caption setText:[NSString stringWithFormat:@"%@: %@", videoFrame.creator.nickname, [videoFrame creatorsInitialCommentWithFallback:YES]]];
        //don't like this magic number, but also don't think the constant belongs in BrowseViewController...
        // KP KP - TODO: for now, hardcoding 300px for the width of the caption label
        CGSize maxCaptionSize = CGSizeMake(300, cell.frame.size.height * 0.33);
        CGFloat textBasedHeight = [cell.caption.text sizeWithFont:[cell.caption font]
                                                constrainedToSize:maxCaptionSize
                                                    lineBreakMode:NSLineBreakByWordWrapping].height;
        [cell.caption setFrame:CGRectMake(cell.caption.frame.origin.x,
                                          cell.frame.size.height - textBasedHeight,
                                          300,
                                          textBasedHeight)];
    }

    
    return cell;
}


#pragma mark - UITableViewDelegate Methods
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.triageDelegate userPressedTriageChannel:self.channel
                                           atItem:self.deduplicatedEntries[indexPath.row]];
}

- (void)tableView:(UITableView *)tableView didHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    SPTriageCell *cell =  (SPTriageCell *)[tableView cellForRowAtIndexPath:indexPath];
    [cell highlightItemWithColor:kShelbyColorGreen];
}

- (void)tableView:(UITableView *)tableView didUnhighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    SPTriageCell *cell =  (SPTriageCell *)[tableView cellForRowAtIndexPath:indexPath];
    [cell unHighlightItem];
}

#pragma mark - MCSwipeTableViewCellDelegate
- (void)swipeTableViewCell:(MCSwipeTableViewCell *)cell didTriggerState:(MCSwipeTableViewCellState)state withMode:(MCSwipeTableViewCellMode)mode
{
    switch (state) {
        case MCSwipeTableViewCellState1:
            //slightly right = Like
            break;
        case MCSwipeTableViewCellState2:
            //far right = Share
            break;
        case MCSwipeTableViewCellState3:
            //slightly left = DVR
            break;
        case MCSwipeTableViewCellState4:
            //far right - unused
            break;
        case MCSwipeTableViewCellStateNone:
            //ignore
            break;
    }
//    DLog(@"IndexPath : %@ - MCSwipeTableViewCellState : %d - MCSwipeTableViewCellMode : %d", [self.triageTable indexPathForCell:cell], state, mode);
}

@end
