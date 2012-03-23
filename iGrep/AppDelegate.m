//
//  AppDelegate.m
//  Autocomplete
//
//  Created by Владимир Гричина on 02.03.12.
//  Copyright (c) 2012 Vladimir Grichina. All rights reserved.
//

#import "AppDelegate.h"

#import "ViewController.h"

#import <sqlite3.h>

@implementation AppDelegate

@synthesize window, viewController, navController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    sqlite3_config(SQLITE_CONFIG_SERIALIZED);

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.viewController = [[ViewController alloc] initWithNibName:@"ViewController" bundle:nil];

    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:self.viewController];
	self.navController = navigationController;

    self.window.rootViewController = self.navController;
    [self.window makeKeyAndVisible];

    return YES;
}

@end
