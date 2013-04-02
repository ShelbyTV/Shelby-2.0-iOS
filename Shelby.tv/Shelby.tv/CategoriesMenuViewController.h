//
//  CategoriesMenuViewController.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 4/2/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CategoriesMenuViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) UITableView *playlistTableView;

@end
