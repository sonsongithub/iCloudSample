//
//  BookListViewController.m
//  iCloudSample
//
//  Created by Yoshida Yuichi on 11/12/24.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

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
