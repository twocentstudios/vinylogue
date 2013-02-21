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

#import "TCSSlideSelectView.h"
#import "TCSAlbumArtistPlayCountCell.h"
#import "TCSInnerShadowView.h"

@interface TCSWeeklyAlbumChartViewController ()

@property (nonatomic, strong) TCSSlideSelectView *slideSelectView;
@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) TCSLastFMAPIClient *lastFMClient;
@property (nonatomic, strong) NSArray *weeklyCharts;
@property (nonatomic, strong) NSArray *albumChartsForWeek;

@property (nonatomic, strong) NSCalendar *calendar;
@property (nonatomic, strong) NSDate *now;
@property (nonatomic, strong) NSDate *displayingDate;
@property (nonatomic) NSUInteger displayingYearsAgo;
@property (nonatomic, strong) WeeklyChart *displayingWeeklyChart;
@property (nonatomic, strong) NSDate *earliestScrobbleDate;
@property (nonatomic, strong) NSDate *latestScrobbleDate;
@property (nonatomic) BOOL canMoveForwardOneYear;
@property (nonatomic) BOOL canMoveBackOneYear;

@property (nonatomic) NSUInteger playCountFilter;

@end

@implementation TCSWeeklyAlbumChartViewController

- (id)initWithUserName:(NSString *)userName{
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    self.title = NSLocalizedString(@"Vinylogue", nil);
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo"]];
    
    self.userName = userName;
    self.playCountFilter = 4;
    self.calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
  }
  return self;
}

- (void)loadView{
  self.view = [[UIView alloc] init];
  self.view.autoresizesSubviews = YES;
  
  [self.view addSubview:self.slideSelectView];
  
  self.tableView.delegate = self;
  self.tableView.dataSource = self;
  [self.view addSubview:self.tableView];
  
}

- (void)viewDidLoad{
  [super viewDidLoad];
  
  [self setUpViewSignals];

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
    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.year = -1*[displayingYearsAgo integerValue];
    return [self.calendar dateByAddingComponents:components toDate:now options:0];
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
      if ([weeklyCharts count] > 0){
        WeeklyChart *firstChart = self.weeklyCharts[0];
        WeeklyChart *lastChart = [self.weeklyCharts lastObject];
        self.earliestScrobbleDate = firstChart.from;
        self.latestScrobbleDate = lastChart.to;
      }
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
    } error:^(NSError *error) {
      @strongify(self);
      self.albumChartsForWeek = nil;
      NSLog(@"There was an error fetching the weekly album charts!");
    }];
  }];
  
  // When the album charts gets changed, reload the table
  [[RACAble(self.albumChartsForWeek) deliverOn:[RACScheduler mainThreadScheduler]]
   subscribeNext:^(id x){
     NSLog(@"Refreshing table...");
    [self.tableView reloadData];
  }];
  
  // Change displayed year by sliding the slideSelectView left or right
  self.slideSelectView.pullLeftCommand = [RACCommand commandWithCanExecuteSignal:RACAble(self.canMoveBackOneYear) block:^(id sender) {
    self.displayingYearsAgo += 1;
  }];
  self.slideSelectView.pullRightCommand = [RACCommand commandWithCanExecuteSignal:RACAble(self.canMoveForwardOneYear) block:^(id sender) {
    self.displayingYearsAgo -= 1;
  }];
  
  self.now = [NSDate date];
  self.displayingYearsAgo = 1;
}

- (void)setUpViewSignals{
  @weakify(self);
  
  // Top Label
  [RACAbleWithStart(self.userName) subscribeNext:^(NSString *userName) {
    @strongify(self);
    if (userName){
      self.slideSelectView.topLabel.text = [NSString stringWithFormat:@"%@'s charts", userName];
    }else{
      self.slideSelectView.topLabel.text = @"No last.fm user selected!";
    }
    [self.slideSelectView setNeedsLayout];
  }];
  
  // Bottom Label, Left Label, Right Label
  [[RACSignal combineLatest:@[RACAbleWithStart(self.displayingDate), RACAbleWithStart(self.earliestScrobbleDate), RACAbleWithStart(self.latestScrobbleDate)] ]
   subscribeNext:^(RACTuple *dates) {
     NSDate *displayingDate = dates.first;
     NSDate *earliestScrobbleDate = dates.second;
     NSDate *latestScrobbleDate = dates.third;
    @strongify(self);
    if (displayingDate){
      // Set the displaying date
      NSDateComponents *components = [self.calendar components:NSYearForWeekOfYearCalendarUnit|NSYearCalendarUnit|NSWeekOfYearCalendarUnit fromDate:displayingDate];
      self.slideSelectView.bottomLabel.text = [NSString stringWithFormat:@"WEEK %i of %i", components.weekOfYear, components.yearForWeekOfYear];
      
      // Set up date calculation shenanigans
      NSDateComponents *pastComponents = [[NSDateComponents alloc] init];
      pastComponents.year = -1;
      NSDateComponents *futureComponents = [[NSDateComponents alloc] init];
      futureComponents.year = 1;
      NSDate *pastTargetDate = [self.calendar dateByAddingComponents:pastComponents toDate:displayingDate options:0];
      NSDate *futureTargetDate = [self.calendar dateByAddingComponents:futureComponents toDate:displayingDate options:0];
      
      self.canMoveBackOneYear = ([pastTargetDate compare:earliestScrobbleDate] == NSOrderedDescending);
      self.canMoveForwardOneYear = ([futureTargetDate compare:latestScrobbleDate] == NSOrderedAscending);
      
      // Only show the left and right labels/arrows if there's data there to jump to
      if (self.canMoveBackOneYear){
        self.slideSelectView.backLeftLabel.text = [NSString stringWithFormat:@"%i", components.yearForWeekOfYear-1];
        self.slideSelectView.backLeftButton.hidden = NO;
      }else{
        self.slideSelectView.backLeftLabel.text = nil;
        self.slideSelectView.backLeftButton.hidden = YES;
      }
      if (self.canMoveForwardOneYear){
        self.slideSelectView.backRightLabel.text = [NSString stringWithFormat:@"%i", components.yearForWeekOfYear+1];
        self.slideSelectView.backRightButton.hidden = NO;
      }else{
        self.slideSelectView.backRightLabel.text = nil;
        self.slideSelectView.backRightButton.hidden = YES;
      }
      
    }else{
      self.slideSelectView.bottomLabel.text = nil;
      self.slideSelectView.backLeftLabel.text = nil;
      self.slideSelectView.backRightLabel.text = nil;
    }
    
    // Allow scrollview to begin animation before updating label sizes
   [self.slideSelectView performSelector:@selector(setNeedsLayout) withObject:self.slideSelectView afterDelay:0];
  }];
}

- (void)viewWillAppear:(BOOL)animated{
  [super viewWillAppear:animated];
  
}

- (void)viewWillLayoutSubviews{
  CGRect r = self.view.bounds;
  CGFloat slideSelectHeight = 60.0f;
  
  [self.slideSelectView setTop:CGRectGetMinY(r) bottom:slideSelectHeight];
  self.slideSelectView.width = CGRectGetWidth(r);
  [self.tableView setTop:slideSelectHeight bottom:CGRectGetMaxY(r)];
  self.tableView.width = CGRectGetWidth(r);
}

- (void)didReceiveMemoryWarning{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
  
  
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
  id object = [self.albumChartsForWeek objectAtIndex:indexPath.row];
  return [TCSAlbumArtistPlayCountCell heightForObject:object atIndexPath:indexPath tableView:tableView];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
  // If the object doesn't have an album URL yet, request it from the server then set it
  // (Kind of ugly, but RAC wasn't working inside the cell (managedobject?) for some reason
  TCSAlbumArtistPlayCountCell *albumChartCell = (TCSAlbumArtistPlayCountCell *)cell;
  WeeklyAlbumChart *albumChart = [self.albumChartsForWeek objectAtIndex:indexPath.row];
  if (albumChart.albumImageURL == nil) {
    [[self.lastFMClient fetchImageURLForWeeklyAlbumChart:albumChart] subscribeNext:^(NSString *albumImageURL) {
      [albumChartCell setImageURL:albumImageURL];
    }];
  }
}

#pragma mark - view getters

- (TCSSlideSelectView *)slideSelectView{
  if (!_slideSelectView){
    _slideSelectView = [[TCSSlideSelectView alloc] init];
  }
  return _slideSelectView;
}

- (UITableView *)tableView{
  if (!_tableView){
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.backgroundView = [[TCSInnerShadowView alloc] initWithColor:WHITE_SUBTLE shadowColor:GRAYCOLOR(210) shadowRadius:3.0f];
  }
  return _tableView;
}

@end
