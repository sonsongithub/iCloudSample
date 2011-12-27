//
//  MyManagedDocument.m
//  iCloudSample
//
//  Created by Yoshida Yuichi on 11/12/24.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "MyManagedDocument.h"

@implementation MyManagedDocument

- (void)dealloc {
	NSLog(@"MyManagedDocument - dealloc");
    [super dealloc];
}


- (void)NSLogInfo {
	NSLog(@"File name = %@", self.fileURL);
	NSLog(@"File type = %@", self.fileType);
	NSLog(@"Last modification date = %@", self.fileModificationDate);
	NSMutableString *string = [NSMutableString stringWithString:@"State"];
	
	if (self.documentState == UIDocumentStateNormal)
		[string appendString:@"|UIDocumentStateNormal"];
	if (self.documentState & UIDocumentStateClosed)
		[string appendString:@"|UIDocumentStateClosed"];
	if (self.documentState & UIDocumentStateInConflict)
		[string appendString:@"|UIDocumentStateInConflict"];
	if (self.documentState & UIDocumentStateSavingError)
		[string appendString:@"|UIDocumentStateSavingError"];
	if (self.documentState & UIDocumentStateEditingDisabled)
		[string appendString:@"|UIDocumentStateEditingDisabled"];
	NSLog(@"State = %@", string);
}

- (void)DocumentStateChanged:(NSNotification*)notification {
	[self NSLogInfo];
}

- (id)initWithFileURL:(NSURL *)url {
    if ((self = [super initWithFileURL:url])) {
        NSLog(@"document created with URL: %@", url);
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(DocumentStateChanged:) name:UIDocumentStateChangedNotification object:nil];
    }
    return self;
}

@end
