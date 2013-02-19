//
//  TCSLastFMAPIClient.h
//  vinylogue
//
//  Created by Christopher Trott on 2/17/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import "AFRESTClient.h"

@class RACSignal;
@class WeeklyChart;

@interface TCSLastFMAPIClient : AFHTTPClient

@property (nonatomic, readonly, copy) NSString *userName;

+ (TCSLastFMAPIClient *)clientForUserName:(NSString *)userName;

- (RACSignal *)fetchWeeklyChartList;
- (RACSignal *)fetchWeeklyAlbumChart;
- (RACSignal *)fetchWeeklyAlbumChartForChart:(WeeklyChart *)chart;


@end
