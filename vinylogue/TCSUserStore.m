//
//  TCSFriendsListStore.m
//  vinylogue
//
//  Created by Christopher Trott on 2/22/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import "TCSUserStore.h"
#import "User.h"

#import <ReactiveCocoa/ReactiveCocoa.h>

@interface TCSUserStore ()

@property (nonatomic, strong) NSMutableArray *friendsList;
@property (nonatomic, strong) RACReplaySubject *friendListCountSignal;

@end

@implementation TCSUserStore

- (id)init{
  self = [super init];
  if (self) {
    self.friendListCountSignal = [RACReplaySubject subject];
    [self load];
  }
  return self;
}

- (void)dealloc{
  [self.friendListCountSignal sendCompleted];
}

- (void)setUser:(User *)user{
  if (_user != user){
    _user = user;
    [self save];
  }
}

- (NSInteger)friendsCount{
  return [self.friendsList count];
}

- (void)friendCountChanged{
  [self.friendListCountSignal sendNext:@([self friendsCount])];
}

- (User *)friendAtIndex:(NSUInteger)index{
  if (index < [self friendsCount]){
    return [self.friendsList objectAtIndex:index];
  }
  return nil;
}

- (void)addFriend:(User *)user{
  [self addFriends:@[user]];
}

- (void)addFriends:(NSArray *)friends{
  if (friends != nil){
    // Start with all new friends and remove those that are already in
    // the user's friend list
    NSMutableArray *friendsToAdd = [friends mutableCopy];
    for (User *newFriend in friends){
      for (User *oldFriend in self.friendsList) {
        if ([oldFriend.userName isEqualToString:newFriend.userName]){
          [friendsToAdd removeObject:newFriend];
        }
      }
    }
    
    if ([friendsToAdd count] > 0){
      [self.friendsList addObjectsFromArray:friendsToAdd];
      [self friendCountChanged];
      [self save];
    }
  }
}

- (void)removeFriendAtIndex:(NSUInteger)index{
  if (index < [self friendsCount]){
    [self.friendsList removeObjectAtIndex:index];
    [self friendCountChanged];
    [self save];
  }
}

- (void)removeAllFriends{
  [self.friendsList removeAllObjects];
  [self friendCountChanged];
  [self save];
}

- (void)replaceFriendAtIndex:(NSUInteger)index withFriend:(User *)user{
  if (index < [self friendsCount]){
    [self.friendsList replaceObjectAtIndex:index withObject:user];
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
  
  [self friendCountChanged];
  
  DLog(@"loaded username: %@", self.user.userName);
  DLog(@"loaded friends: %@", self.friendsList);
}

@end
