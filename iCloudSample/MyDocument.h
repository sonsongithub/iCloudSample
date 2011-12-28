//
//  MyDocument.h
//  iCloudSample
//
//  Created by Yoshida Yuichi on 11/12/24.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString *kDidUpdateMyDocumentNotification;

@interface MyDocument : UIDocument

@property (nonatomic, strong) NSString *text;

@end
