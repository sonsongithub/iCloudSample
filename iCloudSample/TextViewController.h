//
//  TextViewController.h
//  iCloudSample
//
//  Created by Yoshida Yuichi on 11/12/24.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MyDocument;

@interface TextViewController : UIViewController

@property (strong, nonatomic) MyDocument *document;
@property (strong, nonatomic) IBOutlet UITextView *textView;

- (IBAction)save:(id)sender;

@end
