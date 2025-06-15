//
//  User.m
//  vinylogue
//
//  Created by Christopher Trott on 3/11/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import "User.h"

#define kUserUserName @"kUserUserName"
#define kUserRealName @"kUserRealName"
#define kUserImageThumbURL @"kUserImageThumbURL"
#define kUserImageURL @"kUserImageURL"
#define kUserLastFMid @"kUserLastFMid"
#define kUserURL @"kUserURL"

@implementation User

+ (id)objectFromExternalDictionary:(NSDictionary *)dict{
  User *user = [[User alloc] init];
  user.userName = [dict objectForKey:@"name"];
  user.realName = [dict objectForKey:@"realname"];
  user.lastFMid = [dict objectForKey:@"id"];
  user.url = [dict objectForKey:@"url"];
  user.totalPlayCount = [dict objectForKey:@"playcount"];
  
  NSArray *imageArray = [dict objectForKey:@"image"];
  NSString *imageThumbURL, *imageURL;
  TCSSetImageURLsForThumbAndImage(imageArray, &imageThumbURL, &imageURL);
  user.imageThumbURL = imageThumbURL;
  user.imageURL = imageURL;
  return user;
}

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
    self.realName = [decoder decodeObjectForKey:kUserRealName];
    self.imageThumbURL = [decoder decodeObjectForKey:kUserImageThumbURL];
    self.imageURL = [decoder decodeObjectForKey:kUserImageURL];
    self.lastFMid = [decoder decodeObjectForKey:kUserLastFMid];
    self.url = [decoder decodeObjectForKey:kUserURL];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
  [encoder encodeObject:self.userName forKey:kUserUserName];
  [encoder encodeObject:self.realName forKey:kUserRealName];
  [encoder encodeObject:self.imageThumbURL forKey:kUserImageThumbURL];
  [encoder encodeObject:self.imageURL forKey:kUserImageURL];
  [encoder encodeObject:self.lastFMid forKey:kUserLastFMid];
  [encoder encodeObject:self.url forKey:kUserURL];
}

@end
