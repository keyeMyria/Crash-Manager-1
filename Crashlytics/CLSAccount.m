#import "CLSAccount.h"

#import "CLSOrganization.h"

//#error Override password accessor to route it through the keychain, or make it transient

static NSString *const CLSCurrentAccountKeyName = @"CLSCurrentAccountKeyName";

NSString *const CLSActiveAccountDidChangeNotification = @"CLSActiveAccountDidChangeNotification";

@interface CLSAccount ()

+ (RACSubject *)activeAccountInternalSignal;

@end


@implementation CLSAccount

+ (RACSubject *)activeAccountInternalSignal {
	static RACSubject *instance;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		instance = [RACSubject subject];
	});
	return instance;
}

@end

@implementation CLSAccount (CLSSession)

- (void)updateWithContentsOfDictionary:(NSDictionary *)dictionary {
	self.userID = dictionary[@"id"];
	self.token = dictionary[@"token"];
	self.email = dictionary[@"email"];
	self.name = dictionary[@"name"];	
	if (dictionary[@"organizations"]) {
		NSMutableSet *organizations = [NSMutableSet set];
		for (NSDictionary *organizationDictionary in dictionary[@"organizations"]) {
			CLSOrganization *organization = [CLSOrganization organizationWithContentsOfDictionary:organizationDictionary
																						inContext:self.managedObjectContext];
			if (organization) {
				[organizations addObject:organization];
			}
		}
		self.organizations = organizations;
	}
}

- (void)updateOrganizationsWithContentsOfArray:(NSArray *)organizationsArray {
	NSManagedObjectContext *defaultContext = [NSManagedObjectContext MR_defaultContext];
	NSMutableSet *organizationsSet = [NSMutableSet setWithCapacity:[organizationsArray count]];
	for (NSDictionary *organizationDictioanry in organizationsArray) {
		CLSOrganization *organization = [CLSOrganization organizationWithContentsOfDictionary:organizationDictioanry
																					inContext:defaultContext];
		if (organization) {
			[organizationsSet addObject:organization];
		}
	}
	self.organizations = [organizationsSet copy];
}

- (BOOL)canCreateSession {
	return [self.email length] && [self.password length];	
}

- (BOOL)canRestoreSession {
	return [self.token length];
}

@end

@implementation CLSAccount (CLSCurrentAccount)

+ (RACSignal *)activeAccountChangedSignal {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
		[subscriber sendNext:[self activeAccount]];
		[[self activeAccountInternalSignal] subscribe:subscriber];
		return nil;
    }];
}

+ (void)setCurrentAccount:(CLSAccount *)account {
	if (!account) {
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:CLSCurrentAccountKeyName];
		[[NSUserDefaults standardUserDefaults] synchronize];
		[[[self class] activeAccountInternalSignal] sendNext:nil];
		return;
	}

	NSParameterAssert(![account.objectID isTemporaryID]);
	
	[[NSUserDefaults standardUserDefaults] setObject:[[account.objectID URIRepresentation] absoluteString]
											  forKey:CLSCurrentAccountKeyName];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:CLSActiveAccountDidChangeNotification
														object:nil];
	
	[[self activeAccountInternalSignal] sendNext:account];
}

+ (instancetype)activeAccount {
	return [self currentAccountInContext:[NSManagedObjectContext MR_contextForCurrentThread]];
}

+ (instancetype)currentAccountInContext:(NSManagedObjectContext *)context {
	NSString *objectIDURIString = [[NSUserDefaults standardUserDefaults] objectForKey:CLSCurrentAccountKeyName];
	NSURL *objectIDURI = [NSURL URLWithString:objectIDURIString];
	if (!objectIDURI) {
		return nil;
	}
	
	NSManagedObjectID *objectID = [context.persistentStoreCoordinator managedObjectIDForURIRepresentation:objectIDURI];
	if (!objectID) {
		return nil;
	}
	
    NSError *error = nil;
	CLSAccount *currentAccount = (CLSAccount *)[context existingObjectWithID:objectID error:&error];
#ifdef DEBUG
    if (error) {
        NSLog(@"%@", error);
    }
#endif
	return currentAccount;
}

@end