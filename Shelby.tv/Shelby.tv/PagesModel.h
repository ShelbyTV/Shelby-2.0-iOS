//
//  PageModel.h
//  Shelby.tv
//
//  Created by Keren on 2/13/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PageViewController;

@interface PagesModel : NSObject <UIPageViewControllerDataSource>

- (PageViewController *)viewControllerAtIndex:(NSUInteger)index;

@end
