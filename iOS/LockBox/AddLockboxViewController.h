//
//  AddLockboxViewController.h
//  LockBox
//
//  Created by Mason Silber on 2/11/13.
//  Copyright (c) 2013 Mason Silber. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LockBox.h"

@protocol AddLockboxDelegate
@required
-(BOOL)saveNewLockboxWithName:(NSString *)name andIPAddress:(NSString *)IPAddress;
-(BOOL)saveEditedLockbox:(LockBox *)lockbox withNewName:(NSString *)name andIPAddress:(NSString *)IPAddress;

@end

@interface AddLockboxViewController : UIViewController
@property (nonatomic, strong) id<AddLockboxDelegate> delegate;

-(id)initWithLockbox:(LockBox *)lockbox;

@end
