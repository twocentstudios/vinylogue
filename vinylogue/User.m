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

# pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)decoder{
  if (self = [super init]) {
    self.userName = [decoder decodeObjectForKey:kUserUserName];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
  [encoder encodeObject:self.userName forKey:kUserUserName];
}

@end
