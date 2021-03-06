//
//  CRMIssueExceptionViewController.m
//  Crash Manager
//
//  Created by Sasha Zats on 12/25/13.
//  Copyright (c) 2013 Sasha Zats. All rights reserved.
//

#import "CRMIssueExceptionViewController.h"

#import "CRMIncident.h"
#import "CRMIncident_Session+Crashlytics.h"
#import "UIViewController+OpenSource.h"
#import <SHAlertViewBlocks/SHAlertViewBlocks.h>

@interface CRMIssueExceptionViewController ()

@end

@implementation CRMIssueExceptionViewController

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
	if (![self.session.events count]) {
		return 0;
	}
	CRMSessionEvent *event = [self.session.events objectAtIndex:0];
	return [event.app.execution.exception.frames count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
		 cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	CRMSessionFrame *frame = [[self.session lastEvent].app.execution.exception.frames objectAtIndex:indexPath.row];
	uint64_t framePosition = frame.pc + frame.offset;
	CRMSessionBinaryImage *correspondingBinaryImage = [self.session binaryImageForAddress:framePosition];
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ExceptionCellIdentifier"
															forIndexPath:indexPath];
	BOOL isDeveloperCode = (frame.importance & CRMIncident_FrameImportanceInDeveloperCode) != 0;
	BOOL isCrashedFrame = (frame.importance & CRMIncident_FrameImportanceLikelyLeadToCrash) != 0;
	UIColor *color = isCrashedFrame ? [UIColor blackColor] : [UIColor lightGrayColor];
	cell.textLabel.font = isDeveloperCode ? [UIFont boldSystemFontOfSize:18] : [UIFont systemFontOfSize:18];
	cell.textLabel.textColor = color;
	cell.textLabel.text = frame.symbol;
	NSString *binaryName = correspondingBinaryImage.name ?: @"";
    NSURL *binaryImageURL;
    if (binaryName) {
        binaryImageURL = [NSURL fileURLWithPath:binaryName];
        if (binaryImageURL) {
            binaryName = [binaryImageURL lastPathComponent];
        }
    }
	cell.detailTextLabel.text = binaryName;
	
	return cell;
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];

	UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
	
	UIAlertView *alert = [UIAlertView SH_alertViewWithTitle:cell.detailTextLabel.text
												withMessage:cell.textLabel.text];
	[alert SH_addButtonWithTitle:@"Copy" withBlock:^(NSInteger theButtonIndex) {		
		[[UIPasteboard generalPasteboard] setString:[NSString stringWithFormat:@"%@ %@", cell.detailTextLabel.text, cell.textLabel.text]];
	}];
	[alert SH_addButtonCancelWithTitle:@"Cancel" withBlock:nil];
	[alert show];
}

@end
