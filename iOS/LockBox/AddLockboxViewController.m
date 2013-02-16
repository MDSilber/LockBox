//
//  AddLockboxViewController.m
//  LockBox
//
//  Created by Mason Silber on 2/11/13.
//  Copyright (c) 2013 Mason Silber. All rights reserved.
//

#import "AddLockboxViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "AppDelegate.h"

@interface AddLockboxViewController ()

-(void)saveNewLockbox:(id)sender;
-(BOOL)validateLockboxFields;
-(BOOL)stringisValidIPAddress:(NSString *)IPAddress;

@end

UITextField *lockBoxName, *lockBoxIPAddress;
UILabel *nameLabel, *IPLabel;

@implementation AddLockboxViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 20, 220, 30)];
        [nameLabel setText:@"Lockbox Name"];
        [nameLabel setBackgroundColor:[UIColor clearColor]];
        
        lockBoxName = [[UITextField alloc] initWithFrame:CGRectMake(50, 50, 220, 30)];
        [lockBoxName setBackgroundColor:[UIColor whiteColor]];
        [[lockBoxName layer] setCornerRadius:7.0];
        [[lockBoxName layer] setBorderColor:[[UIColor darkGrayColor] CGColor]];
        [[lockBoxName layer] setBorderWidth:1.0];
        [lockBoxName setClearButtonMode:UITextFieldViewModeWhileEditing];
        [lockBoxName setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
        [lockBoxName setPlaceholder:@" e.g. Home door"];
        
        IPLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 100, 220, 30)];
        [IPLabel setText:@"Lockbox IP Address"];
        [IPLabel setBackgroundColor:[UIColor clearColor]];
        
        lockBoxIPAddress = [[UITextField alloc] initWithFrame:CGRectMake(50, 130, 220, 30)];
        [lockBoxIPAddress setBackgroundColor:[UIColor whiteColor]];
        [[lockBoxIPAddress layer] setCornerRadius:7.0];
        [[lockBoxIPAddress layer] setBorderColor:[[UIColor darkGrayColor] CGColor]];
        [[lockBoxIPAddress layer] setBorderWidth:1.0];
        [lockBoxIPAddress setClearButtonMode:UITextFieldViewModeWhileEditing];
        [lockBoxIPAddress setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
        [lockBoxIPAddress setPlaceholder:@" e.g. 192.168.153.132"];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [[self view] setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
    [[self view] addSubview:nameLabel];
    [[self view] addSubview:lockBoxName];
    [[self view] addSubview:IPLabel];
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
    if(![self validateLockboxFields])
        return;
    else
    {
        if([[self delegate] saveNewLockboxWithName:[lockBoxName text] andIPAddress:[lockBoxIPAddress text]])
        {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        else return;
    }
}

-(BOOL)validateLockboxFields
{
    if([[lockBoxName text] length] == 0)
    {
        UIAlertView *noNameAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Please enter a name for your lockbox" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [noNameAlert show];
        return NO;
    }
    
    if([[lockBoxIPAddress text] length] < 7 || [[lockBoxIPAddress text] length] > 15)
    {
        UIAlertView *invalidIPAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Please enter a valid IP address for your lockbox" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [invalidIPAlert show];
        return NO;
    }
    
    if([self stringisValidIPAddress:[lockBoxIPAddress text]])
    {
        UIAlertView *invalidIPAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Please enter a valid IP address for your lockbox" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [invalidIPAlert show];
        return NO;
    }
    
    return YES;
}

-(BOOL)stringisValidIPAddress:(NSString *)IPAddress
{
    NSString *IPAddressRegex = @"(http|https)://((\\w)*|([0-9]*)|([-|_])*)+([\\.|/]((\\w)*|([0-9]*)|([-|_])*))+";
    NSPredicate *IPAddressTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", IPAddressRegex];
    return [IPAddressTest evaluateWithObject:IPAddress];
}

@end
