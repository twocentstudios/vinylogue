//
//  User.m
//  vinylogue
//
//  Created by Christopher Trott on 3/11/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import "User.h"

#define kUserUserName @"kUserUserName"

@implementation User

- (id)initWithUserName:(NSString *)userName{
  self = [super init];
  if (self) {
    self.userName = userName;
  }
  return self;
}

- (NSString *)description{
  return self.userName;
}

# pragma mark - quick archival

- (NSDictionary *)toDictionaryRepresentation{
  return @{ kUserUserName: _userName };
}

+ (User *)fromDictionaryRepresentation:(NSDictionary *)dictionary{
  if (!dictionary)
    return nil;
  
  User *user = [[User alloc] init];
  user.userName = [dictionary objectForKey:kUserUserName];
  return user;
}

+ (NSArray *)dictionaryRepresenationOfArray:(NSArray *)userArray{
  NSMutableArray *outArray = [NSMutableArray arrayWithCapacity:[userArray count]];
  for (User *user in userArray){
    [outArray addObject:[user toDictionaryRepresentation]];
  }
  return outArray;
}

+ (NSArray *)objectRepresenationFromArray:(NSArray *)dictionaryArray{
  NSMutableArray *outArray = [NSMutableArray arrayWithCapacity:[dictionaryArray count]];
  for (NSDictionary *user in dictionaryArray){
    [outArray addObject:[User fromDictionaryRepresentation:user]];
  }
  return outArray;
}

@end
