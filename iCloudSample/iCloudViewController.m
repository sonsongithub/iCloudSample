//
//  iCloudViewController.m
//  iCloudSample
//
//  Created by Yoshida Yuichi on 11/12/24.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "iCloudViewController.h"

#import <CoreData/CoreData.h>

#import "MyDocument.h"
#import "MyManagedDocument.h"
#import "TextViewController.h"
#import "BookListViewController.h"

#define UBIQUITOUS_TEXT_FILE_NAME		@"text.txt"
#define UBIQUITOUS_DATABASE_FILE_NAME	@"database"

@implementation iCloudViewController

@synthesize document = _document;
@synthesize managedDocument = _managedDocument;

- (void)closeDocuments {
	[self.document closeWithCompletionHandler:^(BOOL success) {
	}];
    self.document = nil;
	
	[self.managedDocument closeWithCompletionHandler:^(BOOL success) {
		NSLog(@"close");
	}];
	self.managedDocument = nil; 
}

- (NSURL*)containerUbiquitousURL {
	return [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
}

- (NSURL*)documentFileUbiquitousURL {
	NSURL *ubiq = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
	NSURL *ubiquitousURL = [[ubiq URLByAppendingPathComponent:@"Documents"] URLByAppendingPathComponent:UBIQUITOUS_TEXT_FILE_NAME];
	return ubiquitousURL;
}

- (NSURL*)databaseFileLocalURL {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSURL *localURL = [[NSURL fileURLWithPath:documentsDirectory] URLByAppendingPathComponent:UBIQUITOUS_DATABASE_FILE_NAME];
	return localURL;
}

- (NSURL*)databaseFileUbiquitousURL {
	NSURL *ubiq = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
	NSURL *ubiquitousURL = [[ubiq URLByAppendingPathComponent:@"Documents"] URLByAppendingPathComponent:UBIQUITOUS_DATABASE_FILE_NAME];
	return ubiquitousURL;
}

#pragma mark - Notification handler

- (void)queryDidFinishGatheringForDocument:(NSNotification *)notification {
    NSMetadataQuery *query = [notification object];
    [query disableUpdates];
    [query stopQuery];
	
	if (query.resultCount == 1) {
		NSLog(@"found a document from iCloud");
		
		NSMetadataItem *item = [query resultAtIndex:0];
        NSURL *url = [item valueForAttribute:NSMetadataItemURLKey];
        
        self.document = [[[MyDocument alloc] initWithFileURL:url] autorelease];
		
        [self.document openWithCompletionHandler:^(BOOL success) {
            if (success) {
                NSLog(@"existing document opened from iCloud");
				[[NSNotificationCenter defaultCenter] postNotificationName:kDidUpdateMyDocumentNotification object:nil userInfo:nil];
            } else {
                NSLog(@"existing document failed to open from iCloud");
            }
        }];
	}
	
	else {
		NSLog(@"can't find a document from iCloud");
        NSURL *ubiquitousURL = [self documentFileUbiquitousURL];
        
		self.document = [[[MyDocument alloc] initWithFileURL:ubiquitousURL] autorelease];
		
        [self.document saveToURL:[self.document fileURL] forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
			if (success) {
				NSLog(@"new document save to iCloud");
				[self.document openWithCompletionHandler:^(BOOL success) {
					if (success) {
						NSLog(@"new document opened from iCloud");
						[[NSNotificationCenter defaultCenter] postNotificationName:kDidUpdateMyDocumentNotification object:nil userInfo:nil];
					}
				}];
			}
        }];
	}
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSMetadataQueryDidFinishGatheringNotification object:query];
	[query autorelease];
}

- (void)queryDidFinishGatheringForManagedDocument:(NSNotification *)notification {
    NSMetadataQuery *query = [notification object];
    [query disableUpdates];
    [query stopQuery];
	
	if (query.resultCount == 1) {
		NSLog(@"Found DocumentMetadata.plist.");		
		NSMetadataItem *item = [query resultAtIndex:0];
        NSURL *url = [item valueForAttribute:NSMetadataItemURLKey];
		
		NSLog(@"%@", url);
		
		NSData *data = [NSData dataWithContentsOfURL:url];
		NSString *errorDescription = nil;
		NSPropertyListFormat format = 0;
		NSDictionary* plist = [NSPropertyListSerialization propertyListFromData:data mutabilityOption:NSPropertyListImmutable format:&format errorDescription:&errorDescription];
		
		if(!plist) {
			NSLog(@"Error: %@", errorDescription);
			return;
		}
		
		NSString *key = [plist objectForKey:@"NSPersistentStoreUbiquitousContentNameKey"];
		NSURL *databaseFileUbiquitousURL = [url URLByDeletingLastPathComponent];
		
		NSLog(@"%@", key);
		NSLog(@"%@", databaseFileUbiquitousURL);
		
		self.managedDocument = [[[MyManagedDocument alloc] initWithFileURL:databaseFileUbiquitousURL] autorelease];
		
		NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
								 key,							NSPersistentStoreUbiquitousContentNameKey,
								 databaseFileUbiquitousURL,		NSPersistentStoreUbiquitousContentURLKey,
								 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
								 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
								 nil];
		self.managedDocument.persistentStoreOptions = options;
		dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

		dispatch_async(queue, ^{
			[self.managedDocument openWithCompletionHandler:^(BOOL success) {
				if (success) {
					NSLog(@"Open existing CoreData file from iCloud.");
					[[NSNotificationCenter defaultCenter] postNotificationName:kDidUpdateMyManagedDocumentNotification object:nil userInfo:nil];
				}
			}];
		});
	}
	else {
		NSLog(@"can't find DocumentMetadata from iCloud");
		NSURL *localURL = [self databaseFileLocalURL];
		NSURL *databaseFileUbiquitousURL = [self databaseFileUbiquitousURL];
		MyManagedDocument *tempMyManagedDocument = [[MyManagedDocument alloc] initWithFileURL:localURL];
		
		NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
								 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
								 nil];
		tempMyManagedDocument.persistentStoreOptions = options;
		
		dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
		dispatch_async(queue, ^{
			[tempMyManagedDocument saveToURL:localURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
				if (success) {
					NSLog(@"Save on local storage");
					
					// copy to iCloud storage
					NSError *error = nil;
					if ([[NSFileManager defaultManager] setUbiquitous:YES itemAtURL:localURL destinationURL:databaseFileUbiquitousURL error:&error]) {
						NSLog(@"Copy to iCloud storage");
					}
					else {
						NSLog(@"Can't copy to iCloud, error=%@", [error localizedDescription]);
						if ([[NSFileManager defaultManager] removeItemAtURL:databaseFileUbiquitousURL error:&error]) {
						}
						else {
							NSLog(@"Error=%@", [error localizedDescription]);
						}
						[tempMyManagedDocument closeWithCompletionHandler:^(BOOL success) {
							if (success)
								NSLog(@"close local CoreData document.");
							else
								NSLog(@"Error, can't close local CoreData document.");
							[tempMyManagedDocument autorelease];
						}];
						return;
					}
					
					[tempMyManagedDocument closeWithCompletionHandler:^(BOOL success) {
						if (success)
							NSLog(@"close local CoreData document.");
						else
							NSLog(@"Error, can't close local CoreData document.");
						[tempMyManagedDocument autorelease];
					}];
					
					self.managedDocument = [[[MyManagedDocument alloc] initWithFileURL:databaseFileUbiquitousURL] autorelease];
					
					NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
											 @"com.sonson.booklist",		NSPersistentStoreUbiquitousContentNameKey,
											 databaseFileUbiquitousURL,		NSPersistentStoreUbiquitousContentURLKey,
											 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
											 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
											 nil];
					self.managedDocument.persistentStoreOptions = options;
					[self.managedDocument openWithCompletionHandler:^(BOOL success) {
						if (success) {
							NSLog(@"Open new CoreData file from iCloud.");
							[[NSNotificationCenter defaultCenter] postNotificationName:kDidUpdateMyManagedDocumentNotification object:nil userInfo:nil];
						}
						else {
							NSLog(@"Error, can't open CoreData file from iCloud.");
						}
					}];
				}
				else {
					NSLog(@"Error, can't save on local storage");
					[[NSFileManager defaultManager] removeItemAtURL:localURL error:nil];
					[tempMyManagedDocument autorelease];
				}
			}];
		});
	}
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSMetadataQueryDidFinishGatheringNotification object:query];
	[query autorelease];
}

- (void)openDocument {
	NSURL *ubiq = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
	if (ubiq) {
		NSLog(@"Search a file from iCloud.");
		NSMetadataQuery *query = [[NSMetadataQuery alloc] init];
		[query setSearchScopes:[NSArray arrayWithObject:NSMetadataQueryUbiquitousDocumentsScope]];
		NSPredicate *pred = [NSPredicate predicateWithFormat: @"%K == %@", NSMetadataItemFSNameKey, UBIQUITOUS_TEXT_FILE_NAME];
		[query setPredicate:pred];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(queryDidFinishGatheringForDocument:) name:NSMetadataQueryDidFinishGatheringNotification object:query];
		[query startQuery];
	}
}

- (void)openManagedDocument {
	NSURL *ubiq = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
	if (ubiq) {
		NSLog(@"Search a file from iCloud.");
		NSMetadataQuery *query = [[NSMetadataQuery alloc] init];
		[query setSearchScopes:[NSArray arrayWithObject:NSMetadataQueryUbiquitousDocumentsScope]];
		NSPredicate *pred = [NSPredicate predicateWithFormat: @"%K == %@", NSMetadataItemFSNameKey, @"DocumentMetadata.plist"];
		[query setPredicate:pred];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(queryDidFinishGatheringForManagedDocument:) name:NSMetadataQueryDidFinishGatheringNotification object:query];
		[query startQuery];
	}
}

#pragma mark - Override

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"OpenTextView"]) {
		TextViewController *controller = segue.destinationViewController;
		controller.document = self.document;
	}
	else if ([segue.identifier isEqualToString:@"OpenBookListView"]) {
		BookListViewController *controller = segue.destinationViewController;
		controller.managedDocument = self.managedDocument;
	}
}

- (void)dealloc {
	[self closeDocuments];
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	[self openDocument];
	[self openManagedDocument];
}

- (void)viewDidUnload {
    [super viewDidUnload];
	[self closeDocuments];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
