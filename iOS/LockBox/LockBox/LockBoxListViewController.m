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

@property (nonatomic, strong) GCPINViewController *lockScreen;
@property (nonatomic, strong) UINavigationController *lockScreenNav;

-(void)lockLockbox:(LockBox *)lockbox withSuccessBlock:(void (^)())success andFailureBlock:(void(^)())failure andIndexPath:(NSIndexPath *)indexPath;
-(void)unlockLockbox:(LockBox *)lockbox withSuccessBlock:(void (^)())success andFailureBlock:(void (^)())failure andIndexPath: (NSIndexPath *)indexPath;

@end

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

@implementation LockBoxListViewController

-(void)dealloc
{
    [[self lockboxTable] setDelegate:nil];
    [[self lockboxTable] setDataSource:nil];
}

#pragma mark - View lifecycle methods
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        NSString *PIN = [self checkIfPINExists];
        if(!PIN) {
            _lockScreen = [[GCPINViewController alloc] initWithNibName:nil bundle:nil mode:GCPINViewControllerModeCreate];
            _lockScreen.messageText = @"Please set your passcode";
            _lockScreen.title = @"Set passcode";
            _lockScreen.errorText = @"Passcodes do not match";
            _lockScreen.verifyBlock = ^(NSString *code){
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
            _lockScreen = [[GCPINViewController alloc] initWithNibName:nil bundle:nil mode:GCPINViewControllerModeVerify];
            [_lockScreen setMessageText:@"Please enter your passcode"];
            [_lockScreen setTitle:@"Enter passcode"];
            [_lockScreen setErrorText:@"Passcode is incorrect"];
            [_lockScreen setVerifyBlock:^(NSString *code){
                [(AppDelegate *)[[UIApplication sharedApplication] delegate] setAppState:unlocked];
                return [code isEqualToString:PIN];
            }];
        }
        _lockScreenNav = [[UINavigationController alloc] initWithRootViewController:_lockScreen];
    }
    return self;
}

-(void)loadView
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
    [self setView:view];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
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
    [_lockboxTable setAllowsSelectionDuringEditing:YES];
    
    [[self view] addSubview:_lockboxTable];
    
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self loadLockboxes];
//    });
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if([(AppDelegate *)[[UIApplication sharedApplication] delegate] appState] == locked) {
        [_lockScreen presentFromViewController:self animated:YES];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Lockbox methods

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

-(void)addLockbox:(id)sender
{
    AddLockboxViewController *addLockbox = [[AddLockboxViewController alloc] initWithNibName:nil bundle:nil];
    [addLockbox setDelegate:self];
    [addLockbox setTitle:@"Add Lockbox"];
    [[self navigationController] pushViewController:addLockbox animated:YES];
}

-(void)editLockboxes:(id)sender
{
    if([_lockboxes count] == 0)
    {
        return;
    }
    else
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
        
        [_lockboxTable reloadData];
        UIBarButtonItem *addLockbox = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addLockbox:)];
        [[self navigationItem] setRightBarButtonItem:addLockbox];
        UIBarButtonItem *editLockboxes = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStyleBordered target:self action:@selector(editLockboxes:)];
        [[self navigationItem] setLeftBarButtonItem:editLockboxes];
        if([_lockboxes count] == 0)
        {
            [editLockboxes setEnabled:NO];
        }
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
                                                                                            [[_lockboxTable cellForRowAtIndexPath:indexPath] setAccessoryView:[self newLockedImageView]];
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
                                                                                            [[_lockboxTable cellForRowAtIndexPath:indexPath] setAccessoryView:[self newUnlockedImageView]];
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

#pragma mark - AddLockboxViewControllerDelegate methods

-(BOOL)saveNewLockboxWithName:(NSString *)name andIPAddress:(NSString *)IPAddress
{
    NSLog(@"Delegate called");
    NSManagedObjectContext *context = [(AppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
    LockBox *newLockbox = [[LockBox alloc] initWithEntity:[NSEntityDescription entityForName:@"LockBox" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
    [newLockbox setName:name];
    [newLockbox setIpAddress:IPAddress];
    [newLockbox setIsLocked:@1];
    
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
        [_lockboxes addObject:newLockbox];
        [[[self navigationItem] leftBarButtonItem] setEnabled:YES];
        [_lockboxTable reloadData];
        return YES;
    }
}

-(BOOL)saveEditedLockbox:(LockBox *)lockbox withNewName:(NSString *)name andIPAddress:(NSString *)IPAddress;
{
    [_lockboxTable setEditing:NO animated:YES];
    [[[self navigationItem] leftBarButtonItem] setTitle:@"Edit"];
    [[[self navigationItem] leftBarButtonItem] setStyle:UIBarButtonItemStyleBordered];
    NSManagedObjectContext *context = [lockbox managedObjectContext];
    
    [lockbox setName:name];
    [lockbox setIpAddress:IPAddress];
    
    NSError *error = nil;
    if(![context save:&error])
    {
        NSLog(@"Error editing new lockbox: %@", [error description]);
        UIAlertView *errorEditingAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Error editing your lockbox information. Please try again." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [errorEditingAlert show];
        return NO;
    }
    else
    {
        [_lockboxTable reloadData];
        return YES;
    }
}

- (UIImageView *)newLockedImageView
{
    return [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"locked.png"]];
}

- (UIImageView *)newUnlockedImageView
{
    return [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"unlocked.png"]];
}

#pragma mark - UITableViewDelegate and UITableViewDataSource methods

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
            [cell setAccessoryView:[self newLockedImageView]];
        }
        else
        {
            [cell setAccessoryView:[self newUnlockedImageView]];
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
    //Not in editing mode
    if(![tableView isEditing])
    {
        //Lock or unlock lockbox
        if([indexPath section] == 0)
        {
            LockBox *selectedLockbox = [_lockboxes objectAtIndex:[indexPath row]];
            if([[selectedLockbox isLocked] intValue]
               )
            {
                NSLog(@"Unlocking");
                [selectedLockbox setIsLocked:@0];
                [self unlockLockbox:selectedLockbox withSuccessBlock:0 andFailureBlock:0 andIndexPath:indexPath];
            }
            else
            {
                NSLog(@"Locking");
                [selectedLockbox setIsLocked:@1];
                [self lockLockbox:selectedLockbox withSuccessBlock:0 andFailureBlock:0 andIndexPath:indexPath];
            }
        }
        //Change pin
        else
        {
            [self changePIN];
        }
    }
    //In editing mode
    else
    {
        //Edit a lockbox
        if([indexPath section] == 0)
        {
            LockBox *selectedLockbox = [_lockboxes objectAtIndex:[indexPath row]];
            AddLockboxViewController *editLockboxViewController = [[AddLockboxViewController alloc] initWithLockbox:selectedLockbox];
            [editLockboxViewController setDelegate:self];
            [editLockboxViewController setTitle:@"Edit Lockbox"];
            [[self navigationController] pushViewController:editLockboxViewController animated:YES];
        }
    }
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([indexPath section] == 0 && [tableView isEditing])
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView beginUpdates];

    if(editingStyle == UITableViewCellEditingStyleDelete)
    {
        //Update core data
        NSManagedObjectContext *managedObjectContext = [(AppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
        LockBox *lockboxToDelete = [_lockboxes objectAtIndex:[indexPath row]];
        [managedObjectContext deleteObject:lockboxToDelete];
        NSError *error = nil;
        
        if(![managedObjectContext save:&error])
        {
            UIAlertView *deleteErrorAlert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                       message:@"Error deleting lockbox. Please try again."
                                                                      delegate:nil
                                                             cancelButtonTitle:@"OK"
                                                             otherButtonTitles:nil, nil];
            [deleteErrorAlert show];
            return;
        }
        
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        [tableView setEditing:NO animated:NO];
        
        //Update data source
        [_lockboxes removeObjectAtIndex:[indexPath row]];
        
        if([_lockboxes count] == 0)
        {
            [[[self navigationItem] leftBarButtonItem] setTitle:@"Edit"];
            [[[self navigationItem] leftBarButtonItem] setEnabled:NO];
            [[[self navigationItem] leftBarButtonItem] setStyle:UIBarButtonItemStyleBordered];
        }
    }
    [tableView endUpdates];
}

-(BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([indexPath section] == 0 && [_lockboxes count] > 1)
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

-(void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    //Do not allow movement between sections
    if([sourceIndexPath section] != [destinationIndexPath section])
    {
        return;
        
    }
    
    LockBox *movingLockbox = [_lockboxes objectAtIndex:[sourceIndexPath row]];
    [_lockboxes removeObject:movingLockbox];
    [_lockboxes insertObject:movingLockbox atIndex:[destinationIndexPath row]];
}

@end
