//
//  LockBox.m
//  LockBox
//
//  Created by Mason Silber on 2/5/13.
//  Copyright (c) 2013 Mason Silber. All rights reserved.
//

#import "LockBox.h"


@implementation LockBox

@dynamic name;
@dynamic IPAddress;
@dynamic isLocked;

-(id)init
{
    self = [super init];
    if(self)
    {
        //Note @1 is "object" version of the integer 1
        [self setIsLocked:@1];
    }
    return self;
}
@end
