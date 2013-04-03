//
//  GroupsMenuViewController.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 4/2/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

@class SPVideoReel;

@interface GroupsMenuViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *playlistTableView;

- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil
         andVideoReel:(SPVideoReel *)videoReel;

@end
