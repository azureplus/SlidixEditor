//
//  AppDelegate.m
//  SlidixEditor
//
//  Created by Eduardo on 6/24/15.
//  Copyright (c) 2015 Eduardo. All rights reserved.
//

#import "AppDelegate.h"
#import "BKRCustomNavigationController.h"
#import "BKRCustomNavigationBar.h"
#import "BKRIssuesManager.h"
#import "BKRBakerAPI.h"
#import "UIColor+BakerExtensions.h"
#import "BKRUtils.h"

#import "BKRSettings.h"
#import "BKRBookViewController.h"
#import "BKRAnalyticsEvents.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


+ (void)initialize {
    // Set user agent (the only problem is that we can't modify the User-Agent later in the program)
    // We use a more browser-like User-Agent in order to allow browser detection scripts to run (like Tumult Hype).
    NSDictionary *userAgent = @{@"UserAgent": @"Mozilla/5.0 (compatible; BakerFramework) AppleWebKit/533.00+ (KHTML, like Gecko) Mobile"};
    [[NSUserDefaults standardUserDefaults] registerDefaults:userAgent];
}

- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
    
    //if ([BKRSettings sharedSettings].isNewsstand) {
    //    [self configureNewsstandApp:application options:launchOptions];
    //} else {
        [self configureStandAloneApp:application options:launchOptions];
    //}
    
    self.rootNavigationController = [[BKRCustomNavigationController alloc] initWithRootViewController:self.rootViewController];
    
    [self configureNavigationBar];
    [self configureAnalytics];
    
    self.window = [[BKRInterceptorWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor    = [UIColor whiteColor];
    self.window.rootViewController = self.rootNavigationController;
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)configureNewsstandApp:(UIApplication*)application options:(NSDictionary*)launchOptions {
    
    NSLog(@"====== Baker Newsstand Mode enabled ======");
    [BKRBakerAPI generateUUIDOnce];
    
    // Let the device know we want to handle Newsstand push notifications
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes:(UIRemoteNotificationTypeNewsstandContentAvailability|UIRemoteNotificationTypeBadge|UIRemoteNotificationTypeSound|UIRemoteNotificationTypeAlert) categories:nil];
        [application registerUserNotificationSettings:notificationSettings];
    } else {
        [application registerForRemoteNotificationTypes:(UIRemoteNotificationTypeNewsstandContentAvailability|UIRemoteNotificationTypeBadge|UIRemoteNotificationTypeSound|UIRemoteNotificationTypeAlert)];
    }
    
#ifdef DEBUG
    // For debug only... so that you can download multiple issues per day during development
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"NKDontThrottleNewsstandContentNotifications"];
    [[NSUserDefaults standardUserDefaults] synchronize];
#endif
    
    // Check if the app is runnig in response to a notification
    NSDictionary *payload = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
    if (payload) {
        NSDictionary *aps = payload[@"aps"];
        if (aps && aps[@"content-available"]) {
            
            __block UIBackgroundTaskIdentifier backgroundTask = [application beginBackgroundTaskWithExpirationHandler:^{
                [application endBackgroundTask:backgroundTask];
                backgroundTask = UIBackgroundTaskInvalid;
            }];
            
            // Credit where credit is due. This semaphore solution found here:
            // http://stackoverflow.com/a/4326754/2998
            dispatch_semaphore_t sema = NULL;
            sema = dispatch_semaphore_create(0);
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                [self applicationWillHandleNewsstandNotificationOfContent:payload[@"content-name"]];
                [application endBackgroundTask:backgroundTask];
                backgroundTask = UIBackgroundTaskInvalid;
                dispatch_semaphore_signal(sema);
            });
            
            dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        }
    }
    
    self.rootViewController = [[BKRShelfViewController alloc] init];
    
}

- (void)configureStandAloneApp:(UIApplication*)application options:(NSDictionary*)launchOptions {
    
    NSLog(@"====== Baker Standalone Mode enabled ======");
    NSArray *books = [BKRIssuesManager localBooksList];
    //if (books.count == 1) {
        //BKRBook *book = [books[0] bakerBook];
        //self.rootViewController = [[BKRBookViewController alloc] initWithBook:book];
    //} else  {
        self.rootViewController = [[BKRShelfViewController alloc] initWithBooks:books];
    //}
    
}

- (void)configureNavigationBar {
    BKRCustomNavigationBar *navigationBar = (BKRCustomNavigationBar*)self.rootNavigationController.navigationBar;
    navigationBar.tintColor           = [UIColor bkrColorWithHexString:[BKRSettings sharedSettings].issuesActionBackgroundColor];
    navigationBar.barTintColor        = [UIColor bkrColorWithHexString:@"ffffff"];
    navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor bkrColorWithHexString:@"000000"]};
    [navigationBar setBackgroundImage:[UIImage imageNamed:@"navigation-bar-bg"] forBarMetrics:UIBarMetricsDefault];
}

- (void)configureAnalytics {
    [BKRAnalyticsEvents sharedInstance]; // Initialization
    [[NSNotificationCenter defaultCenter] postNotificationName:@"BakerApplicationStart" object:self]; // -> Baker Analytics Event
}

#pragma mark - Push Notifications

- (void)application:(UIApplication*)application didRegisterUserNotificationSettings:(UIUserNotificationSettings*)notificationSettings {
    [application registerForRemoteNotifications];
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error {
    NSLog(@"[AppDelegate] Push Notification - Device Token, review: %@", error);
}

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken {
    
    if (![BKRSettings sharedSettings].isNewsstand) {
        return;
    }
    
    NSString *apnsToken = [[deviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    apnsToken = [apnsToken stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    NSLog(@"[AppDelegate] My token (as NSData) is: %@", deviceToken);
    NSLog(@"[AppDelegate] My token (as NSString) is: %@", apnsToken);
    
    [[NSUserDefaults standardUserDefaults] setObject:apnsToken forKey:@"apns_token"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    BKRBakerAPI *api = [BKRBakerAPI sharedInstance];
    [api postAPNSToken:apnsToken];
    
}

- (void)application:(UIApplication*)application didReceiveRemoteNotification:(NSDictionary*)userInfo {
    
    if (![BKRSettings sharedSettings].isNewsstand) {
        return;
    }
    
    NSDictionary *aps = userInfo[@"aps"];
    if (aps && aps[@"content-available"]) {
        [self applicationWillHandleNewsstandNotificationOfContent:userInfo[@"content-name"]];
    }
    
}

/*
 - (void)application:(UIApplication*)application didReceiveRemoteNotification:(NSDictionary*)userInfo fetchCompletionHandler:(void(^)(UIBackgroundFetchResult result))handler {
 
 if (![BKRSettings sharedSettings].isNewsstand) {
 return;
 }
 
 NSDictionary *aps = userInfo[@"aps"];
 if (aps && aps[@"content-available"]) {
 [self applicationWillHandleNewsstandNotificationOfContent:userInfo[@"content-name"]];
 }
 
 }
 */

- (void)applicationWillHandleNewsstandNotificationOfContent:(NSString*)contentName {
    
    if (![BKRSettings sharedSettings].isNewsstand) {
        return;
    }
    
    BKRIssuesManager *issuesManager = [BKRIssuesManager sharedInstance];
    BKRPurchasesManager *purchasesManager = [BKRPurchasesManager sharedInstance];
    __block BKRIssue *targetIssue = nil;
    
    [issuesManager refresh:^(BOOL status) {
        if (contentName) {
            for (BKRIssue *issue in issuesManager.issues) {
                if ([issue.ID isEqualToString:contentName]) {
                    targetIssue = issue;
                    break;
                }
            }
        } else {
            targetIssue = (issuesManager.issues)[0];
        }
        
        [purchasesManager retrievePurchasesFor:issuesManager.productIDs withCallback:^(NSDictionary *_purchases) {
            
            NSString *targetStatus = [targetIssue getStatus];
            NSLog(@"[AppDelegate] Push Notification - Target status: %@", targetStatus);
            
            if ([targetStatus isEqualToString:@"remote"] || [targetStatus isEqualToString:@"purchased"]) {
                [targetIssue download];
            } else if ([targetStatus isEqualToString:@"purchasable"] || [targetStatus isEqualToString:@"unpriced"]) {
                NSLog(@"[AppDelegate] Push Notification - You are not entitled to download issue '%@', issue not purchased yet", targetIssue.ID);
            } else if (![targetStatus isEqualToString:@"remote"]) {
                NSLog(@"[AppDelegate] Push Notification - Issue '%@' in download or already downloaded", targetIssue.ID);
            }
        }];
    }];
    
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "mmc.SlidixEditor" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"SlidixEditor" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"SlidixEditor.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}


- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

@end
