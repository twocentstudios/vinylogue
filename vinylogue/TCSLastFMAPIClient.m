//
//  TCSLastFMAPIClient.m
//  vinylogue
//
//  Created by Christopher Trott on 2/17/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import "TCSLastFMAPIClient.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

#import "WeeklyChart.h"
#import "WeeklyAlbumChart.h"
#import "User.h"

static NSString * const kTCSLastFMAPIBaseURLString = @"http://ws.audioscrobbler.com/2.0/";

@interface TCSLastFMAPIClient ()

@property (nonatomic, copy) NSString *userName;

@end

@implementation TCSLastFMAPIClient

+ (TCSLastFMAPIClient *)client{
  TCSLastFMAPIClient *client = [[self alloc] initWithBaseURL:[NSURL URLWithString:kTCSLastFMAPIBaseURLString]];
  return client;
}

+ (TCSLastFMAPIClient *)clientForUserName:(NSString *)userName{
  TCSLastFMAPIClient *client = [[self alloc] initWithBaseURL:[NSURL URLWithString:kTCSLastFMAPIBaseURLString]];
  client.userName = userName;
  return client;
}

- (id)initWithBaseURL:(NSURL *)url {
  self = [super initWithBaseURL:url];
  if (!self) {
    return nil;
  }
  
  [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
  [self setDefaultHeader:@"Accept" value:@"application/json"];
  
  return self;
}

- (RACSignal *)enqueueRequestWithMethod:(NSString *)method path:(NSString *)path parameters:(NSDictionary *)parameters {
	RACReplaySubject *subject = [RACReplaySubject subject];
	NSMutableURLRequest *request = [self requestWithMethod:method path:path parameters:parameters];
  request.cachePolicy = NSURLRequestReturnCacheDataElseLoad;
	AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
    NSNumber *errorCode = [responseObject objectForKey:@"error"];
    if (errorCode){
      NSError *error = [NSError errorWithDomain:@"" code:[errorCode integerValue] userInfo:@{NSLocalizedDescriptionKey: [responseObject objectForKey:@"message"]}];
      [subject sendError:error];
    }else{
      [subject sendNext:responseObject];
      [subject sendCompleted];
    }
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		[subject sendError:error];
	}];
  
	[self enqueueHTTPRequestOperation:operation];
  
	return [subject deliverOn:[RACScheduler scheduler]];
}

// returns an Array of all WeeklyChart objects
- (RACSignal *)fetchWeeklyChartList{
  NSParameterAssert(self.userName);
  
  NSDictionary *params = @{@"method": @"user.getweeklychartlist",
                           @"user": self.userName,
                           @"api_key": kTCSLastFMAPIKeyString,
                           @"format": @"json"};
  return [[[self enqueueRequestWithMethod:@"GET" path:@"" parameters:params]
           map:^id(NSDictionary *responseObject) {
             return [[responseObject objectForKey:@"weeklychartlist"] arrayForKey:@"chart"];
           }] map:^id(NSArray *chartList) {
             return [[chartList.rac_sequence map:^id(NSDictionary *chartDictionary) {
               WeeklyChart *chart = [[WeeklyChart alloc] init];
               chart.from = [NSDate dateWithTimeIntervalSince1970:[[chartDictionary objectForKey:@"from"] doubleValue]];
               chart.to = [NSDate dateWithTimeIntervalSince1970:[[chartDictionary objectForKey:@"to"] doubleValue]];
               return chart;
             }] array];
           }];
  
}

- (RACSignal *)fetchWeeklyAlbumChartForChart:(WeeklyChart *)chart{
  NSParameterAssert(self.userName);

  if (chart == nil){
    return [RACSignal error:nil];
  }
  
  NSMutableDictionary *params = [ @{@"method": @"user.getweeklyalbumchart",
                                 @"user": self.userName,
                                 @"api_key": kTCSLastFMAPIKeyString,
                                 @"format": @"json"} mutableCopy];
  
  [params setObject:[@([chart.from timeIntervalSince1970]) stringValue] forKey:@"from"];
  [params setObject:[@([chart.to timeIntervalSince1970]) stringValue] forKey:@"to"];
  
  return [[[self enqueueRequestWithMethod:@"GET" path:@"" parameters:params]
           map:^id(NSDictionary *responseObject) {
             return [[responseObject objectForKey:@"weeklyalbumchart"] arrayForKey:@"album"];
           }] map:^id(NSArray *albumChartList) {
             RACSequence *list = [albumChartList.rac_sequence map:^id(NSDictionary *albumChartDictionary) {
               WeeklyAlbumChart *albumChart = [[WeeklyAlbumChart alloc] init];
               albumChart.artistName = [[albumChartDictionary objectForKey:@"artist"] objectForKey:@"#text"];
               albumChart.artistMbid = [[albumChartDictionary objectForKey:@"artist"] objectForKey:@"mbid"];
               albumChart.albumName = [albumChartDictionary objectForKey:@"name"];
               albumChart.albumMbid = [albumChartDictionary objectForKey:@"mbid"];
               albumChart.albumURL = [albumChartDictionary objectForKey:@"url"];
               albumChart.playcount = @([[albumChartDictionary objectForKey:@"playcount"] integerValue]);
               albumChart.rank = @([[[albumChartDictionary objectForKey:@"@attr"] objectForKey:@"rank"] integerValue]);
               albumChart.weeklyChart = chart;
               return albumChart;
             }];
             return [list array];
           }];
}

- (RACSignal *)fetchImageURLForWeeklyAlbumChart:(WeeklyAlbumChart *)albumChart{
  if (albumChart == nil){
    return [RACSignal error:nil];
  }
  
  NSMutableDictionary *params = [@{ @"method": @"album.getinfo",
                                 @"api_key": kTCSLastFMAPIKeyString,
                                 @"format": @"json" } mutableCopy];
  
  if ([albumChart.albumMbid length]){
    [params setObject:albumChart.albumMbid forKey:@"mbid"];
  }else if (albumChart.artistName && albumChart.albumName){
    [params setObject:albumChart.artistName forKey:@"artist"];
    [params setObject:albumChart.albumName forKey:@"album"];
  }else{
    return [RACSignal error:nil];
  }
  
  // userName is optional (returns additional user-specific album info)
  if (self.userName){
    [params setObject:self.userName forKey:@"username"];
  }
  
  return [[[[self enqueueRequestWithMethod:@"GET" path:@"" parameters:params]
            map:^id(NSDictionary *responseObject) {
              return [[responseObject objectForKey:@"album"] objectForKey:@"image"];
            }] map:^id(NSArray *imageArray) {
              NSMutableDictionary *newDict = [NSMutableDictionary dictionaryWithCapacity:[imageArray count]];
              for (NSDictionary *imgDict in imageArray){
                [newDict setObject:[imgDict objectForKey:@"#text"] forKey:[imgDict objectForKey:@"size"]];
              }
              return newDict;
            }] map:^id(NSDictionary *imageSizeDict) {
              NSString *largestImageURL = nil;
              largestImageURL = [imageSizeDict objectForKey:@"small"];
              largestImageURL = [imageSizeDict objectForKey:@"medium"];
              largestImageURL = [imageSizeDict objectForKey:@"large"];
              //             largestImageURL = [imageSizeDict objectForKey:@"extralarge"];
              //             largestImageURL = [imageSizeDict objectForKey:@"mega"];
              albumChart.albumImageURL = largestImageURL;
              return largestImageURL;
            }];
}

- (RACSignal *)fetchUserForUserName:(NSString *)userName{
  if (userName == nil){
    return [RACSignal error:nil];
  }
  
  NSMutableDictionary *params = [@{ @"method": @"user.getinfo",
                                 @"user": userName,
                                 @"api_key": kTCSLastFMAPIKeyString,
                                 @"format": @"json" } mutableCopy];
  
  return [[[self enqueueRequestWithMethod:@"GET" path:@"" parameters:params]
            map:^id(NSDictionary *responseObject) {
              return [responseObject objectForKey:@"user"];
            }] map:^id(NSDictionary *userDict) {
              User *user = [[User alloc] init];
              user.userName = [userDict objectForKey:@"name"];
              return user;
            }];
}

@end
