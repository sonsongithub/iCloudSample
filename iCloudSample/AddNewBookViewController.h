//
//  AddNewBookViewController.h
//  iCloudSample
//
//  Created by Yoshida Yuichi on 11/12/24.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MyManagedDocument;

@interface AddNewBookViewController : UITableViewController

@property (strong, nonatomic) MyManagedDocument *managedDocument;
@property (strong, nonatomic) IBOutlet UITextField *bookTitleField;
@property (strong, nonatomic) IBOutlet UITextField *bookPriceField;

- (IBAction)save:(id)sender;
- (IBAction)cancel:(id)sender;

@end
