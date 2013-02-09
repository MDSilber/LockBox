//
//  AppDelegate.h
//  LockBox
//
//  Created by Mason Silber on 2/5/13.
//  Copyright (c) 2013 Mason Silber. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

enum state{
    locked = 0,
    unlocked = 1
};

@property (nonatomic) enum state appState;

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, nonatomic, strong) UINavigationController *nav;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@end
