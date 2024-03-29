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
-(BOOL)saveNewLockboxWithName:(NSString *)name andIPAddress:(NSString *)IPAddress andIdentifier:(NSString *)identifier;
-(BOOL)saveEditedLockbox:(LockBox *)lockbox withNewName:(NSString *)name andIPAddress:(NSString *)IPAddress;

@end

@interface AddLockboxViewController : UIViewController
@property (nonatomic, weak) id<AddLockboxDelegate> delegate;

-(id)initWithLockbox:(LockBox *)lockbox;
+(NSString *)generateIdentifier:(int)chars;

@end
