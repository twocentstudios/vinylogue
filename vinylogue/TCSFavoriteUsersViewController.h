//
//  TCSFavoriteUsersViewController.h
//  vinylogue
//
//  Created by Christopher Trott on 2/22/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TCSFavoriteUsersViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

- (id)initWithUserName:(NSString *)userName playCountFilter:(NSUInteger)playCountFilter friendsList:(NSArray *)friendsList;

@end
