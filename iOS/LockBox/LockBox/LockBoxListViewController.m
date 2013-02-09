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

@interface LockBoxListViewController ()

@end

GCPINViewController *lockScreen;
UINavigationController *lockScreenNav;

@implementation LockBoxListViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        lockScreen = [[GCPINViewController alloc] initWithNibName:nil bundle:nil mode:GCPINViewControllerModeCreate];
        lockScreen.messageText = @"Please set your passcode";
        lockScreen.title = @"Set passcode";
        lockScreen.errorText = @"Passcodes do not match";
        lockScreen.verifyBlock = ^(NSString *code){
            NSLog(@"Code set:%@", code);
            [(AppDelegate *)[[UIApplication sharedApplication] delegate] setAppState:unlocked];
            return YES;
        };
        lockScreenNav = [[UINavigationController alloc] initWithRootViewController:lockScreen];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[self view] setBackgroundColor:[UIColor redColor]];
	// Do any additional setup after loading the view.
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

@end
