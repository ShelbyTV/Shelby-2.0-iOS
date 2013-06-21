//
//  ShelbyStreamBrowseViewController.m
//  Shelby.tv
//
//  Created by Keren on 6/21/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyStreamBrowseViewController.h"
#import "AFNetworking.h"
#import "DashboardEntry.h"
#import "Frame.h"
#import "ShelbyStreamBrowseViewCell.h"
#import "Video.h"

@interface ShelbyStreamBrowseViewController ()
@property (nonatomic, strong) NSArray *entries;
@property (nonatomic, strong) NSArray *deduplicatedEntries;

@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;
@end

@implementation ShelbyStreamBrowseViewController

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
    // Do any additional setup after loading the view from its nib.
    
    // Register Cell Nibs
    [self.collectionView registerNib:[UINib nibWithNibName:@"ShelbyStreamBrowseViewCell" bundle:nil] forCellWithReuseIdentifier:@"ShelbyStreamBrowseViewCell"];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Setters & Getters
- (void)setEntries:(NSArray *)entries
        forChannel:(DisplayChannel *)channel
{
    _channel = channel;
    if (entries) {
        _entries = entries;
//        _deduplicatedEntries = [DeduplicationUtility deduplicatedCopy:entries];
    } else {
        _entries = @[];
        _deduplicatedEntries = @[];
    }
    
    [self.collectionView reloadData];

}

- (void)addEntries:(NSArray *)newChannelEntries
             toEnd:(BOOL)shouldAppend
         ofChannel:(DisplayChannel *)channel

{
    STVAssert(self.channel == channel, @"cannot add entries for a different channel");
    
//    NSMutableArray *indexPathsForInsert, *indexPathsForDelete, *indexPathsForReload;
    
    if(shouldAppend){
        self.entries = [self.entries arrayByAddingObjectsFromArray:newChannelEntries];
//        self.deduplicatedEntries = [DeduplicationUtility deduplicatedArrayByAppending:newChannelEntries
//                                                                       toDedupedArray:self.deduplicatedEntries
//                                                                            didInsert:&indexPathsForInsert
//                                                                            didDelete:&indexPathsForDelete
//                                                                            didUpdate:&indexPathsForReload];
    } else {
        self.entries = [newChannelEntries arrayByAddingObjectsFromArray:self.entries];
//        self.deduplicatedEntries = [DeduplicationUtility deduplicatedArrayByPrepending:newChannelEntries
//                                                                        toDedupedArray:self.deduplicatedEntries
//                                                                             didInsert:&indexPathsForInsert
//                                                                             didDelete:&indexPathsForDelete
//                                                                             didUpdate:&indexPathsForReload];
    }
    
    // The index paths returned by DeduplicationUtility are relative to the original array.
    // So we group them within beginUpdates ... endUpdates
//    [self.collectionView beginUpdates];
//    [self.collectionView insertRowsAtIndexPaths:indexPathsForInsert withRowAnimation:(shouldAppend ? UIColl : UITableViewRowAnimationTop)];
//    [self.collectionView deleteRowsAtIndexPaths:indexPathsForDelete withRowAnimation:UITableViewRowAnimationFade];
//    [self.collectionView reloadRowsAtIndexPaths:indexPathsForReload withRowAnimation:UITableViewRowAnimationAutomatic];
//    [self.collectionView endUpdates];
}

- (NSArray *)deduplicatedEntriesForChannel:(DisplayChannel *)channel
{
    return self.entries; //KP KP: TODO: until we implement dedups
//    return self.deduplicatedEntries;
}




#pragma mark - UICollectionView Datasource
- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section
{
    return [self.entries count];
    
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView
{
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ShelbyStreamBrowseViewCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"ShelbyStreamBrowseViewCell" forIndexPath:indexPath];
    
    id entry = self.entries[indexPath.row];
    
    cell.thumbnail.backgroundColor = [UIColor blackColor];
    
    Frame *videoFrame = nil;
    if ([entry isKindOfClass:[DashboardEntry class]]) {
        videoFrame = ((DashboardEntry *)entry).frame;
    } else if([entry isKindOfClass:[Frame class]]) {
        videoFrame = entry;
    } else {
        STVAssert(false, @"Expected a DashboardEntry or Frame");
    }
    if (videoFrame && videoFrame.video) {
//        cell.shelbyFrame = videoFrame;
        Video *video = videoFrame.video;
        if (video && video.thumbnailURL) {
            NSURLRequest *imageRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:video.thumbnailURL]];
            [[AFImageRequestOperation imageRequestOperationWithRequest:imageRequest
                                                  imageProcessingBlock:nil
                                                               success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
//                                                                   if (cell.shelbyFrame == videoFrame && cell.thumbnail.image == nil) {
                                                                       cell.thumbnail.image = image;
//                                                                   } else {
//                                                                       //cell has been reused, do nothing
//                                                                   }
                                                               }
                                                               failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                                                   //ignoring for now
                                                               }] start];
        }
        
//        [cell.caption setText:[NSString stringWithFormat:@"%@: %@", videoFrame.creator.nickname, [videoFrame creatorsInitialCommentWithFallback:YES]]];
        //don't like this magic number, but also don't think the constant belongs in BrowseViewController...
//        CGSize maxCaptionSize = CGSizeMake(cell.frame.size.width, cell.frame.size.height * 0.33);
//        CGFloat textBasedHeight = [cell.caption.text sizeWithFont:[cell.caption font]
//                                                constrainedToSize:maxCaptionSize
//                                                    lineBreakMode:NSLineBreakByWordWrapping].height;
//        
//        [cell.caption setFrame:CGRectMake(cell.caption.frame.origin.x,
//                                          cell.frame.size.height - textBasedHeight,
//                                          cell.frame.size.width,
//                                          textBasedHeight)];
    }
    
    //load more data
//    NSInteger cellsBeyond = [dedupedEntries count] - [indexPath row];
//    if(cellsBeyond == kShelbyPrefetchEntriesWhenNearEnd && channelCollection.channel.canFetchRemoteEntries){
//        //since id should come from raw entries, not de-duped entries
//        [self.browseDelegate loadMoreEntriesInChannel:channelCollection.channel
//                                           sinceEntry:[[self entriesForChannel:channelCollection.channel] lastObject]];
//    }
    
    return cell;
}


#pragma mark - UICollectionViewDelegate



@end
