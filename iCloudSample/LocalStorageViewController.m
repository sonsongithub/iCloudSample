//
//  LocalStorageViewController.m
//  iCloudSample
//
//  Created by Yoshida Yuichi on 11/12/24.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "LocalStorageViewController.h"

#import <CoreData/CoreData.h>

#import "MyDocument.h"
#import "MyManagedDocument.h"
#import "TextViewController.h"
#import "BookListViewController.h"

@implementation LocalStorageViewController

@synthesize document = _document;
@synthesize managedDocument = _managedDocument;

- (void)closeDocuments {
	[self.document closeWithCompletionHandler:^(BOOL success) {
	}];
    self.document = nil;
	[self.managedDocument closeWithCompletionHandler:^(BOOL success) {
	}];
	self.managedDocument = nil; 
}

- (void)openDocument {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *path = [NSString stringWithFormat:@"%@/text.txt", documentsDirectory];
	
	NSURL *URL = [NSURL fileURLWithPath:path];
	
	self.document = [[[MyDocument alloc] initWithFileURL:URL] autorelease];
	
	if ([[NSFileManager defaultManager] isReadableFileAtPath:path]) {
		[self.document openWithCompletionHandler:^(BOOL success) {
			if (success) {
				NSLog(@"existing document opened from Local");
				[[NSNotificationCenter defaultCenter] postNotificationName:@"didUpdateMyDocument" object:self.document userInfo:nil];
			} else {
				NSLog(@"existing document failed to open from Local");
			}
		}];
	}
	else {
		[self.document saveToURL:[self.document fileURL] forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
			NSLog(@"new document save to local");
			[self.document openWithCompletionHandler:^(BOOL success) {
				if (success) {
					NSLog(@"new document opened from local");
					[[NSNotificationCenter defaultCenter] postNotificationName:@"didUpdateMyDocument" object:self.document userInfo:nil];
				}
				else {
				}
			}];
		}];
	}
}

- (void)openManagedDocument {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *path = [NSString stringWithFormat:@"%@/booklist", documentsDirectory];
	NSURL *docURL = [NSURL fileURLWithPath:path];
	
	self.managedDocument = [[[MyManagedDocument alloc] initWithFileURL:docURL] autorelease];
	
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
							 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
							 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
	self.managedDocument.persistentStoreOptions = options;
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:[docURL path]]) {
		[self.managedDocument openWithCompletionHandler:^(BOOL success){
			if (success) {
				[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateMyManagedDocument:) name:@"didUpdateMyManagedDocument" object:nil];
			}
			else {
			}
		}];
	}
	else {
		[self.managedDocument saveToURL:docURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success){
			if (success) {
				[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateMyManagedDocument:) name:@"didUpdateMyManagedDocument" object:nil];
			}
			else {
			}
		}];
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
