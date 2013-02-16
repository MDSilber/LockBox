//
//  LockBoxListViewController.h
//  LockBox
//
//  Created by Mason Silber on 2/5/13.
//  Copyright (c) 2013 Mason Silber. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AddLockboxViewController.h"

@interface UIColor (UITableViewBackground)
+ (UIColor *)groupTableViewBackgroundColor;
@end

@implementation UIColor (UITableViewBackground)

+ (UIColor *)groupTableViewBackgroundColor
{
    __strong static UIImage* tableViewBackgroundImage = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(7.f, 1.f), NO, 0.0);
        CGContextRef c = UIGraphicsGetCurrentContext();
        [[self colorWithRed:185/255.f green:192/255.f blue:202/255.f alpha:1.f] setFill];
        CGContextFillRect(c, CGRectMake(0, 0, 4, 1));
        [[self colorWithRed:185/255.f green:193/255.f blue:200/255.f alpha:1.f] setFill];
        CGContextFillRect(c, CGRectMake(4, 0, 1, 1));
        [[self colorWithRed:192/255.f green:200/255.f blue:207/255.f alpha:1.f] setFill];
        CGContextFillRect(c, CGRectMake(5, 0, 2, 1));
        tableViewBackgroundImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    });
    return [self colorWithPatternImage:tableViewBackgroundImage];
}

@end

@interface LockBoxListViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, AddLockboxDelegate>

@property (nonatomic, strong) UITableView *lockboxTable;
@property (nonatomic, strong) NSMutableArray *lockboxes;

-(NSString *)checkIfPINExists;
-(void)addLockbox:(id)sender;
-(void)editLockboxes:(id)sender;
-(void)changePIN;

@end
