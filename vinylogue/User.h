//
//  User.h
//  vinylogue
//
//  Created by Christopher Trott on 3/11/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface User : NSObject <NSCoding>

@property (nonatomic, copy) NSString *userName;

- (id)initWithUserName:(NSString *)userName;

@end
