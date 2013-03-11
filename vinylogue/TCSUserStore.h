//
//  TCSFriendsListStore.h
//  vinylogue
//
//  Created by Christopher Trott on 2/22/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import <Foundation/Foundation.h>

@class User;

@interface TCSUserStore : NSObject

@property (nonatomic, readonly) User *user;

- (id)init;

// read
- (NSInteger)friendsCount;
- (User *)friendAtIndex:(NSUInteger)index;

// write
- (void)setUserName:(NSString *)userName;
- (void)addFriendWithUserName:(NSString *)userName;
- (void)removeFriendAtIndex:(NSUInteger)index;
- (void)replaceFriendAtIndex:(NSUInteger)index withUserName:(NSString *)userName;
- (void)moveFriendAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex;

@end
