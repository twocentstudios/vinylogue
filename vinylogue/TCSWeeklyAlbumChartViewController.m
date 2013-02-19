//
//  TCSWeeklyAlbumChartViewController.m
//  vinylogue
//
//  Created by Christopher Trott on 2/18/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import "TCSWeeklyAlbumChartViewController.h"

#import <ReactiveCocoa/ReactiveCocoa.h>
#import "EXTScope.h"

#import "TCSLastFMAPIClient.h"
#import "WeeklyAlbumChart.h"
#import "WeeklyChart.h"

#import "TCSAlbumArtistPlayCountCell.h"

@interface TCSWeeklyAlbumChartViewController ()

@property (nonatomic, retain) UITableView *tableView;

@property (nonatomic, retain) TCSLastFMAPIClient *lastFMClient;
@property (nonatomic, retain) NSArray *weeklyCharts;
@property (nonatomic, retain) NSArray *albumChartsForWeek;

@property (nonatomic, retain) NSDate *now;
@property (nonatomic, retain) NSDate *displayingDate;
@property (nonatomic) NSUInteger displayingYearsAgo;
@property (nonatomic, retain) WeeklyChart *displayingWeeklyChart;

@property (nonatomic) NSUInteger playCountFilter;

@end

@implementation TCSWeeklyAlbumChartViewController

- (id)initWithUserName:(NSString *)userName{
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    self.userName = userName;
    self.playCountFilter = 4;
  }
  return self;
}

- (void)loadView{
  self.view = [[UIView alloc] init];
  self.view.autoresizesSubviews = YES;
  
  self.tableView.delegate = self;
  self.tableView.dataSource = self;
  [self.view addSubview:self.tableView];
  
}

- (void)viewDidLoad{
  [super viewDidLoad];

  self.title = NSLocalizedString(@"Weekly Chart List", nil);
  
  // When the userName changes (or is loaded the first time) we need to basically reload everything. If there's no username set, we'll show an error
  RACSignal *userNameSignal = RACAbleWithStart(self.userName);
  
  @weakify(self);
  [[userNameSignal filter:^BOOL(id x) {
    return (x != nil);
  }] subscribeNext:^(NSString *userName) {
    NSLog(@"Loading client for %@...", userName);
    @strongify(self);
    self.lastFMClient = [TCSLastFMAPIClient clientForUserName:userName];
  }];
  
  [[userNameSignal filter:^BOOL(id x) {
    return (x == nil);
  }] subscribeNext:^(id x) {
    NSLog(@"Please set a username!");
  }];

//  RAC(self.now) = [RACSignal interval:60 * 60]; // update every hour

  // Update the date being displayed based on the current date/time and how many years ago we want to go back
  RAC(self.displayingDate) = [[RACSignal combineLatest:@[ RACAble(self.now), RACAble(self.displayingYearsAgo) ] reduce:^(NSDate *now, NSNumber *displayingYearsAgo){
    NSLog(@"Calculating time range for %@ year(s) ago...", displayingYearsAgo);
    // Naive way of getting 365 days worth of seconds ago
    return [now dateByAddingTimeInterval:-1*365*24*60*60*[displayingYearsAgo doubleValue]];
  }] filter:^BOOL(id x) {
    return (x != nil);
  }];
    
  // When the lastFMClient changes (probably because the username changed), look up the weekly chart list
  [[RACAbleWithStart(self.lastFMClient) filter:^BOOL(id x) {
    return (x != nil);
  }] subscribeNext:^(id x) {
    NSLog(@"Fetching date ranges for available charts...");
    [[self.lastFMClient fetchWeeklyChartList] subscribeNext:^(NSArray *weeklyCharts) {
      @strongify(self);
      self.weeklyCharts = weeklyCharts;
    } error:^(NSError *error) {
      NSLog(@"There was an error fetching the weekly chart list!");
    }];
  }];
  
  // When the weekly charts array changes (probably loading for the first time), or the displaying date changes (probably looking for a previous year), set the new weeklyChart (the exact week range that last.fm expects)
  RAC(self.displayingWeeklyChart) =
  [[RACSignal combineLatest:@[ RACAble(self.weeklyCharts), RACAble(self.displayingDate)]]
   map:^id(RACTuple *t) {
     NSLog(@"Calculating the date range for the weekly chart...");
     NSArray *weeklyCharts = t.first;
     NSDate *displayingDate = t.second;
     return [[weeklyCharts.rac_sequence
              filter:^BOOL(WeeklyChart *weeklyChart) {
                return (([weeklyChart.from compare:displayingDate] == NSOrderedAscending) && ([weeklyChart.to compare:displayingDate] == NSOrderedDescending));
              }] head];
   }];
  
  // When the weeklychart changes (being loaded the first time, or the display date changed), fetch the list of albums for that time period
  [[RACAble(self.displayingWeeklyChart) filter:^BOOL(id x) {
    return (x != nil);
  }] subscribeNext:^(WeeklyChart *displayingWeeklyChart) {
    NSLog(@"Loading album charts for the selected week...");
    @strongify(self);
    [[self.lastFMClient fetchWeeklyAlbumChartForChart:displayingWeeklyChart] subscribeNext:^(NSArray *albumChartsForWeek) {
      NSLog(@"Filtering charts by playcount...");
      @strongify(self);
      NSArray *filteredCharts = [[albumChartsForWeek.rac_sequence filter:^BOOL(WeeklyAlbumChart *chart) {
        @strongify(self);
        return (chart.playcountValue > self.playCountFilter);
      }] array];
      self.albumChartsForWeek = filteredCharts;
    }];
  }];
  
  // When the album charts gets changed, reload the table
  [[RACAble(self.albumChartsForWeek) deliverOn:[RACScheduler mainThreadScheduler]]
   subscribeNext:^(id x){
     NSLog(@"Refreshing table...");
    [self.tableView reloadData];
  }];
  
  self.now = [NSDate date];
  self.displayingYearsAgo = 1;
}

- (void)viewWillAppear:(BOOL)animated{
  [super viewWillAppear:animated];
  
}

- (void)viewWillLayoutSubviews{
  CGRect r = self.view.bounds;
  self.tableView.frame = r;
}

- (void)didReceiveMemoryWarning{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
  
  self.displayingYearsAgo += 1;
//  self.userName = @"ybsc";
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
  return [self.albumChartsForWeek count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
  static NSString *CellIdentifier = @"TCSAlbumArtistPlayCountCell";
  TCSAlbumArtistPlayCountCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (!cell) {
    cell = [[TCSAlbumArtistPlayCountCell alloc] init];
  }
  
  WeeklyAlbumChart *albumChart = [self.albumChartsForWeek objectAtIndex:indexPath.row];
  [cell setObject:albumChart];
  
  return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  id object = [self.albumChartsForWeek objectAtIndex:indexPath.row];
  NSLog(@"%@", object);
}

#pragma mark - view getters

- (UITableView *)tableView{
  if (!_tableView){
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
  }
  return _tableView;
}

@end
