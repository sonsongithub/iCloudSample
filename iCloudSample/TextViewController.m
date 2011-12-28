//
//  TextViewController.m
//  iCloudSample
//
//  Created by Yoshida Yuichi on 11/12/24.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "TextViewController.h"

#import "MyDocument.h"

@implementation TextViewController

@synthesize textView = _textView;
@synthesize document = _document;

- (void)dealloc {
	self.document = nil;
    self.textView = nil;
    [super dealloc];
}

- (void)didUpdateMyDocument:(NSNotification*)notification {
	id obj = [notification object];
	if (self.document == obj) {
		// update
		self.textView.text = self.document.text;
	}
}

- (void)viewDidLoad {
	[super viewDidLoad];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateMyDocument:) name:kDidUpdateMyDocumentNotification object:nil];
	self.textView.text = self.document.text;
}

- (IBAction)save:(id)sender {
	self.document.text = self.textView.text;
	[self.document updateChangeCount:UIDocumentChangeDone];
}

@end
