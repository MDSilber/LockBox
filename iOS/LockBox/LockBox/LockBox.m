//
//  LockBox.m
//  LockBox
//
//  Created by Mason Silber on 3/11/13.
//  Copyright (c) 2013 Mason Silber. All rights reserved.
//

#import "LockBox.h"


@implementation LockBox

@dynamic ipAddress;
@dynamic isLocked;
@dynamic name;
@dynamic lockboxNumber;

-(id)init
{
    self = [super init];
    if(self)
    {
        [self setIsLocked:@0];
    }
    return self;
}

@end
