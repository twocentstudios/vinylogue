//
//  TCSFavoriteUsersViewController.h
//  vinylogue
//
//  Created by Christopher Trott on 2/22/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TCSUserStore;

@interface TCSFavoriteUsersViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

- (id)initWithUserStore:(TCSUserStore *)userStore playCountFilter:(NSUInteger)playCountFilter;

@end
