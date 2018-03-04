//
//  TCSAppDelegate.m
//  vinylogue
//
//  Created by Christopher Trott on 2/17/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import "TCSAppDelegate.h"

#import "TCSVinylogueSecret.h"
#import <AFNetworking/AFNetworking.h>
#import <SDURLCache/SDURLCache.h>

#import "TCSWeeklyAlbumChartViewController.h"
#import "TCSFavoriteUsersViewController.h"

#import "TCSUserStore.h"

// For Debugging
#import <mach/mach.h>
#import <mach/mach_host.h>
#import "TargetConditionals.h"

@implementation TCSAppDelegate

# pragma mark - private

- (void)quicktest{

}

- (void)configureApplicationStyle{
  
  // STATUS BAR
  [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
  
  self.window.tintColor = BLUE_DARK;

  NSDictionary *navBarTextAttributes = @{ NSFontAttributeName: FONT_AVN_REGULAR(20),
                                          NSForegroundColorAttributeName: BLUE_DARK, };
  [[UINavigationBar appearance] setTitleTextAttributes:navBarTextAttributes];
  
  [[UINavigationBar appearance] setBarTintColor:WHITE_SUBTLE];
}

# pragma mark - App Delegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions{
  
  SDURLCache *URLCache = [[SDURLCache alloc] initWithMemoryCapacity:20 * 1024 * 1024 diskCapacity:50 * 1024 * 1024 diskPath:[SDURLCache defaultCachePath]];
  [SDURLCache setSharedURLCache:URLCache];
  
  [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
  
  // Keep track of versions in case we need to do migrations in the future
  if ([[NSUserDefaults standardUserDefaults] boolForKey:@"init_1_2_0"] == NO) {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"init_1_2_0"];
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
  
  [self configureApplicationStyle];

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


#pragma mark - debug

#ifdef DEBUG

NSString *print_free_memory(){
  mach_port_t host_port;
  mach_msg_type_number_t host_size;
  vm_size_t pagesize;
  
  host_port = mach_host_self();
  host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
  host_page_size(host_port, &pagesize);
  
  vm_statistics_data_t vm_stat;
  
  if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) != KERN_SUCCESS)
    NSLog(@"Failed to fetch vm statistics");
  
  /* Stats in bytes */
  natural_t mem_used = (vm_stat.active_count +
                        vm_stat.inactive_count +
                        vm_stat.wire_count) * pagesize;
  natural_t mem_free = vm_stat.free_count * pagesize;
  natural_t mem_total = mem_used + mem_free;
  natural_t megabyte = 1048576;
  return [NSString stringWithFormat:@"used: %f free: %f total: %f", (double)mem_used/(double)megabyte, (double)mem_free/(double)megabyte, (double)mem_total/(double)megabyte];
}

#endif

@end
