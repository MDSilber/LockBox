//
//  LockBoxListViewController.h
//  LockBox
//
//  Created by Mason Silber on 2/5/13.
//  Copyright (c) 2013 Mason Silber. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LockBox.h"

@interface LockBoxListViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *lockboxTable;
@property (nonatomic, strong) NSMutableArray *lockboxes;

-(NSString *)checkIfPINExists;
-(void)addLockbox:(id)sender;
-(void)editLockboxes:(id)sender;

@end
