/*
 * iCloud Sample
 * MyDocument.m
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

#import "MyDocument.h"

NSString *kDidUpdateMyDocumentNotification = @"kDidUpdateMyDocumentNotification";

@implementation MyDocument

@synthesize text = _text;

- (void)dealloc {
	NSLog(@"MyDocument - dealloc");
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
		[[NSNotificationCenter defaultCenter] postNotificationName:kDidUpdateMyDocumentNotification object:self userInfo:nil];
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
