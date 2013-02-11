//
//  AddLockboxViewController.m
//  LockBox
//
//  Created by Mason Silber on 2/11/13.
//  Copyright (c) 2013 Mason Silber. All rights reserved.
//

#import "AddLockboxViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface AddLockboxViewController ()
-(void)saveNewLockbox:(id)sender;
@end

#define ValidIPAddressRegex = @"^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$"

UITextField *lockBoxName, *lockBoxIPAddress;

@implementation AddLockboxViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        lockBoxName = [[UITextField alloc] initWithFrame:CGRectMake(50, 100, 220, 30)];
        [lockBoxName setBackgroundColor:[UIColor whiteColor]];
        [[lockBoxName layer] setCornerRadius:7.0];
        [[lockBoxName layer] setBorderColor:[[UIColor darkGrayColor] CGColor]];
        [[lockBoxName layer] setBorderWidth:1.0];
        [lockBoxName setPlaceholder:@"Name, e.g. Home door"];
        
        lockBoxIPAddress = [[UITextField alloc] initWithFrame:CGRectMake(50, 200, 220, 30)];
        [lockBoxIPAddress setBackgroundColor:[UIColor whiteColor]];
        [[lockBoxIPAddress layer] setCornerRadius:7.0];
        [[lockBoxIPAddress layer] setBorderColor:[[UIColor darkGrayColor] CGColor]];
        [[lockBoxIPAddress layer] setBorderWidth:1.0];
        [lockBoxIPAddress setPlaceholder:@"IP Address e.g. 192.168.153.132"];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [[self view] setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
    [[self view] addSubview:lockBoxName];
    [[self view] addSubview:lockBoxIPAddress];
    
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveNewLockbox:)];
    [[self navigationItem] setRightBarButtonItem:saveButton];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)saveNewLockbox:(id)sender
{
    
}
@end
