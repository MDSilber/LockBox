//
//  LockBox.h
//  LockBox
//
//  Created by Mason Silber on 4/21/13.
//  Copyright (c) 2013 Mason Silber. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface LockBox : NSManagedObject

@property (nonatomic, retain) NSString * ipAddress;
@property (nonatomic, retain) NSNumber * isLocked;
@property (nonatomic, retain) NSNumber * lockboxNumber;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * identifier;

@end
