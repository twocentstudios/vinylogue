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
  [[NSUserDefaults standardUserDefaults] setObject:[User dictionaryRepresenationOfArray:self.friendsList] forKey:kTCSUserDefaultsLastFMFriendsList];
  [[NSUserDefaults standardUserDefaults] setObject:[self.user toDictionaryRepresentation] forKey:kTCSUserDefaultsLastFMUserName];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)load{
  NSDictionary *storedUser = [[NSUserDefaults standardUserDefaults] objectForKey:kTCSUserDefaultsLastFMUserName];
  NSArray *storedFriendsList = [[NSUserDefaults standardUserDefaults] objectForKey:kTCSUserDefaultsLastFMFriendsList];
  
  if (storedFriendsList == nil){
    storedFriendsList = [NSArray array];
    [[NSUserDefaults standardUserDefaults] setObject:storedFriendsList forKey:kTCSUserDefaultsLastFMFriendsList];
    [[NSUserDefaults standardUserDefaults] synchronize];
  }
  
  _user = [User fromDictionaryRepresentation:storedUser];
  _friendsList = [NSMutableArray arrayWithArray:[User objectRepresenationFromArray:storedFriendsList]];
  
  DLog(@"loaded username: %@", self.user.userName);
  DLog(@"loaded friends: %@", self.friendsList);
}

@end
