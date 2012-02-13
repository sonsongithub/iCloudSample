/*
 * iCloud Sample
 * BookListViewController.m
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

#import "BookListViewController.h"

#import <CoreData/CoreData.h>

#import "BookInfo.h"
#import "MyManagedDocument.h"

#import "AddNewBookViewController.h"

@implementation BookListViewController

@synthesize managedDocument = _managedDocument;
@synthesize array = _array;

- (void)dealloc {
	self.array = nil;
    self.managedDocument = nil;
    [super dealloc];
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)reloadDatabase {
	if (self.managedDocument == nil)
		return;
	
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"BookInfo" inManagedObjectContext:self.managedDocument.managedObjectContext];
	[request setEntity:entity];
	
//	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"price" ascending:NO];
//	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
//	[request setSortDescriptors:sortDescriptors];
//	[sortDescriptors release];
//	[sortDescriptor release];
	
	NSError *error = nil;
	NSMutableArray *mutableFetchResults = [[self.managedDocument.managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
	if (mutableFetchResults == nil) {
		NSLog(@"%@", [error localizedDescription]);
	}
	else {
		[self.array removeAllObjects];
		[self.array addObjectsFromArray:mutableFetchResults];
		[mutableFetchResults release];
		[self.tableView reloadData];
	}
}

- (void)didUpdateMyManagedDocument:(NSNotification*)notification {
	id obj = [notification object];
	if (self.managedDocument == obj) {
		// update
		[self reloadDatabase];
	}
}

- (void)viewDidLoad {
    [super viewDidLoad];
	self.array = [NSMutableArray array];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateMyManagedDocument:) name:kDidUpdateMyManagedDocumentNotification object:nil];
	[self reloadDatabase];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"OpenAddView"]) {
		UINavigationController *nav = segue.destinationViewController;
		AddNewBookViewController *con = (AddNewBookViewController*)[nav topViewController];
		con.managedDocument = self.managedDocument;
	}
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	[self reloadDatabase];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {

	if (editingStyle == UITableViewCellEditingStyleDelete) {
		// Delete the row from the data source
		BookInfo *info = [self.array objectAtIndex:indexPath.row];
		
		[self.managedDocument.managedObjectContext deleteObject:info];

		[self.array removeObjectAtIndex:indexPath.row];
		[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
	}
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.array count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"normal";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

	BookInfo *info = [self.array objectAtIndex:indexPath.row];
	cell.textLabel.text = info.title;
	cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", info.price];
    
    return cell;
}

@end
