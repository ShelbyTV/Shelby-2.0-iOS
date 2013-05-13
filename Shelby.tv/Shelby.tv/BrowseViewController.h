//
//  BrowseViewController.h
//  Shelby.tv
//
//  Created by Keren on 2/13/13.
//  Copyright (c) 2013 Shelby TV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SPVideoReel.h"
#import "SPChannelCell.h"
#import "ShelbyHideBrowseAnimationViews.h"

@protocol ShelbyBrowseProtocol <NSObject>

- (void)userPressedChannel:(DisplayChannel *)channel atItem:(id)item;
- (void)loadMoreEntriesInChannel:(DisplayChannel *)channel sinceEntry:(NSManagedObject *)entry;

@end

@protocol ShelbyPlayerProtocol;

// KP KP: TODO: right now, browseVC is the delegate of the SPVideoReel. Need to be changed - the brain should be the delegate
@interface BrowseViewController : GAITrackedViewController <UICollectionViewDataSource, UICollectionViewDelegate, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIButton *toggleSecretButton;
@property (weak, nonatomic) id<ShelbyBrowseProtocol> browseDelegate;

//data model: Array of DisplayChannel
//NB 1: the ordering of this array (when set) will be used to determine display ordering
//NB 2: the entries for a given channel are part of data model as well, set with methods (below)
@property (nonatomic, strong) NSArray *channels;

/// Action Methods
- (IBAction)toggleSecretModes:(id)sender;


- (void)fetchDidCompleteForChannel:(DisplayChannel *)channel;
- (void)setEntries:(NSArray *)entries forChannel:(DisplayChannel *)channel;
- (void)addEntries:(NSArray *)newChannelEntries toEnd:(BOOL)shouldAppend ofChannel:(DisplayChannel *)channel;
- (NSArray *)entriesForChannel:(DisplayChannel *)channel;

- (void)refreshActivityIndicatorForChannel:(DisplayChannel *)channel shouldAnimate:(BOOL)shouldAnimate;
- (void)loadMoreActivityIndicatorForChannel:(DisplayChannel *)channel shouldAnimate:(BOOL)shouldAnimate;

- (ShelbyHideBrowseAnimationViews *)animationViewForOpeningChannel:(DisplayChannel *)channel;
- (ShelbyHideBrowseAnimationViews *)animationViewForClosingChannel:(DisplayChannel *)channel;

- (void)highlightFrame:(Frame *)frame atChannel:(DisplayChannel *)channel;
@end
