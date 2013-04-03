//
//  GroupsMenuViewController.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 4/2/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import "GroupsMenuViewController.h"
#import "SPVideoReel.h"

@interface GroupsMenuViewController ()

@property (weak, nonatomic) AppDelegate *appDelegate;
@property (nonatomic) NSMutableArray *categories;
@property (nonatomic) SPVideoReel *videoReel;

- (void)setupDataSource;
- (void)setupUserSpecificGroupsForRow:(NSUInteger)row inCell:(UITableViewCell *)cell;
- (NSString *)extractTitleFromCategory:(id)category;
- (void)launchCategory:(id)category;

@end

@implementation GroupsMenuViewController

#pragma mark - Initialization Methods
- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil
         andVideoReel:(SPVideoReel *)videoReel
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if ( self ) {
        _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        _videoReel = videoReel;
        [self setupDataSource];
    }
    
    return self;
}

#pragma mark - View Lifecycle Methods
- (void)viewDidLoad
{
    [super viewDidLoad];
}

#pragma mark - Setup Methods
- (void)setupDataSource
{
    CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
    self.categories = [dataUtility fetchAllCategories];
}

- (void)setupUserSpecificGroupsForRow:(NSUInteger)row inCell:(UITableViewCell *)cell
{
    switch ( row ) {
       
        case 0: {
            
            cell.textLabel.text = @"Likes";
            cell.textLabel.textColor = [UIColor redColor];
            
        } break;
        
        case 1: {
            
            cell.textLabel.text = @"Stream";
            cell.textLabel.textColor = [UIColor blueColor];
            
        } break;
            
        case 2: {
            
            cell.textLabel.text = @"My Roll";
            cell.textLabel.textColor = kShelbyColorGreen;
            
        } break;
            
        default:
            break;
    }
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
            
            DLog(@"Category is neither a Channel or Roll");
            
        }
        
    }
       
    return categoryTitle;
}

- (void)launchCategoryInRow:(id)category
{
    if ( [category isKindOfClass:[NSManagedObject class]] ) {
        
        NSManagedObjectContext *context = [self.appDelegate context];
        NSManagedObjectID *objectID = [category objectID];
        CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
        
        if ( [category isMemberOfClass:[Channel class]] ) {
            
            Channel *channel = (Channel *)[context existingObjectWithID:objectID error:nil];
            NSMutableArray *videoFrames = [dataUtility fetchFramesInCategoryChannel:[channel channelID]];
            [self.videoReel loadWithGroupType:GroupType_CategoryChannel groupTitle:[channel displayTitle] videoFrames:videoFrames andCategoryID:[channel channelID]];
            
        } else if ( [category isMemberOfClass:[Roll class]] ) {
            
            Roll *roll = (Roll *)[context existingObjectWithID:objectID error:nil];
            NSMutableArray *videoFrames = [dataUtility fetchFramesInCategoryChannel:[roll rollID]];
            [self.videoReel loadWithGroupType:GroupType_CategoryRoll groupTitle:[roll title] videoFrames:videoFrames andCategoryID:[roll rollID]];
            
        } else {
            DLog(@"Category is neither a Channel or Roll");
        }
    }
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
        cell.textLabel.textColor = [UIColor orangeColor];
        cell.backgroundView.backgroundColor = [UIColor clearColor];
    }
    
    if ( 0 == indexPath.section ) { // User-Specific Playlists
    
        [self setupUserSpecificGroupsForRow:[indexPath row] inCell:cell];
        
    } else { // Category Playlists
    
        id category = [self.categories objectAtIndex:[indexPath row]];
        cell.textLabel.text = [self extractTitleFromCategory:category];
        
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate Methods
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return ( 0 == section ) ? @"My Stuff" : @"#Channels" ;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (0 == indexPath.section) { // User-Specific Playlists
        
        
    } else { // Category Playlists
        
        id category = [self.categories objectAtIndex:[indexPath row]];
        [self launchCategoryInRow:category];
        
    }
}


@end
