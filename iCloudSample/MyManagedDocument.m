//
//  MyManagedDocument.m
//  iCloudSample
//
//  Created by Yoshida Yuichi on 11/12/24.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "MyManagedDocument.h"

#import <CoreData/CoreData.h>

NSString *kDidUpdateMyManagedDocumentNotification = @"kDidUpdateMyManagedDocumentNotification";

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

- (id)contentsForType:(NSString *)typeName error:(NSError *__autoreleasing *)outError {
    NSLog(@"Auto-Saving Document");
    return [super contentsForType:typeName error:outError];
}

- (void)handleError:(NSError *)error userInteractionPermitted:(BOOL)userInteractionPermitted {   
    NSLog(@"UIManagedDocument error: %@", error.localizedDescription);
    NSArray* errors = [[error userInfo] objectForKey:NSDetailedErrorsKey];
    if(errors != nil && errors.count > 0) {
        for (NSError *error in errors) {
            NSLog(@"  Error: %@", error.userInfo);
        }
    } else {
        NSLog(@"  %@", error.userInfo);
    }
}

@end
