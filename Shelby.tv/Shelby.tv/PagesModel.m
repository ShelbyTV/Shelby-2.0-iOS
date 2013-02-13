//
//  PageModel.m
//  Shelby.tv
//
//  Created by Keren on 2/13/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import "PagesModel.h"
#import "ChannelViewController.h"
#import "MeViewController.h"
#import "PageViewController.h"

@interface PagesModel()

@property (strong, nonatomic) NSMutableArray *pageData;

- (NSUInteger)indexOfViewController:(PageViewController *)viewController;

@end

@implementation PagesModel

// This is a dummy init until we get real data from the backend
- (id)init
{
    self = [super init];
    if (self) {

        // Create the data model.
        _pageData = [[NSMutableArray alloc] init];
        for (int i = 0; i < 4; i++) {
            [_pageData addObject:[NSNull null]];
        }
    
    }
    return self;
}

#pragma mark - Model Methods (Public)
- (PageViewController *)viewControllerAtIndex:(NSUInteger)index
{
    PageViewController *pageViewController = nil;
    if (index == 0) {
        pageViewController = [[MeViewController alloc] initWithNibName:@"MeViewController" bundle:nil];
    } else {
        pageViewController = [[ChannelViewController alloc] initWithNibName:@"ChannelView" bundle:nil];
    }
    
    [self.pageData setObject:[pageViewController description] atIndexedSubscript:index];
    return pageViewController;
}

#pragma mark - Model Methods (Private)
- (NSUInteger)indexOfViewController:(PageViewController *)viewController
{
    return [self.pageData indexOfObject:[viewController description]];
}

#pragma mark - UIPageViewControllerDataSource methods
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSUInteger index = [self indexOfViewController:(PageViewController *)viewController];
    if ((index == 0) || (index == NSNotFound)) {
        return nil;
    }
    
    index--;
    return [self viewControllerAtIndex:index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSUInteger index = [self indexOfViewController:(PageViewController *)viewController];
    if (index == NSNotFound) {
        return nil;
    }
    
    index++;
    if (index == [self.pageData count]) {
        return nil;
    }
    
    return [self viewControllerAtIndex:index];
}

@end
