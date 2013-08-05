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
#import "DisplayChannel+Helper.h"
#import "ShelbyDVRController.h"
#import "Frame+Helper.h"
#import "ShelbyVideoContainer.h"
#import "SPShareController.h"
#import "SPTriageCell.h"
#import "Video.h"
#import "User.h"

@interface TriageViewController ()
@property (nonatomic, strong) NSArray *entries;
@property (nonatomic, strong) NSArray *deduplicatedEntries;

@property (nonatomic, weak) IBOutlet UITableView *triageTable;

@property (nonatomic, strong) ShelbyDVRController *dvrController;
@end

@implementation TriageViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _dvrController = [[ShelbyDVRController alloc] init];
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
    [self.triageTable insertRowsAtIndexPaths:indexPathsForInsert withRowAnimation:(shouldAppend ? UITableViewRowAnimationBottom : UITableViewRowAnimationTop)];
    [self.triageTable deleteRowsAtIndexPaths:indexPathsForDelete withRowAnimation:UITableViewRowAnimationFade];
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
    Frame *shelbyFrame;
    if ([entry isKindOfClass:[Frame class]]) {
        shelbyFrame = entry;
    } else if ([entry isKindOfClass:[DashboardEntry class]]) {
        shelbyFrame = ((DashboardEntry *)entry).frame;
    }
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    // Swipable Cell Settings
     //slightly right = Like
    [cell setFirstStateIconName:([shelbyFrame videoIsLiked] ? @"unlike_for_table.png" : @"like_for_table.png")
                     firstColor:kShelbyColorLikesRed
     //far right = Share
            secondStateIconName:@"share_for_table.png"
                    secondColor:[UIColor colorWithHex:@"0590c4" andAlpha:1.0]
     //slightly left = DVR
                  thirdIconName:@"dvr_for_table.png"
                     thirdColor:kShelbyColorGreen
     //far right - unused
                 fourthIconName:nil
                    fourthColor:nil];
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
        // KP KP - TODO: for now, hardcoding 300px for the width and 48px for height of the caption label
        CGSize maxCaptionSize = CGSizeMake(300, 48);
        CGFloat textBasedHeight = [cell.caption.text sizeWithFont:[cell.caption font]
                                                constrainedToSize:maxCaptionSize
                                                    lineBreakMode:NSLineBreakByWordWrapping].height;
        [cell.caption setFrame:CGRectMake(cell.caption.frame.origin.x,
                                          cell.caption.frame.origin.y,
                                          300,
                                          textBasedHeight)];
    }

    //load more data
    NSInteger cellsBeyond = [self.deduplicatedEntries count] - [indexPath row];
    if(cellsBeyond == kShelbyPrefetchEntriesWhenNearEnd && [self.channel canFetchRemoteEntries]){
        //since id should come from raw entries, not de-duped entries
        [self.triageDelegate loadMoreEntriesInChannel:self.channel
                                           sinceEntry:[self.entries lastObject]];
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
    id entry = self.deduplicatedEntries[[self.triageTable indexPathForCell:cell].row];
    STVAssert([entry isKindOfClass:[Frame class]] || [entry isKindOfClass:[DashboardEntry class]], @"expected Frame or DashboardEntry");
    Frame *shelbyFrame;
    if ([entry isKindOfClass:[Frame class]]) {
        shelbyFrame = entry;
    } else if ([entry isKindOfClass:[DashboardEntry class]]) {
        shelbyFrame = ((DashboardEntry *)entry).frame;
    }
    
    switch (state) {
        case MCSwipeTableViewCellState1:
            //slightly right
            [self toggleLikeOfFrame:shelbyFrame];
            break;
        case MCSwipeTableViewCellState2:
            //far right
            [self shareFrame:shelbyFrame];
            break;
        case MCSwipeTableViewCellState3:
            //slightly left
            [self dvrFrame:shelbyFrame];
            break;
        case MCSwipeTableViewCellState4:
            //far left - unused
            break;
        case MCSwipeTableViewCellStateNone:
            //ignore
            break;
    }

    [self.triageTable reloadRowsAtIndexPaths:@[[self.triageTable indexPathForCell:cell]] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)dvrFrame:(Frame *)shelbyFrame
{    
    DVRDatePickerView *dvrPicker = [[DVRDatePickerView alloc] init];
    dvrPicker.delegate = self;
    dvrPicker.entityForDVR = shelbyFrame;
    
    [self.parentViewController.view addSubview:dvrPicker];
    [self.parentViewController.view bringSubviewToFront:dvrPicker];
}

- (void)shareFrame:(Frame *)shelbyFrame
{
    SPShareController *shareController = [[SPShareController alloc] initWithVideoFrame:shelbyFrame fromViewController:self atRect:CGRectZero];
    shareController.delegate = nil;

    [shareController shareWithCompletionHandler:nil];
}

- (void)toggleLikeOfFrame:(Frame *)shelbyFrame
{
    [shelbyFrame toggleLike];
//    [ShelbyViewController sendEventWithCategory:kAnalyticsCategoryVideoPlayer
//                                     withAction:kAnalyticsVideoPlayerToggleLike
//                                      withLabel:(didLike ? @"Liked" : @"Unliked")];

    NSError *err;
    [shelbyFrame.managedObjectContext save:&err];
    STVAssert(!err, @"like save failed");
}

#pragma mark - DVRDatePickerViewDelegate

- (void)cancelForDVRDatePickerView:(DVRDatePickerView *)view
{
    [view removeFromSuperview];
}

- (void)setDVRForDVRDatePickerView:(DVRDatePickerView *)view withDatePicker:(UIDatePicker *)datePicker
{
    NSDate *when = datePicker.date;
    //annoyingly, the date picker keeps the seconds as whatever the current time is, so i need to set them to zero
    NSTimeInterval time = floor([when timeIntervalSinceReferenceDate] / 60.0) * 60.0;
    when = [NSDate dateWithTimeIntervalSinceReferenceDate:time];
    
    DLog(@"DVRing for: %@", when);
    [self.dvrController setDVRFor:view.entityForDVR toRemindAt:when];
    
    [view removeFromSuperview];
}

@end
