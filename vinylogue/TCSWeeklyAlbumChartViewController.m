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

@interface TCSWeeklyAlbumChartViewController ()

@property (nonatomic, retain) TCSLastFMAPIClient *lastFMClient;
@property (nonatomic, retain) NSArray *weeklyCharts;
@property (nonatomic, retain) NSArray *albumChartsForWeek;

@property (nonatomic, retain) NSDate *now;
@property (nonatomic, retain) NSDate *displayingDate;
@property (nonatomic) NSUInteger displayingYearsAgo;
@property (nonatomic, retain) WeeklyChart *displayingWeeklyChart;

@end

@implementation TCSWeeklyAlbumChartViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad{
  [super viewDidLoad];

  self.title = NSLocalizedString(@"Weekly Chart List", nil);
  
  self.lastFMClient = [TCSLastFMAPIClient clientForUserName:@"ybsc"];
  
  @weakify(self);
//  RAC(self.now) = [RACSignal interval:60 * 60]; // update every hour

  RAC(self.displayingDate) = [[RACSignal combineLatest:@[ RACAble(self.now), RACAble(self.displayingYearsAgo) ] reduce:^(NSDate *now, NSNumber *displayingYearsAgo){
    // Naive way of getting 365 days worth of seconds ago
    return [now dateByAddingTimeInterval:-1*365*24*60*60*[displayingYearsAgo doubleValue]];
  }] filter:^BOOL(id x) {
    return (x != nil);
  }];
  
  RAC(self.weeklyCharts) = [self.lastFMClient fetchWeeklyChartList];
  RAC(self.displayingWeeklyChart) =
  [[RACSignal combineLatest:@[ RACAble(self.weeklyCharts), RACAble(self.displayingDate)]]
   map:^id(RACTuple *t) {
     NSArray *weeklyCharts = t.first;
     NSDate *displayingDate = t.second;
     return [[weeklyCharts.rac_sequence
              filter:^BOOL(WeeklyChart *weeklyChart) {
                return (([weeklyChart.from compare:displayingDate] == NSOrderedAscending) && ([weeklyChart.to compare:displayingDate] == NSOrderedDescending));
              }] head];
   }];
  
  [[RACAble(self.displayingWeeklyChart) filter:^BOOL(id x) {
    return (x != nil);
  }] subscribeNext:^(WeeklyChart *displayingWeeklyChart) {
    @strongify(self);
    [[self.lastFMClient fetchWeeklyAlbumChartForChart:displayingWeeklyChart] subscribeNext:^(NSArray *albumChartsForWeek) {
      @strongify(self);
      self.albumChartsForWeek = albumChartsForWeek;
    }];
  }];
  
  [[RACAble(self.albumChartsForWeek) deliverOn:[RACScheduler mainThreadScheduler]]
   subscribeNext:^(id x){
    [self.tableView reloadData];
  }];
  
  self.now = [NSDate date];
  self.displayingYearsAgo = 1;
  
}

- (void)didReceiveMemoryWarning{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
  
  self.displayingYearsAgo += 1;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
  return [self.albumChartsForWeek count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
  static NSString *CellIdentifier = @"Cell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (!cell) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
  }
  
  WeeklyAlbumChart *albumChart = [self.albumChartsForWeek objectAtIndex:indexPath.row];
  cell.textLabel.text = albumChart.artistName;
  cell.detailTextLabel.text = albumChart.albumName;
  
  return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    // Navigation logic may go here. Create and push another view controller.
    /*
      *detailViewController = [[ alloc] initWithNibName:@"" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

@end
