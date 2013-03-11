//
//  TCSFriendsListStore.m
//  vinylogue
//
//  Created by Christopher Trott on 2/22/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import "TCSUserStore.h"
#import "User.h"

@interface TCSUserStore ()

@property (nonatomic, strong) User *user;
@property (nonatomic, strong) NSMutableArray *friendsList;

@end

@implementation TCSUserStore

- (id)init{
  self = [super init];
  if (self) {
    [self load];
  }
  return self;
}

- (void)setUserName:(NSString *)userName{
  if (_user.userName != userName){
    self.user = [[User alloc] initWithUserName:userName];
    [self save];
  }
}

- (NSInteger)friendsCount{
  return [self.friendsList count];
}

- (User *)friendAtIndex:(NSUInteger)index{
  if (index < [self friendsCount]){
    return [self.friendsList objectAtIndex:index];
  }
  return nil;
}

- (void)addFriendWithUserName:(NSString *)userName{
  if (userName != nil) {
    [self.friendsList addObject:[[User alloc] initWithUserName:userName]];
    [self save];
  }
}

- (void)removeFriendAtIndex:(NSUInteger)index{
  if (index < [self friendsCount]){
    [self.friendsList removeObjectAtIndex:index];
    [self save];
  }
}

- (void)replaceFriendAtIndex:(NSUInteger)index withUserName:(NSString *)userName{
  if (index < [self friendsCount]){
    [self.friendsList replaceObjectAtIndex:index withObject:[[User alloc] initWithUserName:userName]];
    [self save];
  }
}

- (void)moveFriendAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex{  
  if (toIndex != fromIndex) {
    NSMutableArray* list = self.friendsList;
		id obj = [list objectAtIndex:fromIndex];
    [list removeObjectAtIndex:fromIndex];
    if (toIndex >= [self friendsCount]) {
      [list addObject:obj];
    } else {
      [list insertObject:obj atIndex:toIndex];
    }
		[self save];
  }
}

- (void)save{
  NSData *friendsData = [NSKeyedArchiver archivedDataWithRootObject:self.friendsList];
  NSData *userData = [NSKeyedArchiver archivedDataWithRootObject:self.user];
  [[NSUserDefaults standardUserDefaults] setObject:friendsData forKey:kTCSUserDefaultsLastFMFriendsList];
  [[NSUserDefaults standardUserDefaults] setObject:userData forKey:kTCSUserDefaultsLastFMUserName];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)load{
  NSData *storedUserData = [[NSUserDefaults standardUserDefaults] objectForKey:kTCSUserDefaultsLastFMUserName];
  NSData *storedFriendsListData = [[NSUserDefaults standardUserDefaults] objectForKey:kTCSUserDefaultsLastFMFriendsList];
  User *storedUser = [NSKeyedUnarchiver unarchiveObjectWithData:storedUserData];
  NSArray *storedFriendsList = [NSKeyedUnarchiver unarchiveObjectWithData:storedFriendsListData];
  
  if (storedFriendsList == nil){
    storedFriendsList = [NSArray array];
  }
  
  _user = storedUser;
  _friendsList = [storedFriendsList mutableCopy];
  
  DLog(@"loaded username: %@", self.user.userName);
  DLog(@"loaded friends: %@", self.friendsList);
}

@end
