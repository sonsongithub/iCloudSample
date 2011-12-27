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
	
	dispatch_queue_t queue = 
	dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	
	dispatch_async(queue, ^{
	[self.managedDocument closeWithCompletionHandler:^(BOOL success) {
		NSLog(@"close");
	}];
	});
	
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
				
//		NSLog(@"only found booklist");		
//		NSMetadataItem *item = [query resultAtIndex:0];
//        NSURL *url = [item valueForAttribute:NSMetadataItemURLKey];
//        
//        self.managedDocument = [[[MyManagedDocument alloc] initWithFileURL:url] autorelease];
//		
//		NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:@"com.sonson.booklist", NSPersistentStoreUbiquitousContentNameKey,
//		 url, NSPersistentStoreUbiquitousContentURLKey,
//		 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
//		 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
//		 nil];
//		self.managedDocument.persistentStoreOptions = options;
//		
//        [self.managedDocument openWithCompletionHandler:^(BOOL success) {
//            if (success) {
//                NSLog(@"existing document opened from iCloud");
//				[[NSNotificationCenter defaultCenter] postNotificationName:@"didUpdateMyManagedDocument" object:nil userInfo:nil];
//            } else {
//                NSLog(@"existing document failed to open from iCloud");
//            }
//        }];
	}
	else {
		NSLog(@"can't find text.txt from iCloud");
		
		NSURL *ubiq = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
		NSURL *ubiquitousURL = [[ubiq URLByAppendingPathComponent:@"Documents"] URLByAppendingPathComponent:@"booklist"];
        
        self.managedDocument = [[[MyManagedDocument alloc] initWithFileURL:ubiquitousURL] autorelease];
		
		NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:@"com.sonson.booklist", NSPersistentStoreUbiquitousContentNameKey,
								 ubiquitousURL,														NSPersistentStoreUbiquitousContentURLKey,
								 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
								 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
								 nil];
		self.managedDocument.persistentStoreOptions = options;
		dispatch_queue_t queue = 
		dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
		
		dispatch_async(queue, ^{
        [self.managedDocument saveToURL:ubiquitousURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
            NSLog(@"new document save to iCloud");
            [self.managedDocument openWithCompletionHandler:^(BOOL success) {
                NSLog(@"new document opened from iCloud");
				[[NSNotificationCenter defaultCenter] postNotificationName:@"didUpdateMyManagedDocument" object:nil userInfo:nil];
            }];
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
