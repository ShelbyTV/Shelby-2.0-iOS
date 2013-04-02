//
//  GroupsMenuViewController.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 4/2/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import "GroupsMenuViewController.h"

@interface GroupsMenuViewController ()

@property (weak, nonatomic) AppDelegate *appDelegate;
@property (strong, nonatomic) NSMutableArray *categories;

- (void)setupDataSource;
- (void)setupTableView;
- (void)setupUserSpecificGroups;
- (NSString *)extractTitleFromCategory:(id)category;

@end

@implementation GroupsMenuViewController

#pragma mark - Initialization Methods
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [self setupDataSource];
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
- (void)setupDataSource
{
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    self.categories = [dataUtility fetchAllCategories];
}

- (void)setupTableView
{
    self.playlistTableView.backgroundView.backgroundColor = [UIColor blackColor];
    self.playlistTableView.backgroundView.alpha = 0.7f;
    [self.playlistTableView setScrollEnabled:NO];
}

- (void)setupUserSpecificGroups
{
    
}

#pragma mark - Private Methods
- (NSString *)extractTitleFromCategory:(id)category
{
    
    NSString *categoryTitle = @"";
 
    if ( [category isKindOfClass:[NSManagedObject class]] ) {
        
        NSManagedObjectContext *context = [self.appDelegate context];
        NSManagedObjectID *objectID = [category objectID];
        
        if ( [category isMemberOfClass:[Channel class]] ) {
            
            Channel *channel = (Channel *)[context existingObjectWithID:objectID error:nil];
            categoryTitle = [NSString stringWithFormat:@"#%@", [channel displayTitle]];
            
        } else if ( [category isMemberOfClass:[Roll class]] ) {
            
            Roll *roll = (Roll *)[context existingObjectWithID:objectID error:nil];
            categoryTitle = [NSString stringWithFormat:@"#%@", [roll title]];
            
        } else {
            
            DLog(@"Category is newither a Channel or Roll");
            
        }

        
    }
       
    return categoryTitle;
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
        
        rows = 3;
        
    } else { // Category Playlists
        
        rows = ( [self.categories count] ? [self.categories count] : 1 );
        
    }
    
    return rows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [self.playlistTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if ( nil == cell ) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.textLabel.textColor = [UIColor whiteColor];
    }
    
    if ( 0 == indexPath.section ) { // User-Specific Playlists
    
        cell.textLabel.text = @"Likes";
        
    } else { // Category Playlists
    
        cell.textLabel.text = [self extractTitleFromCategory:[self.categories objectAtIndex:[indexPath row]]];
        
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate Methods
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}


@end
