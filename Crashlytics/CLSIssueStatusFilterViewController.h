//
//  CLSIssueStatusFilterViewController.h
//  Crashlytics
//
//  Created by Sasha Zats on 12/30/13.
//  Copyright (c) 2013 Sasha Zats. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CLSFilter;
@interface CLSIssueStatusFilterViewController : UITableViewController

@property (nonatomic, weak) CLSFilter *filter;

@end