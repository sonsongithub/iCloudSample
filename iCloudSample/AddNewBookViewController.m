//
//  AddNewBookViewController.m
//  iCloudSample
//
//  Created by Yoshida Yuichi on 11/12/24.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "AddNewBookViewController.h"

#import <CoreData/CoreData.h>
#import "MyManagedDocument.h"
#import "BookInfo.h"

@implementation AddNewBookViewController

@synthesize bookTitleField = _bookTitleField;
@synthesize bookPriceField = _bookPriceField;
@synthesize managedDocument = _managedDocument;

- (void)dealloc {
	self.managedDocument = nil;
    self.bookTitleField = nil;
	self.bookPriceField = nil;
    [super dealloc];
}

- (IBAction)save:(id)sender {
	NSString *title = self.bookTitleField.text;
	int price = [self.bookPriceField.text intValue];
	
	if ([title length] && price > 0) {
		BookInfo *book = (BookInfo*)[NSEntityDescription insertNewObjectForEntityForName:@"BookInfo"
														  inManagedObjectContext:self.managedDocument.managedObjectContext];
		
		book.title = title;
		book.price = price;
		
		[self dismissModalViewControllerAnimated:YES];
	}
}

- (IBAction)cancel:(id)sender {
	[self dismissModalViewControllerAnimated:YES];
}

@end
