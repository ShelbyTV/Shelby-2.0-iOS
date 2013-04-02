//
//  CategoriesMenuViewController.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 4/2/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import "CategoriesMenuViewController.h"

@interface CategoriesMenuViewController ()

- (void)setupTableView;

@end

@implementation CategoriesMenuViewController

#pragma mark - Initialization Methods
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

#pragma mark - Interface Orientation Methods
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupTableView];
}

#pragma mark - Setup Methods
- (void)setupTableView
{
    self.playlistTableView.backgroundColor = [UIColor blackColor];
    self.playlistTableView.alpha = 0.7f;
}

#pragma mark - UITableViewDataSource Methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rows = 0;
    
    if ( 0 == section ) { // User-Specific Playlists
        
        rows = 1;
        
    } else { // Category Playlists
        
        rows = 1;
        
    }
    
    return rows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [self.playlistTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if ( nil == cell ) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    if ( 0 == indexPath.section ) { // User-Specific Playlists
        
        
        
    } else { // Category Playlists
        
        
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate Methods



@end
