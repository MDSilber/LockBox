//
//  LockBoxListViewController.h
//  LockBox
//
//  Created by Mason Silber on 2/5/13.
//  Copyright (c) 2013 Mason Silber. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AddLockboxViewController.h"

@interface LockBoxListViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, AddLockboxDelegate>

@property (nonatomic, strong) UITableView *lockboxTable;
@property (nonatomic, strong) NSMutableArray *lockboxes;

-(NSString *)checkIfPINExists;
-(void)addLockbox:(id)sender;
-(void)editLockboxes:(id)sender;
-(void)changePIN;
-(void)loadLockboxes;

@end
