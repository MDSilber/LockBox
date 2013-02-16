//
//  LockBox.h
//  LockBox
//
//  Created by Mason Silber on 2/5/13.
//  Copyright (c) 2013 Mason Silber. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface LockBox : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * IPAddress;
@property (nonatomic, retain) NSNumber * isLocked;

@end
