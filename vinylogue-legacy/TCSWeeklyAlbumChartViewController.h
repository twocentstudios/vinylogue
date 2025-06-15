//
//  TCSWeeklyAlbumChartViewController.h
//  vinylogue
//
//  Created by Christopher Trott on 2/18/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import <UIKit/UIKit.h>

@class User;

@interface TCSWeeklyAlbumChartViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

- (id)initWithUser:(User *)user playCountFilter:(NSUInteger)playCountFilter;

@end
