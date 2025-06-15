//
//  User.h
//  vinylogue
//
//  Created by Christopher Trott on 3/11/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "LastFMObject.h"

@interface User : LastFMObject <NSCoding>

@property (nonatomic, strong) NSString *userName;
@property (nonatomic, strong) NSString *realName;
@property (nonatomic, strong) NSString *imageThumbURL;
@property (nonatomic, strong) NSString *imageURL;
@property (nonatomic, strong) NSString *lastFMid;
@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSString *totalPlayCount; // not saved

- (id)initWithUserName:(NSString *)userName;

@end
