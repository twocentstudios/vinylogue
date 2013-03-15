//
//  TCSAppDelegate.m
//  vinylogue
//
//  Created by Christopher Trott on 2/17/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import "TCSAppDelegate.h"

#import <FlurrySDK/Flurry.h>
#import <TestFlightSDK/TestFlight.h>
#import <Crashlytics/Crashlytics.h>

#import "TCSVinylogueSecret.h"
#import <AFNetworking/AFNetworking.h>
#import <SDURLCache/SDURLCache.h>

#import "TCSWeeklyAlbumChartViewController.h"
#import "TCSFavoriteUsersViewController.h"

#import "TCSUserStore.h"

@implementation TCSAppDelegate

# pragma mark - private

- (void)quicktest{

}

- (void)configureApplicationStyle{
  
  // STATUS BAR
  //  [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque];
  
  // NAVIGATION BAR
  [[UINavigationBar appearance]
   setBackgroundImage:[[UIImage imageNamed:@"navBarPatch"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)]
   forBarMetrics:UIBarMetricsDefault];
  NSDictionary *navBarTextAttributes = @{ UITextAttributeFont: FONT_AVN_REGULAR(20),
                                          UITextAttributeTextColor: BLUE_DARK,
                                          UITextAttributeTextShadowColor: CLEAR,
                                          UITextAttributeTextShadowOffset: [NSValue valueWithUIOffset:UIOffsetMake(0, 0)] };
  [[UINavigationBar appearance] setTitleTextAttributes:navBarTextAttributes];
  
  // UIBARBUTTONITEM
  NSDictionary *barButtonItemTextAttributes = @{ UITextAttributeFont: FONT_AVN_DEMIBOLD(12),
                                                 UITextAttributeTextColor: WHITE,
                                                 UITextAttributeTextShadowColor: GRAYCOLOR(140),
                                                 UITextAttributeTextShadowOffset: [NSValue valueWithUIOffset:UIOffsetMake(0, -1)] };
  [[UIBarButtonItem appearance] setTitleTextAttributes:barButtonItemTextAttributes forState:UIControlStateNormal];
  [[UIBarButtonItem appearance] setTitlePositionAdjustment:UIOffsetMake(1, 1) forBarMetrics:UIBarMetricsDefault];
  [[UIBarButtonItem appearance] setTintColor:BAR_BUTTON_TINT];
}

# pragma mark - App Delegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions{
  
#ifdef BETATESTING
  [TestFlight takeOff:kTestFlightAPIKey];
#elsif APPSTORE
  [Flurry startSession:kFlurryAPIKey];
#endif

#if defined(BETATESTING) || defined(APPSTORE)
  [Crashlytics startWithAPIKey:kCrashlyticsAPIKey];
#endif
  
  SDURLCache *URLCache = [[SDURLCache alloc] initWithMemoryCapacity:20 * 1024 * 1024 diskCapacity:50 * 1024 * 1024 diskPath:[SDURLCache defaultCachePath]];
  [SDURLCache setSharedURLCache:URLCache];
  
  [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
  
  [self configureApplicationStyle];
  
  // Keep track of versions in case we need to do migrations in the future
  if ([[NSUserDefaults standardUserDefaults] boolForKey:@"init_1_0_0"] == NO) {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"init_1_0_0"];
    [[NSUserDefaults standardUserDefaults] synchronize];
  }
  
  NSNumber *storedPlayCountFilter = [[NSUserDefaults standardUserDefaults] objectForKey:kTCSUserDefaultsPlayCountFilter];
  
  if (storedPlayCountFilter == nil){
    storedPlayCountFilter = [NSNumber numberWithUnsignedInteger:0];
    [[NSUserDefaults standardUserDefaults] setObject:storedPlayCountFilter forKey:kTCSUserDefaultsPlayCountFilter];
    [[NSUserDefaults standardUserDefaults] synchronize];
  }
  
  TCSUserStore *userStore = [[TCSUserStore alloc] init];
  
  TCSFavoriteUsersViewController *favoriteUsersController = [[TCSFavoriteUsersViewController alloc] initWithUserStore:userStore playCountFilter:[storedPlayCountFilter unsignedIntegerValue]];
  UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:favoriteUsersController];

  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  self.window.rootViewController = navigationController;
  self.window.backgroundColor = [UIColor whiteColor];
  [self.window makeKeyAndVisible];
  
//  [self quicktest];
    
  return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application{
  // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
  // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application{
  // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
  // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application{
  // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application{
  // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application{

}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
  [[NSURLCache sharedURLCache] removeAllCachedResponses];
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory{
  return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
