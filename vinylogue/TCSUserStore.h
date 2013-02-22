//
//  TCSFriendsListStore.h
//  vinylogue
//
//  Created by Christopher Trott on 2/22/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TCSUserStore : NSObject

@property (nonatomic, strong) NSString *userName;

- (id)init;

// read
- (NSInteger)friendsCount;
- (NSString *)friendAtIndex:(NSUInteger)index;

// write
- (void)addFriendWithUserName:(NSString *)userName;
- (void)removeFriendAtIndex:(NSUInteger)index;
- (void)replaceFriendAtIndex:(NSUInteger)index withUserName:(NSString *)userName;

@end
