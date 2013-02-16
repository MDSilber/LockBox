//
//  LockBox.m
//  LockBox
//
//  Created by Mason Silber on 2/16/13.
//  Copyright (c) 2013 Mason Silber. All rights reserved.
//

#import "LockBox.h"


@implementation LockBox

@dynamic ipAddress;
@dynamic isLocked;
@dynamic name;

-(id)init
{
    self = [super init];
    if(self)
    {
        [self setIsLocked:@1];
    }
    return self;
}

@end
