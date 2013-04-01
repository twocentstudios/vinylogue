//
//  TCSLastFMAPIClient.m
//  vinylogue
//
//  Created by Christopher Trott on 2/17/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import "TCSLastFMAPIClient.h"
#import "TCSVinylogueSecret.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

#import "WeeklyChart.h"
#import "WeeklyAlbumChart.h"
#import "User.h"
#import "Album.h"
#import "Artist.h"

static NSString * const kTCSLastFMAPIBaseURLString = @"http://ws.audioscrobbler.com/2.0/";

@interface TCSLastFMAPIClient ()

@property (nonatomic, copy) NSString *userName;
@property (nonatomic, strong) User *user;

@end

@implementation TCSLastFMAPIClient

+ (TCSLastFMAPIClient *)clientForUser:(User *)user{
  TCSLastFMAPIClient *client = [[self alloc] initWithBaseURL:[NSURL URLWithString:kTCSLastFMAPIBaseURLString]];
  client.user = user;
  return client;
}

+ (TCSLastFMAPIClient *)client{
  return [[self class] clientForUser:nil];
}

- (id)initWithBaseURL:(NSURL *)url {
  self = [super initWithBaseURL:url];
  if (!self) {
    return nil;
  }
  
  [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
  [self setDefaultHeader:@"Accept" value:@"application/json"];
  [self setDefaultHeader:@"Accept-Encoding" value:nil];
  
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
    // Use a cached response if it exists (iOS6 bug)
    NSCachedURLResponse *cachedResponse = [[NSURLCache sharedURLCache] cachedResponseForRequest:request];
    if (cachedResponse != nil && [[cachedResponse data] length] > 0){
      NSError *JSONError = nil;
      id JSON = [NSJSONSerialization JSONObjectWithData:cachedResponse.data options:0 error:&JSONError];
      if (!JSONError){
        [subject sendNext:JSON];
        [subject sendCompleted];
      }else{
        [subject sendError:error];
      }
    }else{
      [subject sendError:error];
    }
	}];
  
	[self enqueueHTTPRequestOperation:operation];
  
	return [subject deliverOn:[RACScheduler scheduler]];
}

// returns an Array of all WeeklyChart objects
- (RACSignal *)fetchWeeklyChartList{
  NSParameterAssert(self.user.userName);
  
  NSDictionary *params = @{@"method": @"user.getweeklychartlist",
                           @"user": self.user.userName,
                           @"api_key": kTCSLastFMAPIKeyString,
                           @"format": @"json"};
  return [[[self enqueueRequestWithMethod:@"GET" path:@"" parameters:params]
           map:^id(NSDictionary *responseObject) {
             return [[responseObject objectForKey:@"weeklychartlist"] arrayForKey:@"chart"];
           }] map:^id(NSArray *chartList) {
             return [[chartList.rac_sequence map:^id(NSDictionary *chartDictionary) {
               return [WeeklyChart objectFromExternalDictionary:chartDictionary];
             }] array];
           }];
  
}

- (RACSignal *)fetchWeeklyAlbumChartForChart:(WeeklyChart *)chart{
  NSParameterAssert(self.user.userName);

  if (chart == nil){
    return [RACSignal error:nil];
  }
  
  NSMutableDictionary *params = [ @{@"method": @"user.getweeklyalbumchart",
                                 @"user": self.user.userName,
                                 @"api_key": kTCSLastFMAPIKeyString,
                                 @"format": @"json"} mutableCopy];
  
  [params setObject:[@([chart.from timeIntervalSince1970]) stringValue] forKey:@"from"];
  [params setObject:[@([chart.to timeIntervalSince1970]) stringValue] forKey:@"to"];
  
  return [[[self enqueueRequestWithMethod:@"GET" path:@"" parameters:params]
           map:^id(NSDictionary *responseObject) {
             return [[responseObject objectForKey:@"weeklyalbumchart"] arrayForKey:@"album"];
           }] map:^id(NSArray *albumChartList) {
             RACSequence *list = [albumChartList.rac_sequence map:^id(NSDictionary *albumChartDictionary) {
               WeeklyAlbumChart *albumChart = [WeeklyAlbumChart objectFromExternalDictionary:albumChartDictionary];
               albumChart.weeklyChart = chart;
               albumChart.user = self.user;
               return albumChart;
             }];
             return [list array];
           }];
}

- (RACSignal *)fetchAlbumDetailsForAlbum:(Album *)album{
  if (album == nil){
    return [RACSignal error:nil];
  }
  
  NSMutableDictionary *params = [@{ @"method": @"album.getinfo",
                                 @"api_key": kTCSLastFMAPIKeyString,
                                 @"format": @"json" } mutableCopy];
  
  if ([album.mbid length]){
    [params setObject:album.mbid forKey:@"mbid"];
  }else if (album.artist.name && album.name){
    [params setObject:album.artist.name forKey:@"artist"];
    [params setObject:album.name forKey:@"album"];
  }else{
    NSError *error = [NSError errorWithDomain:@"vinylogue" code:0 userInfo:@{ NSLocalizedDescriptionKey: @"Not enough info in supplied Album to look up details." }];
    return [RACSignal error:error];
  }
  
  // userName is optional (returns additional user-specific album info)
  if (self.user.userName){
    [params setObject:self.user.userName forKey:@"username"];
  }
  
  return [[[self enqueueRequestWithMethod:@"GET" path:@"" parameters:params]
            map:^id(NSDictionary *responseObject) {
              return [responseObject objectForKey:@"album"];
            }] map:^id(NSDictionary *albumDict) {
              // Populate new data into the original album object
              [album populateFromExternalDictionary:albumDict];
              return album;
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
              return [User objectFromExternalDictionary:userDict];
            }];
}

- (RACSignal *)fetchFriends{
  return [self fetchFriendsForUser:self.user];
}

- (RACSignal *)fetchFriendsForUser:(User *)user{
  if (user == nil){
    return [RACSignal error:nil];
  }
  
  // Limit 0 returns all (I think)
  NSMutableDictionary *params = [@{ @"method": @"user.getfriends",
                                 @"user": user.userName,
                                 @"limit": @"0",
                                 @"api_key": kTCSLastFMAPIKeyString,
                                 @"format": @"json" } mutableCopy];
  
  return [[[self enqueueRequestWithMethod:@"GET" path:@"" parameters:params]
           map:^id(NSDictionary *responseObject) {
             return [[responseObject objectForKey:@"friends"] arrayForKey:@"user"];
           }] map:^id(NSArray *friendsArray) {
             RACSequence *list = [friendsArray.rac_sequence map:^id(NSDictionary *friendDict) {
               return [User objectFromExternalDictionary:friendDict];
             }];
             return [list array];
           }];
}


@end
