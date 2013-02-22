//
//  TCSFriendsListStore.h
//  vinylogue
//
//  Created by Christopher Trott on 2/22/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TCSFriendsListStore : NSObject

- (id)initWithList:(NSArray *)friendsList;

// read
- (NSInteger)count;
- (NSString *)userAtIndex:(NSUInteger)index;

// write
- (void)addUserName:(NSString *)userName;
- (void)removeUserAtIndex:(NSUInteger)index;
- (void)replaceUserAtIndex:(NSUInteger)index withUserName:(NSString *)userName;

@end
