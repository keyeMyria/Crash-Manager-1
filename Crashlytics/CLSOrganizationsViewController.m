//
//  CLSOrganizationsViewController.m
//  Crashlytics
//
//  Created by Sasha Zats on 12/7/13.
//  Copyright (c) 2013 Sasha Zats. All rights reserved.
//

#import "CLSOrganizationsViewController.h"

#import "CLSAPIClient.h"
#import "CLSAccount.h"
#import "CLSApplicationsTableViewController.h"
#import "CLSOrganization.h"
#import <Crashlytics/Crashlytics.h>
#import <TTTLocalizedPluralString/TTTLocalizedPluralString.h>
#import <SHUIKitBlocks/SHUIKitBlocks.h>
#import "CLSPasteboardObserver.h"

@interface CLSOrganizationsViewController ()

@end

@implementation CLSOrganizationsViewController

#pragma mark - Actions

- (IBAction)_logoutBarButtonItemHandler:(id)sender {
	UIAlertView *alert = [UIAlertView SH_alertViewWithTitle:@"Logout?" withMessage:@"Are you sure you want to logout?"];
	[alert SH_addButtonCancelWithTitle:@"Cancel" withBlock:nil];
	[alert SH_addButtonWithTitle:@"Logout" withBlock:^(NSInteger theButtonIndex) {
		[CLSAccount setCurrentAccount:nil];
		
		
		NSPersistentStore *persistentStore = [NSPersistentStore MR_defaultPersistentStore];
		NSError *error = nil;
		
		NSURL *URL = [persistentStore URL];
		if (![[NSFileManager defaultManager] removeItemAtURL:URL
													   error:&error]) {
			NSLog(@"Failed to remove a persistent store at %@", [URL relativePath]);
		}
		
		[MagicalRecord cleanUp];
		[MagicalRecord setupAutoMigratingCoreDataStack];
	}];
	[alert show];
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	

	@weakify(self);
	[[[CLSAccount activeAccountChangedSignal]
		filter:^BOOL(CLSAccount *account) {
			return account != nil;
		}]
		subscribeNext:^(CLSAccount *account) {
			@strongify(self);
			NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%@ in %K", account, CLSOrganizationRelationships.accounts];

			self.fetchedResultsController = [CLSOrganization MR_fetchAllGroupedBy:nil
																 withPredicate:predicate
																	  sortedBy:CLSOrganizationAttributes.name
																	 ascending:YES];
			
			[[CLSPasteboardObserver sharedInstance] startObservingParsteboardWithNavigationController:self.navigationController];
		}];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	[[[CLSAccount activeAccountChangedSignal]
	  filter:^BOOL(CLSAccount *account) {
		  return account != nil;
	  }]
	 subscribeNext:^(CLSAccount *account) {
		 [[CLSAPIClient sharedInstance] organizations];
	 }];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"organizations-applications"]) {
		NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
		CLSOrganization *selectedOrganization = [self.fetchedResultsController objectAtIndexPath:selectedIndexPath];
		[((CLSApplicationsTableViewController *)segue.destinationViewController) setOrganization:selectedOrganization];
    }
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView
		 cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"OrganizationCellIdentifier"
															forIndexPath:indexPath];
	
	CLSOrganization *organization = [self.fetchedResultsController objectAtIndexPath:indexPath];
	cell.textLabel.text = organization.name;
	if (!organization.appsCountValue) {
		cell.detailTextLabel.text = NSLocalizedString(@"CLSOrganizationNoApps", @"No applications string for organization screen");
	} else {
		cell.detailTextLabel.text = TTTLocalizedPluralString(organization.appsCountValue, @"CLSOrganizationsAppsCount", @"Applications number for organization screen");
	}
	
	return cell;
}

@end