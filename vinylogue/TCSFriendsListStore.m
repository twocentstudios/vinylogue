//
//  TCSFriendsListStore.m
//  vinylogue
//
//  Created by Christopher Trott on 2/22/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import "TCSFriendsListStore.h"

@interface TCSFriendsListStore ()

@property (nonatomic, strong) NSMutableArray *friendsList;

@end

@implementation TCSFriendsListStore

- (id)initWithList:(NSArray *)friendsList{
  self = [super init];
  if (self) {
    self.friendsList = [NSMutableArray arrayWithArray:friendsList];
  }
  return self;
}

- (NSInteger)count{
  return [self.friendsList count];
}

- (NSString *)userAtIndex:(NSUInteger)index{
  if (index < [self count]){
    return [self.friendsList objectAtIndex:index];
  }
  return nil;
}

- (void)addUserName:(NSString *)userName{
  if (userName != nil) {
    [self.friendsList addObject:userName];
    [self save];
  }
}

- (void)removeUserAtIndex:(NSUInteger)index{
  if (index < [self count]){
    [self.friendsList removeObjectAtIndex:index];
    [self save];
  }
}

- (void)replaceUserAtIndex:(NSUInteger)index withUserName:(NSString *)userName{
  if (index < [self count]){
    [self.friendsList replaceObjectAtIndex:index withObject:userName];
    [self save];
  }
}

- (void)save{
  [[NSUserDefaults standardUserDefaults] setObject:self.friendsList forKey:kTCSUserDefaultsLastFMFriendsList];
  [[NSUserDefaults standardUserDefaults] synchronize];
}


@end
