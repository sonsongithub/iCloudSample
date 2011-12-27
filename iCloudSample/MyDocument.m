//
//  MyDocument.m
//  iCloudSample
//
//  Created by Yoshida Yuichi on 11/12/24.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "MyDocument.h"

@implementation MyDocument

@synthesize text = _text;

- (void)dealloc {
	NSLog(@"dealloc");
    self.text = nil;
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
	
	if (self.documentState &  UIDocumentStateEditingDisabled) {
	}
	else {
		// this document is enabled.
		if (self.documentState & UIDocumentStateInConflict) {
			NSError *error = nil;
			NSArray *conflictVersions = [NSFileVersion unresolvedConflictVersionsOfItemAtURL:[self fileURL]];
			
			if ([conflictVersions count]) {
				NSFileVersion *latestVersion = [conflictVersions objectAtIndex:0];
				
				for (NSFileVersion *conflictVersion in conflictVersions) {
					if ([conflictVersion.modificationDate compare:latestVersion.modificationDate] == NSOrderedDescending)
						latestVersion = conflictVersion;
				}
				NSData *data = [NSData dataWithContentsOfURL:latestVersion.URL];
				
				// load latest data
				[self loadFromContents:data ofType:@"public.plain-text" error:&error];
				
				// clean up conficting versions.
				for (NSFileVersion *conflictVersion in conflictVersions)
					conflictVersion.resolved = YES;
			}
			
			NSFileVersion *currentVersion = [NSFileVersion currentVersionOfItemAtURL:[self fileURL]];
			currentVersion.resolved = YES;
			[NSFileVersion removeOtherVersionsOfItemAtURL:[self fileURL] error:&error];
			
		}
		else {
		}
		
		// post message to update a view.
		[[NSNotificationCenter defaultCenter] postNotificationName:@"didUpdateMyDocument" object:self userInfo:nil];
	}
}

- (id)initWithFileURL:(NSURL *)url {
    if ((self = [super initWithFileURL:url])) {
        NSLog(@"document created with URL: %@", url);
		self.text = @"";
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(DocumentStateChanged:) name:UIDocumentStateChangedNotification object:nil];
    }
    return self;
}

- (id)contentsForType:(NSString *)typeName error:(NSError **)outError {

    if ([typeName isEqualToString:@"public.plain-text"]) {
        return [self.text dataUsingEncoding:NSUTF8StringEncoding];
    }
	else {
        NSLog(@"unexpected typeName");
        if (outError) {
            *outError = [NSError errorWithDomain:@"com.sonson.icloudTest"
											code:22
										userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
												  @"Unrecongnized document type", NSLocalizedDescriptionKey, nil]];
        }
        return nil;
    }
}

- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError **)outError {
	
    if ([typeName isEqualToString:@"public.plain-text"]) {
		
		if ([contents isKindOfClass:[NSData class]]) {
			self.text = [[[NSString alloc] initWithData:contents encoding:NSUTF8StringEncoding] autorelease];
			return YES;
		}
		else
			return NO;
    }
	else {
        NSLog(@"unexpected typeName");
        if (outError) {
            *outError = [NSError errorWithDomain:@"com.sonson.icloudTest"
											code:22
										userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
												  @"Unrecongnized document type", NSLocalizedDescriptionKey, nil]];
        }
        return NO;
    }
}

@end
