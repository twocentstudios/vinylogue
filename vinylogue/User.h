//
//  User.h
//  vinylogue
//
//  Created by Christopher Trott on 3/11/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface User : NSObject

@property (nonatomic, copy) NSString *userName;

- (id)initWithUserName:(NSString *)userName;

// Quick archival
- (NSDictionary *)toDictionaryRepresentation;
+ (User *)fromDictionaryRepresentation:(NSDictionary *)dictionary;
+ (NSArray *)dictionaryRepresenationOfArray:(NSArray *)userArray;
+ (NSArray *)objectRepresenationFromArray:(NSArray *)dictionaryArray;

@end
