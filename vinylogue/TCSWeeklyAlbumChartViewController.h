//
//  TCSWeeklyAlbumChartViewController.h
//  vinylogue
//
//  Created by Christopher Trott on 2/18/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TCSWeeklyAlbumChartViewController : UITableViewController

@property (nonatomic, copy) NSString *userName;

- (id)initWithUserName:(NSString *)userName;

@end
