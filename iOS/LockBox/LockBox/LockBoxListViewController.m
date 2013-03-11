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
#import "AddLockboxViewController.h"
#import "LockBox.h"
#import "AFNetworking.h"

@interface LockBoxListViewController ()
-(void)lockLockbox:(LockBox *)lockbox withSuccessBlock:(void (^)())success andFailureBlock:(void(^)())failure andIndexPath:(NSIndexPath *)indexPath;
-(void)unlockLockbox:(LockBox *)lockbox withSuccessBlock:(void (^)())success andFailureBlock:(void (^)())failure andIndexPath: (NSIndexPath *)indexPath;

@end

GCPINViewController *lockScreen;
UINavigationController *lockScreenNav;
UIImageView *lockedAccessoryView, *unlockedAccessoryView;

@implementation LockBoxListViewController

-(void)dealloc
{
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
	// Do any additional setup after loading the view.
    [_lockboxTable registerClass:[LockboxTableViewCell class] forCellReuseIdentifier:@"Cell"];
    
    _lockboxTable = [[UITableView alloc] initWithFrame:[[self view] frame] style:UITableViewStyleGrouped];
    [_lockboxTable setDelegate:self];
    [_lockboxTable setDataSource:self];
    [_lockboxTable setBackgroundView:nil];
    [_lockboxTable setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
    [[self view] addSubview:_lockboxTable];
    
    lockedAccessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"locked.png"]];
    unlockedAccessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"unlocked.png"]];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self loadLockboxes];
    });
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
    AddLockboxViewController *addLockbox = [[AddLockboxViewController alloc] init];
    [addLockbox setDelegate:self];
    [addLockbox setTitle:@"Add Lockbox"];
    [[self navigationController] pushViewController:addLockbox animated:YES];
}

-(void)editLockboxes:(id)sender
{
    if([[[[self navigationItem] leftBarButtonItem] title] isEqualToString:@"Edit"])
    {
        NSLog(@"Editing");
        [[[self navigationItem] leftBarButtonItem] setTitle:@"Done"];
        [[[self navigationItem] leftBarButtonItem] setStyle:UIBarButtonItemStyleDone];
        [_lockboxTable setEditing:YES animated:YES];
    }
    else
    {
        NSLog(@"Not Editing");
        [[[self navigationItem] leftBarButtonItem] setTitle:@"Edit"];
        [[[self navigationItem] leftBarButtonItem] setStyle:UIBarButtonItemStyleBordered];
        [_lockboxTable setEditing:NO animated:YES];
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

-(BOOL)saveNewLockboxWithName:(NSString *)name andIPAddress:(NSString *)IPAddress
{
    NSLog(@"Delegate called");
    LockBox *newLockbox = [[LockBox alloc] initWithEntity:[NSEntityDescription entityForName:@"LockBox" inManagedObjectContext:[(AppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext]] insertIntoManagedObjectContext:[(AppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext]];
    [newLockbox setName:name];
    [newLockbox setIpAddress:IPAddress];
    [newLockbox setIsLocked:@1];
    NSManagedObjectContext *context = [newLockbox managedObjectContext];
    
    NSError *error = nil;
    
    if(![context save:&error])
    {
        NSLog(@"Error saving new lockbox: %@", [error description]);
        UIAlertView *errorSavingAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Error saving your new lockbox. Please try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [errorSavingAlert show];
        return NO;
    }
    else
    {
        return YES;
    }
}

-(void)loadLockboxes
{
    NSManagedObjectContext *managedObjectContext = [(AppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"LockBox" inManagedObjectContext:managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:entityDescription];
    
    NSError *error = nil;
    NSArray *temp = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    if(error)
    {
        NSLog(@"Error fetching lockboxes: %@", [error description]);
    }
    else
    {
        _lockboxes = [[NSMutableArray alloc] initWithArray:temp];
        dispatch_async(dispatch_get_main_queue(), ^{
            [_lockboxTable reloadData];
        });
    }
}

-(void)lockLockbox:(LockBox *)lockbox withSuccessBlock:(void (^)())success andFailureBlock:(void(^)())failure andIndexPath:(NSIndexPath *)indexPath
{
    //    NSURL *lockboxURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/lock", [lockbox ipAddress], [lockbox name]]];
    NSURL *lockboxURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/$1", [lockbox ipAddress]]];
    NSURLRequest *lockboxRequest = [NSURLRequest requestWithURL:lockboxURL];
    
    //Handles putting networking in the background
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:lockboxRequest
                                                                                        success:^(NSURLRequest *request, NSURLResponse *response, id JSON){
                                                                                            [[_lockboxTable cellForRowAtIndexPath:indexPath] setAccessoryView:lockedAccessoryView];
                                                                                            if(success != 0)
                                                                                                success();
                                                                                        }
                                                                                        failure:^(NSURLRequest *request, NSURLResponse *response, NSError *error, id JSON){
                                                                                            NSLog(@"Error locking lockbox: %@", [error description]);
                                                                                            if(failure != 0)
                                                                                                failure();
                                                                                        }];
    [operation start];
}

-(void)unlockLockbox:(LockBox *)lockbox withSuccessBlock:(void (^)())success andFailureBlock:(void (^)())failure andIndexPath:(NSIndexPath *)indexPath
{
    //    NSURL *lockboxURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/lock", [lockbox ipAddress], [lockbox name]]];
    NSURL *lockboxURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/$2", [lockbox ipAddress]]];
    NSURLRequest *lockboxRequest = [NSURLRequest requestWithURL:lockboxURL];
    
    //Handles putting networking in the background
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:lockboxRequest
                                                                                        success:^(NSURLRequest *request, NSURLResponse *response, id JSON){
                                                                                            [[_lockboxTable cellForRowAtIndexPath:indexPath] setAccessoryView:unlockedAccessoryView];
                                                                                            if(success != 0)
                                                                                                success();
                                                                                        }
                                                                                        failure:^(NSURLRequest *request, NSURLResponse *response, NSError *error, id JSON){
                                                                                            NSLog(@"Error unlocking lockbox: %@", [error description]);
                                                                                            if(success != 0)
                                                                                                success();
                                                                                        }];
    [operation start];
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
        LockBox *selectedLockbox = [_lockboxes objectAtIndex:[indexPath row]];
        if([[selectedLockbox isLocked] intValue]
           )
        {
            NSLog(@"Unlocking");
            [selectedLockbox setIsLocked:@0];
//            [[_lockboxTable cellForRowAtIndexPath:indexPath] setAccessoryView:unlockedAccessoryView];
            [self unlockLockbox:selectedLockbox withSuccessBlock:0 andFailureBlock:0 andIndexPath:indexPath];
        }
        else
        {
            NSLog(@"Locking");
            [selectedLockbox setIsLocked:@1];
//            [[_lockboxTable cellForRowAtIndexPath:indexPath] setAccessoryView:lockedAccessoryView];
            [self lockLockbox:selectedLockbox withSuccessBlock:0 andFailureBlock:0 andIndexPath:indexPath];
        }
    }
    else
    {
        [self changePIN];
    }
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([tableView isEditing])
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

@end
