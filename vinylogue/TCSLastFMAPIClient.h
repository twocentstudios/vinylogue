//
//  TCSLastFMAPIClient.h
//  vinylogue
//
//  Created by Christopher Trott on 2/17/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>

@class RACSignal;
@class WeeklyChart;
@class WeeklyAlbumChart;
@class Artist;
@class Album;
@class User;

@interface TCSLastFMAPIClient : AFHTTPClient

@property (nonatomic, readonly) User *user;

// Client for anonymous requests (not reliant on user specific data)
+ (TCSLastFMAPIClient *)client;

// Client for user specific requests
+ (TCSLastFMAPIClient *)clientForUser:(User *)user;

- (RACSignal *)fetchWeeklyChartList;
- (RACSignal *)fetchWeeklyAlbumChartForChart:(WeeklyChart *)chart;
- (RACSignal *)fetchAlbumDetailsForAlbum:(Album *)album;
- (RACSignal *)fetchUserForUserName:(NSString *)userName;

@end
