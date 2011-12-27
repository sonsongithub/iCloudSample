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

- (void)queryDidFinishGatheringForDocument:(NSNotification *)notification {
    NSMetadataQuery *query = [notification object];
    [query disableUpdates];
    [query stopQuery];
	
	if (query.resultCount == 1) {
		NSLog(@"only found text.txt");
		
		NSMetadataItem *item = [query resultAtIndex:0];
        NSURL *url = [item valueForAttribute:NSMetadataItemURLKey];
        
        self.document = [[[MyDocument alloc] initWithFileURL:url] autorelease];
		
        [self.document openWithCompletionHandler:^(BOOL success) {
            if (success) {
                NSLog(@"existing document opened from iCloud");
				[[NSNotificationCenter defaultCenter] postNotificationName:@"didUpdateMyDocument" object:nil userInfo:nil];
            } else {
                NSLog(@"existing document failed to open from iCloud");
            }
        }];
	}
	
	else {
		NSLog(@"can't find text.txt from iCloud");
        NSURL *ubiq = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
        NSURL *ubiquitousURL = [[ubiq URLByAppendingPathComponent:@"Documents"] URLByAppendingPathComponent:@"text.txt"];
        
		self.document = [[[MyDocument alloc] initWithFileURL:ubiquitousURL] autorelease];
		
        [self.document saveToURL:[self.document fileURL] forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
            NSLog(@"new document save to iCloud");
            [self.document openWithCompletionHandler:^(BOOL success) {
                NSLog(@"new document opened from iCloud");
				[[NSNotificationCenter defaultCenter] postNotificationName:@"didUpdateMyDocument" object:nil userInfo:nil];
            }];
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
		NSLog(@"DocumentMetadata");
		
		NSMetadataItem *item = [query resultAtIndex:0];
        NSURL *url = [item valueForAttribute:NSMetadataItemURLKey];
		NSLog(@"%@", url);
		
		NSData *data = [NSData dataWithContentsOfURL:url];
		
		NSLog(@"%d", [data length]);
		
		NSLog(@"%@", [NSString stringWithUTF8String:[data bytes]]);
		
		NSString *error;
		NSPropertyListFormat format;
		NSDictionary* plist = [NSPropertyListSerialization propertyListFromData:data mutabilityOption:NSPropertyListImmutable format:&format errorDescription:&error];
		NSLog( @"plist is %@", plist );
		if(!plist){
			NSLog(@"Error: %@",error);
			[error release];
		}
		
		NSString *key = [plist objectForKey:@"NSPersistentStoreUbiquitousContentNameKey"];
		NSURL *ubiURL = [url URLByDeletingLastPathComponent];
		
        self.managedDocument = [[[MyManagedDocument alloc] initWithFileURL:ubiURL] autorelease];
		
		NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:key,	NSPersistentStoreUbiquitousContentNameKey,
								 ubiURL,									NSPersistentStoreUbiquitousContentURLKey,
								 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
								 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
								 nil];
		self.managedDocument.persistentStoreOptions = options;
		dispatch_queue_t queue = 
		dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
		
		dispatch_async(queue, ^{
			[self.managedDocument openWithCompletionHandler:^(BOOL success) {
				if (success) {
					NSLog(@"Open");
					[[NSNotificationCenter defaultCenter] postNotificationName:@"didUpdateMyManagedDocument" object:nil userInfo:nil];
				}
			}];
		});
	}
	else {
		NSLog(@"can't find DocumentMetadata from iCloud");
		
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *documentsDirectory = [paths objectAtIndex:0];
		
		NSURL *localURL = [NSURL fileURLWithPath:[documentsDirectory stringByAppendingPathComponent:@"booklist3"]];
		
		NSURL *ubiq = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
        NSURL *ubiquitousURL = [[ubiq URLByAppendingPathComponent:@"Documents"] URLByAppendingPathComponent:@"booklist3"];
        
        self.managedDocument = [[[MyManagedDocument alloc] initWithFileURL:localURL] autorelease];
		
		NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:@"com.sonson.booklist",	NSPersistentStoreUbiquitousContentNameKey,
								 ubiq,																NSPersistentStoreUbiquitousContentURLKey,
								 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
								 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
								 nil];
		self.managedDocument.persistentStoreOptions = options;
		dispatch_queue_t queue = 
		dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
		
		
		dispatch_async(queue, ^{
        [self.managedDocument saveToURL:localURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
			if (success) {
				NSLog(@"Save");
				[self.managedDocument openWithCompletionHandler:^(BOOL success) {
					if (success) {
					//	NSLog(@"Open");
					//	[[NSNotificationCenter defaultCenter] postNotificationName:@"didUpdateMyManagedDocument" object:nil userInfo:nil];
					}
				}];
				
				NSError *error = nil;
				[[NSFileManager defaultManager] 
				 setUbiquitous:YES
				 itemAtURL:localURL
				 destinationURL:ubiquitousURL
				 error:&error];
				NSLog(@"Error=%@", [error localizedDescription]);
				
				self.managedDocument = [[[MyManagedDocument alloc] initWithFileURL:ubiquitousURL] autorelease];
				
				NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:@"com.sonson.booklist",	NSPersistentStoreUbiquitousContentNameKey,
										 ubiq,																NSPersistentStoreUbiquitousContentURLKey,
										 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
										 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
										 nil];
				self.managedDocument.persistentStoreOptions = options;
				[self.managedDocument openWithCompletionHandler:^(BOOL success) {
					if (success) {
						NSLog(@"Open");
						[[NSNotificationCenter defaultCenter] postNotificationName:@"didUpdateMyManagedDocument" object:nil userInfo:nil];
					}
				}];
//				dispatch_queue_t queue = 
//				dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
//				
//				dispatch_async(queue, ^{
//					NSError *error = nil;
//					[[NSFileManager defaultManager] 
//					 setUbiquitous:YES
//					 itemAtURL:localURL
//					 destinationURL:ubiquitousURL
//					 error:&error];
//					NSLog(@"%@", [error localizedDescription]);
//				});
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
		NSPredicate *pred = [NSPredicate predicateWithFormat: @"%K == %@", NSMetadataItemFSNameKey, @"text.txt"];
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
	[self closeDocuments];
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	//[self openDocument];
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
