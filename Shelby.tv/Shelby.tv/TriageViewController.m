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
#import "Frame+Helper.h"
#import "SPTriageCell.h"
#import "Video.h"
#import "User.h"

@interface TriageViewController ()
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

    self.itemsToTriage = @[];
    
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

- (void)setItemsToTriage:(NSMutableArray *)itemsToTriage
{
    _itemsToTriage = itemsToTriage;
    
    [self.triageTable reloadData];
}

#pragma mark - UITableViewDataSource Methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.itemsToTriage count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SPTriageCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SPTriageCell" forIndexPath:indexPath];
    id entry = self.itemsToTriage[indexPath.row];
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
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
        CGSize maxCaptionSize = CGSizeMake(cell.frame.size.width, cell.frame.size.height * 0.33);
        CGFloat textBasedHeight = [cell.caption.text sizeWithFont:[cell.caption font]
                                                constrainedToSize:maxCaptionSize
                                                    lineBreakMode:NSLineBreakByWordWrapping].height;
        
        [cell.caption setFrame:CGRectMake(cell.caption.frame.origin.x,
                                          cell.frame.size.height - textBasedHeight,
                                          cell.frame.size.width,
                                          textBasedHeight)];
    }

    
    return cell;
}


#pragma mark - UITableViewDelegate Methods
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.triageDelegate userPressedTriageChannel:self.triageChannel atItem:self.itemsToTriage[indexPath.row]];
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

@end
