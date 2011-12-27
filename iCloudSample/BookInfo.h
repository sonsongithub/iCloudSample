//
//  BookInfo.h
//  iCloudSample
//
//  Created by Yoshida Yuichi on 11/12/24.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface BookInfo : NSManagedObject

@property (nonatomic, retain) NSString * title;
@property (nonatomic) int32_t price;

@end
