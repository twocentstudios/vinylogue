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
               WeeklyChart *chart = [[WeeklyChart alloc] init];
               chart.from = [NSDate dateWithTimeIntervalSince1970:[[chartDictionary objectForKey:@"from"] doubleValue]];
               chart.to = [NSDate dateWithTimeIntervalSince1970:[[chartDictionary objectForKey:@"to"] doubleValue]];
               return chart;
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
               WeeklyAlbumChart *albumChart = [[WeeklyAlbumChart alloc] init];
               albumChart.album = [[Album alloc] init];
               albumChart.album.weeklyAlbumChart = albumChart;
               albumChart.album.artist = [[Artist alloc] init];
               albumChart.album.artist.name = [[albumChartDictionary objectForKey:@"artist"] objectForKey:@"#text"];
               albumChart.album.artist.mbid = [[albumChartDictionary objectForKey:@"artist"] objectForKey:@"mbid"];
               albumChart.album.name = [albumChartDictionary objectForKey:@"name"];
               albumChart.album.mbid = [albumChartDictionary objectForKey:@"mbid"];
               albumChart.album.url = [albumChartDictionary objectForKey:@"url"];
               albumChart.playcount = @([[albumChartDictionary objectForKey:@"playcount"] integerValue]);
               albumChart.rank = @([[[albumChartDictionary objectForKey:@"@attr"] objectForKey:@"rank"] integerValue]);
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
              Album *detailAlbum = album;
              
              if (!detailAlbum.artist){
                detailAlbum.artist = [[Artist alloc] init];
              }
              detailAlbum.artist.name = [albumDict objectForKey:@"artist"];
              detailAlbum.name = [albumDict objectForKey:@"name"];
              detailAlbum.lastFMid = [albumDict objectForKey:@"id"];
              detailAlbum.mbid = [albumDict objectForKey:@"mbid"];
              detailAlbum.url = [albumDict objectForKey:@"url"];
              detailAlbum.releaseDate = [NSDate date]; // TODO: parse the date
              detailAlbum.totalPlayCount = @([[albumDict objectForKey:@"userplaycount"] integerValue]);
              
              // Process image array
              NSArray *imageArray = [albumDict objectForKey:@"image"];
              NSMutableDictionary *newAlbumDict = [NSMutableDictionary dictionaryWithCapacity:[imageArray count]];
              for (NSDictionary *imgDict in imageArray){
                [newAlbumDict setObject:[imgDict objectForKey:@"#text"] forKey:[imgDict objectForKey:@"size"]];
              }
              NSString *largestImageURL = nil;
              NSString *currentImageURL = nil;
              largestImageURL = [newAlbumDict objectForKey:@"small"];
              currentImageURL = [newAlbumDict objectForKey:@"medium"];
              if (currentImageURL != nil)
                largestImageURL = currentImageURL;
              currentImageURL = [newAlbumDict objectForKey:@"large"];
              if (currentImageURL != nil)
                largestImageURL = currentImageURL;
              detailAlbum.imageThumbURL = largestImageURL;
              currentImageURL = [newAlbumDict objectForKey:@"extralarge"];
              if (currentImageURL != nil)
                largestImageURL = currentImageURL;
              currentImageURL = [newAlbumDict objectForKey:@"mega"];
              if (currentImageURL != nil)
                largestImageURL = currentImageURL;
              detailAlbum.imageURL = largestImageURL;
              
              // Indicates Album object is complete
              detailAlbum.detailLoaded = YES;
              
              return detailAlbum;
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
