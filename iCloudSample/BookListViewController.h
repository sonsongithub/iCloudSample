//
//  BookListViewController.h
//  iCloudSample
//
//  Created by Yoshida Yuichi on 11/12/24.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MyManagedDocument;

@interface BookListViewController : UITableViewController

@property (strong, nonatomic) NSMutableArray *array;
@property (strong, nonatomic) MyManagedDocument *managedDocument;

@end
