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

@synthesize documentQuery = _documentQuery;
@synthesize managedDocumentQuery = _managedDocumentQuery;

#pragma mark - Instance method

- (void)closeDocuments {
	[self.document closeWithCompletionHandler:^(BOOL success) {
	}];
    self.document = nil;
	
	[self.managedDocument closeWithCompletionHandler:^(BOOL success) {
		NSLog(@"close");
	}];
	self.managedDocument = nil; 
}

- (void)deleteFiles {
	NSURL *URLforUIDocument = self.document.fileURL;
	NSURL *URLforUIManagedDocument = self.managedDocument.fileURL;
	
	[self closeDocuments];
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
		NSFileCoordinator* fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
		[fileCoordinator coordinateWritingItemAtURL:URLforUIDocument
											options:NSFileCoordinatorWritingForDeleting
											  error:nil
										 byAccessor:^(NSURL* writingURL) {
											 NSError *error = nil;
											 NSFileManager* fileManager = [[NSFileManager alloc] init];
											 [fileManager removeItemAtURL:writingURL error:&error];
											 if (error)
												 NSLog(@"%@", [error localizedDescription]);
											 else
												NSLog(@"Delete file at %@", URLforUIDocument.absoluteString);
										 }];
	});
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
		NSFileCoordinator* fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
		[fileCoordinator coordinateWritingItemAtURL:URLforUIManagedDocument
											options:NSFileCoordinatorWritingForDeleting
											  error:nil
										 byAccessor:^(NSURL* writingURL) {
											 NSError *error = nil;
											 NSFileManager* fileManager = [[NSFileManager alloc] init];
											 [fileManager removeItemAtURL:writingURL error:&error];
											 if (error)
												 NSLog(@"%@", [error localizedDescription]);
											 else
												 NSLog(@"Delete file at %@", URLforUIManagedDocument.absoluteString);
										 }];
	});
}

- (void)prepareQueryForDocument {
	NSURL *ubiq = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
	if (ubiq) {
		self.documentQuery = [[[NSMetadataQuery alloc] init] autorelease];
		[self.documentQuery setSearchScopes:[NSArray arrayWithObject:NSMetadataQueryUbiquitousDocumentsScope]];
		NSPredicate *pred = [NSPredicate predicateWithFormat: @"%K == %@", NSMetadataItemFSNameKey, UBIQUITOUS_TEXT_FILE_NAME];
		[self.documentQuery setPredicate:pred];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(queryDidFinishGatheringForDocument:)
													 name:NSMetadataQueryDidFinishGatheringNotification
												   object:self.documentQuery];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(queryDidUpdateForDocument:)
													 name:NSMetadataQueryDidUpdateNotification
												   object:self.managedDocumentQuery];
		[self.documentQuery startQuery];
	}
}

- (void)prepareQueryForManagedDocument {
	NSURL *ubiq = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
	if (ubiq) {
		self.managedDocumentQuery = [[[NSMetadataQuery alloc] init] autorelease];
		[self.managedDocumentQuery setSearchScopes:[NSArray arrayWithObject:NSMetadataQueryUbiquitousDocumentsScope]];
		NSPredicate *pred = [NSPredicate predicateWithFormat: @"%K == %@", NSMetadataItemFSNameKey, @"DocumentMetadata.plist"];
		[self.managedDocumentQuery setPredicate:pred];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(queryDidFinishGatheringForManagedDocument:)
													 name:NSMetadataQueryDidFinishGatheringNotification
												   object:self.managedDocumentQuery];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(queryDidUpdateForManagedDocument:)
													 name:NSMetadataQueryDidUpdateNotification
												   object:self.managedDocumentQuery];
		[self.managedDocumentQuery startQuery];
	}
}

#pragma mark - URL

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

- (void)createOrOpenMyDocument {
	
}

#pragma mark - Notification handler

- (void)queryDidUpdateForDocument:(NSNotification *)notification {
}

- (void)queryDidFinishGatheringForDocument:(NSNotification *)notification {
    [self.documentQuery disableUpdates];
    [self.documentQuery stopQuery];
	
	if (self.documentQuery.resultCount == 1) {
		NSLog(@"found a document from iCloud");
		
		NSMetadataItem *item = [self.documentQuery resultAtIndex:0];
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
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSMetadataQueryDidFinishGatheringNotification object:self.documentQuery];
	[self.documentQuery enableUpdates];
}

- (void)queryDidUpdateForManagedDocument:(NSNotification *)notification {
	NSLog(@"queryDidUpdateForManagedDocument:");
	[self.managedDocumentQuery disableUpdates];
    [self.managedDocumentQuery stopQuery];
	
	if (self.managedDocumentQuery.resultCount == 1) {
		NSLog(@"Found DocumentMetadata.plist.");		
		NSMetadataItem *item = [self.managedDocumentQuery resultAtIndex:0];
        NSURL *url = [item valueForAttribute:NSMetadataItemURLKey];
		
		NSLog(@"%@", url);
		
		NSNumber *downloadedKey = [item valueForAttribute:NSMetadataUbiquitousItemIsDownloadedKey];
		NSNumber *downloadingKey = [item valueForAttribute:NSMetadataUbiquitousItemIsDownloadingKey];
		
		if ([downloadedKey boolValue]) {
			NSLog(@"Already downloaded.");
		}
		else {
			if ([downloadingKey boolValue]) {
				NSLog(@"Still downloading.");
				return;
			}
			else {
				NSLog(@"Not yet.");
				NSError *error = nil;
				[[NSFileManager defaultManager] startDownloadingUbiquitousItemAtURL:url error:&error];
				if (error) {
					NSLog(@"Can't start downloading - %@", [error localizedDescription]);
				}
				else {
					NSLog(@"Start downloading");
				}
				return;
			}
		}
		
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
	[self.managedDocumentQuery enableUpdates];
}

- (void)queryDidFinishGatheringForManagedDocument:(NSNotification *)notification {
	NSLog(@"queryDidFinishGatheringForManagedDocument:");
	
    [self.managedDocumentQuery disableUpdates];
    [self.managedDocumentQuery stopQuery];
	
	if (self.managedDocumentQuery.resultCount == 1) {
		NSLog(@"Found DocumentMetadata.plist.");		
		NSMetadataItem *item = [self.managedDocumentQuery resultAtIndex:0];
        NSURL *url = [item valueForAttribute:NSMetadataItemURLKey];
		
		NSLog(@"%@", url);
		
		NSNumber *downloadedKey = [item valueForAttribute:NSMetadataUbiquitousItemIsDownloadedKey];
		NSNumber *downloadingKey = [item valueForAttribute:NSMetadataUbiquitousItemIsDownloadingKey];
		
		if ([downloadedKey boolValue]) {
			NSLog(@"Already downloaded.");
		}
		else {
			if ([downloadingKey boolValue]) {
				NSLog(@"Still downloading.");
				return;
			}
			else {
				NSLog(@"Not yet.");
				NSError *error = nil;
				[[NSFileManager defaultManager] startDownloadingUbiquitousItemAtURL:url error:&error];
				if (error) {
					NSLog(@"Can't start downloading - %@", [error localizedDescription]);
				}
				else {
					NSLog(@"Start downloading");
				}
				return;
			}
		}
		
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
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSMetadataQueryDidFinishGatheringNotification object:self.managedDocumentQuery];
	[self.managedDocumentQuery enableUpdates];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 1 && indexPath.row == 0) {
		NSLog(@"delete files on iCloud");
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
		[self deleteFiles];
		[self.navigationController popViewControllerAnimated:YES];
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
	self.managedDocumentQuery = nil;
	self.documentQuery = nil;
	[self closeDocuments];
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self.documentQuery startQuery];
	[self.documentQuery enableUpdates];
	[self.managedDocumentQuery startQuery];
	[self.managedDocumentQuery enableUpdates];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[self.documentQuery stopQuery];
	[self.documentQuery disableUpdates];
	[self.managedDocumentQuery stopQuery];
	[self.managedDocumentQuery disableUpdates];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	[self prepareQueryForDocument];
	[self prepareQueryForManagedDocument];
}

- (void)viewDidUnload {
    [super viewDidUnload];
	[self.managedDocumentQuery stopQuery];
	self.managedDocumentQuery = nil;
	[self.documentQuery stopQuery];
	self.documentQuery = nil;
	[self closeDocuments];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
