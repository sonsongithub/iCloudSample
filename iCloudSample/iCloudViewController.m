/*
 * iCloud Sample
 * iCloudViewController.m
 *
 * Copyright (c) Yuichi YOSHIDA, 11/12/27.
 * All rights reserved.
 * 
 * BSD License
 *
 * Redistribution and use in source and binary forms, with or without modification, are 
 * permitted provided that the following conditions are met:
 * - Redistributions of source code must retain the above copyright notice, this list of
 *  conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright notice, this list
 *  of conditions and the following disclaimer in the documentation and/or other materia
 * ls provided with the distribution.
 * - Neither the name of the "Yuichi Yoshida" nor the names of its contributors may be u
 * sed to endorse or promote products derived from this software without specific prior 
 * written permission.
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY E
 * XPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES O
 * F MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SH
 * ALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENT
 * AL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROC
 * UREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS I
 * NTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRI
 * CT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF T
 * HE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "iCloudViewController.h"

#import <CoreData/CoreData.h>

#import "MyDocument.h"
#import "MyManagedDocument.h"
#import "TextViewController.h"
#import "BookListViewController.h"

#define UBIQUITOUS_CONTENT_NAME			@"com.sonson.booklist"
#define UBIQUITOUS_TEXT_FILE_NAME		@"text.txt"
#define UBIQUITOUS_DATABASE_FILE_NAME	@"database"

@implementation iCloudViewController

@synthesize document = _document;
@synthesize managedDocument = _managedDocument;

@synthesize documentQuery = _documentQuery;
@synthesize managedDocumentQuery = _managedDocumentQuery;

#pragma mark - Instance method

- (void)openManagedDocumentWithUbiquitousContentURL:(NSURL*)ubiquitousContentURL ubiquitousContentName:(NSString*)ubiquitousContentName {
	self.managedDocument = [[[MyManagedDocument alloc] initWithFileURL:ubiquitousContentURL] autorelease];
	
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
							 ubiquitousContentName,			NSPersistentStoreUbiquitousContentNameKey,
							 ubiquitousContentURL,			NSPersistentStoreUbiquitousContentURLKey,
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

- (NSString*)ubiquitousContentNameWithNSMetadataItem:(NSMetadataItem*)item {
	NSURL *url = [item valueForAttribute:NSMetadataItemURLKey];
	
	NSNumber *downloadedKey = [item valueForAttribute:NSMetadataUbiquitousItemIsDownloadedKey];
	NSNumber *downloadingKey = [item valueForAttribute:NSMetadataUbiquitousItemIsDownloadingKey];
	
	if ([downloadedKey boolValue]) {
		NSLog(@"Already downloaded.");
	}
	else {
		if ([downloadingKey boolValue]) {
			NSLog(@"Still downloading.");
			return nil;
		}
		else {
			NSLog(@"Not yet.");
			NSError *error = nil;
			[[NSFileManager defaultManager] startDownloadingUbiquitousItemAtURL:url error:&error];
			if (error)
				NSLog(@"Can't start downloading - %@", [error localizedDescription]);
			else
				NSLog(@"Start downloading");
			return nil;
		}
	}
	
	NSData *data = [NSData dataWithContentsOfURL:url];
	NSString *errorDescription = nil;
	NSPropertyListFormat format = 0;
	NSDictionary* plist = [NSPropertyListSerialization propertyListFromData:data mutabilityOption:NSPropertyListImmutable format:&format errorDescription:&errorDescription];
	
	if(!plist) {
		NSLog(@"Error: %@", errorDescription);
		return nil;
	}
	
	return [plist objectForKey:@"NSPersistentStoreUbiquitousContentNameKey"];
}

- (void)createUbiquitousDatabaseFileWithDatabaseLocalURL:(NSURL*)databaseLocalURL databaseUbiquitousURL:(NSURL*)databaseUbiquitousURL ubiquitousContentName:(NSString*)ubiquitousContentName {
	
	MyManagedDocument *tempMyManagedDocument = [[MyManagedDocument alloc] initWithFileURL:databaseLocalURL];
	
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
							 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
							 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
							 nil];
	tempMyManagedDocument.persistentStoreOptions = options;
	
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_async(queue, ^{
		[tempMyManagedDocument saveToURL:databaseLocalURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
			if (success) {
				NSLog(@"Save on local storage");
				
				NSError *error = nil;
				if ([[NSFileManager defaultManager] setUbiquitous:YES itemAtURL:databaseLocalURL destinationURL:databaseUbiquitousURL error:&error]) {
					NSLog(@"Copy to iCloud storage");
				}
				else {
					NSLog(@"Can't copy to iCloud, error=%@", [error localizedDescription]);
					if ([[NSFileManager defaultManager] removeItemAtURL:databaseUbiquitousURL error:&error])
						NSLog(@"Remove existing ubiquitous URL = %@", databaseUbiquitousURL);
					else
						NSLog(@"Error=%@", [error localizedDescription]);
					
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
				
				self.managedDocument = [[[MyManagedDocument alloc] initWithFileURL:databaseUbiquitousURL] autorelease];
				
				NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
										 ubiquitousContentName,		NSPersistentStoreUbiquitousContentNameKey,
										 databaseUbiquitousURL,		NSPersistentStoreUbiquitousContentURLKey,
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
				[[NSFileManager defaultManager] removeItemAtURL:databaseLocalURL error:nil];
				[tempMyManagedDocument autorelease];
			}
		}];
	});
}

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
		NSFileCoordinator* fileCoordinator = [[[NSFileCoordinator alloc] initWithFilePresenter:nil] autorelease];
		[fileCoordinator coordinateWritingItemAtURL:URLforUIDocument
											options:NSFileCoordinatorWritingForDeleting
											  error:nil
										 byAccessor:^(NSURL* writingURL) {
											 NSError *error = nil;
											 NSFileManager* fileManager = [[[NSFileManager alloc] init] autorelease];
											 [fileManager removeItemAtURL:writingURL error:&error];
											 if (error)
												 NSLog(@"%@", [error localizedDescription]);
											 else
												NSLog(@"Delete file at %@", URLforUIDocument.absoluteString);
										 }];
	});
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
		NSFileCoordinator* fileCoordinator = [[[NSFileCoordinator alloc] initWithFilePresenter:nil] autorelease];
		[fileCoordinator coordinateWritingItemAtURL:URLforUIManagedDocument
											options:NSFileCoordinatorWritingForDeleting
											  error:nil
										 byAccessor:^(NSURL* writingURL) {
											 NSError *error = nil;
											 NSFileManager* fileManager = [[[NSFileManager alloc] init] autorelease];
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
		
		NSString *ubiquitousContentName = [self ubiquitousContentNameWithNSMetadataItem:item];
		NSURL *databaseFileUbiquitousURL = [[item valueForAttribute:NSMetadataItemURLKey] URLByDeletingLastPathComponent];
		
		[self openManagedDocumentWithUbiquitousContentURL:databaseFileUbiquitousURL ubiquitousContentName:ubiquitousContentName];
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
		
		NSString *ubiquitousContentName = [self ubiquitousContentNameWithNSMetadataItem:item];
		NSURL *databaseFileUbiquitousURL = [[item valueForAttribute:NSMetadataItemURLKey] URLByDeletingLastPathComponent];
		
		[self openManagedDocumentWithUbiquitousContentURL:databaseFileUbiquitousURL ubiquitousContentName:ubiquitousContentName];
	}
	else {
		NSLog(@"can't find DocumentMetadata from iCloud");
		NSURL *localURL = [self databaseFileLocalURL];
		NSURL *databaseFileUbiquitousURL = [self databaseFileUbiquitousURL];
		NSString *ubiquitousContentName = @"com.sonson.booklist";
		[self createUbiquitousDatabaseFileWithDatabaseLocalURL:localURL
										 databaseUbiquitousURL:databaseFileUbiquitousURL
										 ubiquitousContentName:ubiquitousContentName];
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
