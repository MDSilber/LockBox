//
//  LockBoxListViewController.m
//  LockBox
//
//  Created by Mason Silber on 2/5/13.
//  Copyright (c) 2013 Mason Silber. All rights reserved.
//

#import "LockBoxListViewController.h"
#import "AppDelegate.h"
#import "GCPINViewController.h"
#import "LockboxTableViewCell.h"
#import "SFHFKeychainUtils.h"

#define USERNAME @"DEFAULTUSERNAME"
#define APPSERVICE @"LOCKBOX"

@interface LockBoxListViewController ()

@end

GCPINViewController *lockScreen;
UINavigationController *lockScreenNav;
UIImageView *lockedAccessoryView, *unlockedAccessoryView;

@implementation LockBoxListViewController

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[self lockboxTable] setDelegate:nil];
    [[self lockboxTable] setDataSource:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        NSString *PIN = [self checkIfPINExists];
        if(!PIN) {
            lockScreen = [[GCPINViewController alloc] initWithNibName:nil bundle:nil mode:GCPINViewControllerModeCreate];
            lockScreen.messageText = @"Please set your passcode";
            lockScreen.title = @"Set passcode";
            lockScreen.errorText = @"Passcodes do not match";
            lockScreen.verifyBlock = ^(NSString *code){
                NSLog(@"Code set:%@", code);
                [(AppDelegate *)[[UIApplication sharedApplication] delegate] setAppState:unlocked];
                NSError *error = nil;
                [SFHFKeychainUtils storeUsername:USERNAME andPassword:code forServiceName:APPSERVICE updateExisting:YES error:&error];
                if(error) {
                    NSLog(@"Error saving new password: %@", [error description]);
                }
                return YES;
            };
        }
        else
        {
            lockScreen = [[GCPINViewController alloc] initWithNibName:nil bundle:nil mode:GCPINViewControllerModeVerify];
            [lockScreen setMessageText:@"Please enter your passcode"];
            [lockScreen setTitle:@"Enter passcode"];
            [lockScreen setErrorText:@"Passcode is incorrect"];
            [lockScreen setVerifyBlock:^(NSString *code){
                [(AppDelegate *)[[UIApplication sharedApplication] delegate] setAppState:unlocked];
                return [code isEqualToString:PIN];
            }];
        }
        lockScreenNav = [[UINavigationController alloc] initWithRootViewController:lockScreen];
        
        UIBarButtonItem *addLockbox = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addLockbox:)];
        [[self navigationItem] setRightBarButtonItem:addLockbox];
        UIBarButtonItem *editLockboxes = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStyleBordered target:self action:@selector(editLockboxes:)];
        [[self navigationItem] setLeftBarButtonItem:editLockboxes];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(presentChangePinViewController:) name:@"PresentChangePinViewControllerNotification" object:nil];
    }
    return self;
}

-(void)loadView
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
    [self setView:view];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[self view] setBackgroundColor:[UIColor redColor]];
	// Do any additional setup after loading the view.
    [_lockboxTable registerClass:[LockboxTableViewCell class] forCellReuseIdentifier:@"Cell"];
    
    _lockboxTable = [[UITableView alloc] initWithFrame:[[self view] frame] style:UITableViewStyleGrouped];
    [_lockboxTable setDelegate:self];
    [_lockboxTable setDataSource:self];
    [[self view] addSubview:_lockboxTable];
    
    lockedAccessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"locked.png"]];
    unlockedAccessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"unlocked.png"]];
}

-(NSString *)checkIfPINExists
{
    NSError *error = nil;
    
    NSString *pin = [SFHFKeychainUtils getPasswordForUsername:USERNAME andServiceName:APPSERVICE error:&error];
    if(error)
    {
        return nil;
    }
    return pin;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if([(AppDelegate *)[[UIApplication sharedApplication] delegate] appState] == locked) {
        [lockScreen presentFromViewController:self animated:YES];
    }
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)addLockbox:(id)sender
{
    
}

-(void)editLockboxes:(id)sender
{
   if([[[[self navigationItem] leftBarButtonItem] title] isEqualToString:@"Edit"])
   {
       NSLog(@"Editing");
       [[[self navigationItem] leftBarButtonItem] setTitle:@"Done"];
       [[[self navigationItem] leftBarButtonItem] setStyle:UIBarButtonItemStyleDone];
   }
   else
   {
       NSLog(@"Not Editing");
       [[[self navigationItem] leftBarButtonItem] setTitle:@"Edit"];
       [[[self navigationItem] leftBarButtonItem] setStyle:UIBarButtonItemStyleBordered];
   }
}

-(void)changePIN
{
    GCPINViewController *verifyPin = [[GCPINViewController alloc] initWithNibName:nil bundle:nil mode:GCPINViewControllerModeVerify];
    verifyPin.messageText = @"Please verify current passcode";
    verifyPin.title = @"Enter passcode";
    verifyPin.errorText = @"Passcode is incorrect";
    [verifyPin setIsChangingPIN:YES];
    verifyPin.verifyBlock = ^(NSString *code){
        NSString *PIN = [self checkIfPINExists];
        return [code isEqualToString:PIN];
    };
    
    [verifyPin presentFromViewController:self animated:YES];
}

-(void)presentChangePinViewController:(NSNotification *)notif
{
    GCPINViewController *changePin = [[GCPINViewController alloc] initWithNibName:nil bundle:nil mode:GCPINViewControllerModeCreate];
    changePin.messageText = @"Please set your passcode";
    changePin.title = @"Set passcode";
    changePin.errorText = @"Passcodes do not match";
    changePin.verifyBlock = ^(NSString *code){
        NSLog(@"Code set:%@", code);
        [(AppDelegate *)[[UIApplication sharedApplication] delegate] setAppState:unlocked];
        NSError *error = nil;
        [SFHFKeychainUtils storeUsername:USERNAME andPassword:code forServiceName:APPSERVICE updateExisting:YES error:&error];
        if(error) {
            NSLog(@"Error saving new passcode in keychain: %@", [error description]);
        }
        return YES;
    };
    [changePin presentFromViewController:self animated:YES];
}

#pragma mark - UITableView methods

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(section == 0)
    {
        return [_lockboxes count];
    }
    else return 1;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if(section == 0)
    {
        return @"Lockboxes";
    }
    else return @"";
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    LockboxTableViewCell *cell = (LockboxTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    if(cell == nil)
    {
        cell = [[LockboxTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    
    if([indexPath section] == 0)
    {
        [[cell textLabel] setText:[[_lockboxes objectAtIndex:[indexPath row]] name]];
        if([[_lockboxes objectAtIndex:[indexPath row]] isLocked])
        {
            [cell setAccessoryView:lockedAccessoryView];
        }
        else
        {
            [cell setAccessoryView:unlockedAccessoryView];
        }
    }
    else
    {
        [[cell textLabel] setText:@"Change passcode"];
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [[tableView cellForRowAtIndexPath:indexPath] setSelected:NO];
    if([indexPath section] == 0)
    {
        
    }
    else
    {
        [self changePIN];
    }
}

@end
