//
//  AppDelegate.h
//  SlidixEditor
//
//  Created by Eduardo on 6/24/15.
//  Copyright (c) 2015 Eduardo. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "BKRInterceptorWindow.h"
#import "BKRShelfViewController.h"


#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate, NSFileManagerDelegate>

//@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong) BKRInterceptorWindow *window;
@property (nonatomic, strong) UIViewController *rootViewController;
@property (nonatomic, strong) UINavigationController *rootNavigationController;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;


@end

