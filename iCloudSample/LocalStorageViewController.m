/*
 * iCloud Sample
 * LocalStorageViewController.m
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

#import "LocalStorageViewController.h"

#import <CoreData/CoreData.h>

#import "MyDocument.h"
#import "MyManagedDocument.h"
#import "TextViewController.h"
#import "BookListViewController.h"

#define LOCAL_TEXT_FILE_NAME		@"local_text.txt"
#define LOCAL_DATABASE_FILE_NAME	@"local_database"

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
	NSString *path = [NSString stringWithFormat:@"%@/%@", documentsDirectory, LOCAL_TEXT_FILE_NAME];
	
	NSURL *URL = [NSURL fileURLWithPath:path];
	
	self.document = [[[MyDocument alloc] initWithFileURL:URL] autorelease];
	
	if ([[NSFileManager defaultManager] isReadableFileAtPath:path]) {
		[self.document openWithCompletionHandler:^(BOOL success) {
			if (success) {
				NSLog(@"existing document opened from Local");
				[[NSNotificationCenter defaultCenter] postNotificationName:kDidUpdateMyDocumentNotification object:self.document userInfo:nil];
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
					[[NSNotificationCenter defaultCenter] postNotificationName:kDidUpdateMyDocumentNotification object:self.document userInfo:nil];
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
	NSString *path = [NSString stringWithFormat:@"%@/%@", documentsDirectory, LOCAL_DATABASE_FILE_NAME];
	NSURL *docURL = [NSURL fileURLWithPath:path];
	
	self.managedDocument = [[[MyManagedDocument alloc] initWithFileURL:docURL] autorelease];
	
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
							 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
							 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
	self.managedDocument.persistentStoreOptions = options;
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:[docURL path]]) {
		[self.managedDocument openWithCompletionHandler:^(BOOL success){
			if (success) {
				[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateMyManagedDocument:) name:kDidUpdateMyManagedDocumentNotification object:nil];
			}
			else {
			}
		}];
	}
	else {
		[self.managedDocument saveToURL:docURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success){
			if (success) {
				[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateMyManagedDocument:) name:kDidUpdateMyManagedDocumentNotification object:nil];
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
