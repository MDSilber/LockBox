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
#import "AFNetworking.h"

@interface AddLockboxViewController ()

@property (nonatomic, strong) UITextField *lockBoxName, *lockBoxIPAddress;
@property (nonatomic, strong) UILabel *nameLabel, *IPLabel;
@property BOOL isEditingLockbox;
@property (nonatomic, strong) LockBox *lockboxBeingEdited;

-(void)saveLockbox:(id)sender;
-(BOOL)validateLockboxFields;
-(BOOL)stringisValidIPAddress:(NSString *)IPAddress;

@end

@implementation AddLockboxViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 20, 220, 30)];
        [_nameLabel setText:@"Lockbox Name"];
        [_nameLabel setBackgroundColor:[UIColor clearColor]];
        
        _lockBoxName = [[UITextField alloc] initWithFrame:CGRectMake(50, 50, 220, 30)];
        [_lockBoxName setBackgroundColor:[UIColor whiteColor]];
        [[_lockBoxName layer] setCornerRadius:7.0];
        [[_lockBoxName layer] setBorderColor:[[UIColor darkGrayColor] CGColor]];
        [[_lockBoxName layer] setBorderWidth:1.0];
        [_lockBoxName setClearButtonMode:UITextFieldViewModeWhileEditing];
        [_lockBoxName setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
        [_lockBoxName setPlaceholder:@" e.g. Home door"];
        
        _IPLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 100, 220, 30)];
        [_IPLabel setText:@"Lockbox IP Address"];
        [_IPLabel setBackgroundColor:[UIColor clearColor]];
        
        _lockBoxIPAddress = [[UITextField alloc] initWithFrame:CGRectMake(50, 130, 220, 30)];
        [_lockBoxIPAddress setBackgroundColor:[UIColor whiteColor]];
        [[_lockBoxIPAddress layer] setCornerRadius:7.0];
        [[_lockBoxIPAddress layer] setBorderColor:[[UIColor darkGrayColor] CGColor]];
        [[_lockBoxIPAddress layer] setBorderWidth:1.0];
        [_lockBoxIPAddress setClearButtonMode:UITextFieldViewModeWhileEditing];
        [_lockBoxIPAddress setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
        [_lockBoxIPAddress setPlaceholder:@" e.g. 192.168.153.132"];
        _lockboxBeingEdited = nil;
    }
    return self;
}

-(id)initWithLockbox:(LockBox *)lockbox
{
    self = [self initWithNibName:nil bundle:nil];
    if(self)
    {
        [_lockBoxName setText:[lockbox name]];
        [_lockBoxIPAddress setText:[lockbox ipAddress]];
        _lockboxBeingEdited = lockbox;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [[self view] setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
    [[self view] addSubview:_nameLabel];
    [[self view] addSubview:_lockBoxName];
    [[self view] addSubview:_IPLabel];
    [[self view] addSubview:_lockBoxIPAddress];
    
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveLockbox:)];
    [[self navigationItem] setRightBarButtonItem:saveButton];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

+(NSString *)generateIdentifier:(int)numChars
{
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *identifier = [NSMutableString stringWithCapacity:numChars];
    for(int i = 0; i < numChars; i++)
    {
        [identifier appendFormat:@"%C", [letters characterAtIndex:(arc4random() % [letters length])]];
    }
    
    return identifier;
}

-(void)saveLockbox:(id)sender
{
    if(![self validateLockboxFields])
        return;
    
    NSURL *lockboxURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/create/?key=%@&lockboxid=%@", [_lockBoxIPAddress text], [AddLockboxViewController generateIdentifier:20], [_lockBoxName text]]];
    NSURLRequest *lockboxRequest = [NSURLRequest requestWithURL:lockboxURL];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:lockboxRequest
                                                                                        success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSString *success = (NSString*)[JSON valueForKeyPath:@"success"];
        if ([success isEqualToString:@"false"]) {
            return;
        }
        if(_lockboxBeingEdited != nil)
        {
            if([[self delegate] saveEditedLockbox:_lockboxBeingEdited withNewName:[_lockBoxName text] andIPAddress:[_lockBoxIPAddress text]])
            {
                [[self navigationController] popViewControllerAnimated:YES];
            }
            else return;
        }
        else
        {
            if([[self delegate] saveNewLockboxWithName:[_lockBoxName text] andIPAddress:[_lockBoxIPAddress text] andIdentifier:[AddLockboxViewController generateIdentifier:20]])
            {
                [[self navigationController] popViewControllerAnimated:YES];
            }
            else return;
        }
    }
                                                                                        failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        return;
                                                                                        }];
    [operation start];
}

-(BOOL)validateLockboxFields
{
    if([[_lockBoxName text] length] == 0)
    {
        UIAlertView *noNameAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Please enter a name for your lockbox" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [noNameAlert show];
        return NO;
    }
    
    if([[_lockBoxIPAddress text] length] < 7 || [[_lockBoxIPAddress text] length] > 15)
    {
        UIAlertView *invalidIPAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Please enter a valid IP address for your lockbox" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [invalidIPAlert show];
        return NO;
    }
    
    if([self stringisValidIPAddress:[_lockBoxIPAddress text]])
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
