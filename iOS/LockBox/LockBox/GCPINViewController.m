//
//  GCPINViewController.m
//  PINCode
//
//  Created by Caleb Davenport on 8/28/10.
//  Copyright 2010 GUI Cocoa, LLC. All rights reserved.
//

#import "GCPINViewController.h"
#import "SFHFKeychainUtils.h"
#import "AppDelegate.h"

#define kGCPINViewControllerDelay 0.3

@interface GCPINViewController ()

// array of passcode entry labels
@property (copy, nonatomic) NSArray *labels;

// readwrite override for mode
@property (nonatomic, readwrite, assign) GCPINViewControllerMode mode;

// extra storage used when creating a passcode
@property (copy, nonatomic) NSString *text;

// make the passcode entry labels match the input text
- (void)updatePasscodeDisplay;

// reset user input after a set delay
- (void)resetInput;

// signal that the passcode is incorrect
- (void)wrong;

// dismiss the view after a set delay
- (void)dismiss;

@end

@implementation GCPINViewController

@synthesize fieldOneLabel = __fieldOneLabel;
@synthesize fieldTwoLabel = __fieldTwoLabel;
@synthesize fieldThreeLabel = __fieldThreeLabel;
@synthesize fieldFourLabel = __fieldFourLabel;
@synthesize messageLabel = __messageLabel;
@synthesize errorLabel = __errorLabel;
@synthesize inputField = __inputField;
@synthesize messageText = __messageText;
@synthesize errorText = __errorText;
@synthesize labels = __labels;
@synthesize mode = __mode;
@synthesize text = __text;
@synthesize verifyBlock = __verifyBlock;

#pragma mark - object methods
- (id)initWithNibName:(NSString *)nib bundle:(NSBundle *)bundle mode:(GCPINViewControllerMode)mode {
    NSAssert(mode == GCPINViewControllerModeCreate ||
             mode == GCPINViewControllerModeVerify,
             @"Invalid passcode mode");
	if (self = [super initWithNibName:nib bundle:bundle]) {
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(textDidChange:)
         name:UITextFieldTextDidChangeNotification
         object:nil];
        self.mode = mode;
        __dismiss = NO;
        [self setIsChangingPIN:NO];
	}
	return self;
}
- (void)dealloc {
    
    // clear notifs
	[[NSNotificationCenter defaultCenter]
     removeObserver:self
     name:UITextFieldTextDidChangeNotification
     object:nil];
    
    // clear properties
    self.fieldOneLabel = nil;
    self.fieldTwoLabel = nil;
    self.fieldThreeLabel = nil;
    self.fieldFourLabel = nil;
    self.messageLabel = nil;
    self.errorLabel = nil;
    self.inputField = nil;
    self.messageText = nil;
    self.errorText = nil;
    self.labels = nil;
    self.text = nil;
    self.verifyBlock = nil;
	
    // super
    
}
- (void)presentFromViewController:(UIViewController *)controller animated:(BOOL)animated {
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self];
	[controller presentViewController:navController animated:animated completion:0];
}
- (void)updatePasscodeDisplay {
    NSUInteger length = [self.inputField.text length];
    for (NSUInteger i = 0; i < 4; i++) {
        UILabel *label = [self.labels objectAtIndex:i];
        label.text = (i < length) ? @"●" : @"";
    }
}
- (void)resetInput {
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, kGCPINViewControllerDelay * NSEC_PER_SEC);
    dispatch_after(time, dispatch_get_main_queue(), ^(void){
        self.inputField.text = @"";
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
    });
}
- (void)wrong {
    self.errorLabel.hidden = NO;
    self.text = nil;
    [self resetInput];
}
- (void)dismiss {
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    __dismiss = YES;
    
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, kGCPINViewControllerDelay * NSEC_PER_SEC);
    dispatch_after(time, dispatch_get_main_queue(), ^(void){
        [self dismissViewControllerAnimated:YES completion:0];
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
    });
}

#pragma mark - view lifecycle
- (void)viewDidLoad {
	[super viewDidLoad];
    
    // setup labels list
    self.labels = [NSArray arrayWithObjects:
                   self.fieldOneLabel,
                   self.fieldTwoLabel,
                   self.fieldThreeLabel,
                   self.fieldFourLabel,
                   nil];
    
    // setup labels
    self.messageLabel.text = self.messageText;
    self.errorLabel.text = self.errorText;
    self.errorLabel.hidden = YES;
	[self updatePasscodeDisplay];
    
	// setup input field
    self.inputField.hidden = YES;
    self.inputField.keyboardType = UIKeyboardTypeNumberPad;
    self.inputField.delegate = self;
    self.inputField.secureTextEntry = YES;
    self.inputField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.inputField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    [self.inputField becomeFirstResponder];
	
}
- (void)viewDidUnload {
	[super viewDidUnload];
	self.fieldOneLabel = nil;
    self.fieldTwoLabel = nil;
    self.fieldThreeLabel = nil;
    self.fieldFourLabel = nil;
    self.messageLabel = nil;
    self.errorLabel = nil;
    self.inputField = nil;
    self.labels = nil;
    self.text = nil;
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return UIInterfaceOrientationIsLandscape(orientation);
    }
    else {
        return (orientation == UIInterfaceOrientationPortrait);
    }
}

#pragma mark - overridden property accessors
- (void)setMessageText:(NSString *)text {
    __messageText = [text copy];
    self.messageLabel.text = __messageText;
}
- (void)setErrorText:(NSString *)text {
    __errorText = [text copy];
    self.errorLabel.text = __errorText;
}

#pragma mark - text field methods
- (void)textDidChange:(NSNotification *)notif {
    if ([notif object] == self.inputField) {
        NSAssert(self.verifyBlock, @"No passcode verify block is set");
        [self updatePasscodeDisplay];
        if ([self.inputField.text length] == 4) {
            //Changing pin
            if (self.mode == GCPINViewControllerModeCreate) {
                if (self.text == nil) {
                    self.text = self.inputField.text;
                    //Clear password
                    [self setMessageText:@"Please re-enter password"];
                    [self clearTextBoxes];
                    [self resetInput];
                }
                else {
                    if ([self.text isEqualToString:self.inputField.text] &&
                        self.verifyBlock(self.inputField.text)) {
                        [self dismiss];
                    }
                    else {
                        [self setMessageText:@"Please set your passcode"];
                        [self clearTextBoxes];
                        [self wrong];
                    }
                }
            }
            //Verifying pin
            else if (self.mode == GCPINViewControllerModeVerify) {
                if (self.verifyBlock(self.inputField.text)) {
                    if([self isChangingPIN])
                    {
                        [self setIsChangingPIN:NO];
                        [self setMode:GCPINViewControllerModeCreate];
                        self.messageText = @"Please set your passcode";
                        self.title = @"Set passcode";
                        self.errorText = @"Passcodes do not match";
                        self.verifyBlock = ^(NSString *code){
                            NSLog(@"Code set:%@", code);
                            [(AppDelegate *)[[UIApplication sharedApplication] delegate] setAppState:unlocked];
                            NSError *error = nil;
                            [SFHFKeychainUtils storeUsername:USERNAME andPassword:code forServiceName:APPSERVICE updateExisting:YES error:&error];
                            if(error) {
                                NSLog(@"Error saving new passcode in keychain: %@", [error description]);
                            }
                            return YES;
                        };
                        [self clearTextBoxes];
                        [self resetInput];
                        return;
                    }
                    else
                    {
                        [self dismiss];
                    }
                }
                else {
                    [self clearTextBoxes];
                    [self wrong];
                }
            }
        }
    }
}
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if ([textField.text length] == 4 && [string length] > 0) {
        return NO;
    }
    else {
        self.errorLabel.hidden = YES;
        return YES;
    }
}
- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    return __dismiss;
}

-(void)clearTextBoxes
{
    for (NSUInteger i = 0; i < 4; i++) {
        UILabel *label = [self.labels objectAtIndex:i];
        label.text = @"";
    }
}
@end
