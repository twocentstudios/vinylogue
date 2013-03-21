//
//  TCSFriendsListStore.h
//  vinylogue
//
//  Created by Christopher Trott on 2/22/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import <Foundation/Foundation.h>

@class User;
@class RACReplaySubject;

@interface TCSUserStore : NSObject

@property (nonatomic, strong) User *user;
@property (nonatomic, readonly) RACReplaySubject *friendListCountSignal;

- (id)init;

// read
- (NSInteger)friendsCount;
- (User *)friendAtIndex:(NSUInteger)index;

// write
- (void)addFriend:(User *)user;
- (void)addFriends:(NSArray *)friends;
- (void)removeFriendAtIndex:(NSUInteger)index;
- (void)replaceFriendAtIndex:(NSUInteger)index withFriend:(User *)user;
- (void)moveFriendAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex;

@end
