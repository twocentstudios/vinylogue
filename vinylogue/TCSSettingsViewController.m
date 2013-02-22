//
//  TCSSettingsViewController.m
//  vinylogue
//
//  Created by Christopher Trott on 2/21/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import "TCSSettingsViewController.h"

#import "TCSUserNameViewController.h"

#import "TCSSimpleTableDataSource.h"
#import "TCSSettingsCells.h"

#import <ReactiveCocoa/ReactiveCocoa.h>
#import <EXTScope.h>

@interface TCSSettingsViewController ()

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic) NSUInteger playCountFilter;

@property (nonatomic, strong) TCSSimpleTableDataSource *dataSource;

@end

@implementation TCSSettingsViewController

- (id)initWithPlayCountFilter:(NSUInteger)playCountFilter{
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    self.playCountFilter = playCountFilter;
    
    self.playCountFilterSignal = [RACSubject subject];
        
    // When navigation bar is present
    self.title = @"settings";
  }
  return self;
}

- (void)loadView{
  self.view = [[UIView alloc] init];
  [self.view addSubview:self.tableView];
}

- (void)viewDidLoad{
  [super viewDidLoad];
  
  @weakify(self);
  
  [[RACAble(self.playCountFilter) distinctUntilChanged] subscribeNext:^(NSNumber *playCountFilter) {
    @strongify(self);
    [[NSUserDefaults standardUserDefaults] setObject:playCountFilter forKey:kTCSUserDefaultsPlayCountFilter];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.playCountFilterSignal sendNext:playCountFilter];
  }];
}

- (void)viewWillLayoutSubviews{
  self.tableView.frame = self.view.bounds;
}

- (void)viewWillAppear:(BOOL)animated{
  [super viewWillAppear:animated];
  
  NSArray *tableLayout = @[ @{ kTCSimpleTableTypeKey: kTCSimpleTableHeaderKey,
                               kTCSimpleTableTitle: @"play count filter" },
                            @{ kTCSimpleTableTypeKey: kTCSimpleTableCellKey,
                               kTCSimpleTableTitle: [self stringForPlays],
                               kTCSimpleTableSelector: @"doSetFilter:" },
                            @{ kTCSimpleTableTypeKey: kTCSimpleTableHeaderKey,
                               kTCSimpleTableTitle: @"support" },
                            @{ kTCSimpleTableTypeKey: kTCSimpleTableCellKey,
                               kTCSimpleTableTitle: @"report an issue",
                               kTCSimpleTableSelector: @"doReportIssue" },
                            @{ kTCSimpleTableTypeKey: kTCSimpleTableCellKey,
                               kTCSimpleTableTitle: @"rate on appstore",
                               kTCSimpleTableSelector: @"doRate" },
                            @{ kTCSimpleTableTypeKey: kTCSimpleTableCellKey,
                               kTCSimpleTableTitle: @"licenses",
                               kTCSimpleTableSelector: @"doViewLicenses" },
                            @{ kTCSimpleTableTypeKey: kTCSimpleTableHeaderKey,
                               kTCSimpleTableTitle: @"about" },
                            @{ kTCSimpleTableTypeKey: kTCSimpleTableCellKey,
                               kTCSimpleTableTitle: @"twocentstudios.com",
                               kTCSimpleTableSelector: @"doDeveloperWebsite" },
                            @{ kTCSimpleTableTypeKey: kTCSimpleTableCellKey,
                               kTCSimpleTableTitle: @"@twocentstudios",
                               kTCSimpleTableSelector: @"doDeveloperTwitter" }
                            ];
  
  self.dataSource = [[TCSSimpleTableDataSource alloc] initWithTableLayout:tableLayout controller:self];
  self.dataSource.cellClass = [TCSSettingsCell class];
  self.dataSource.tableHeaderViewClass = [TCSSettingsHeaderCell class];
  self.dataSource.tableFooterViewClass = [TCSSettingsFooterCell class];
  self.dataSource.headerVerticalMargin = 10;
  self.dataSource.footerVerticalMargin = 8;
  self.dataSource.cellVerticalMargin = 7;
  self.tableView.dataSource = self.dataSource;
  self.tableView.delegate = self.dataSource;
  [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - actions

- (void)doSetFilter:(UITableViewCell *)cell{
  if (self.playCountFilter > 31){
    self.playCountFilter = 0;
  }else if(self.playCountFilter == 0){
    self.playCountFilter = 1;
  }else{
    self.playCountFilter *= 2;
  }
  cell.textLabel.text = [self stringForPlays];
}

- (void)doReportIssue{
  
}

- (void)doViewLicense{
  
}

- (void)doDeveloperWebsite{
  
}

- (void)doDeveloperTwitter{
  
}

#pragma mark - private

- (NSString *)stringForPlays{
  if (self.playCountFilter == 0){
    return @"off";
  }else if (self.playCountFilter == 1){
    return @"1 play";
  }else{
    return [NSString stringWithFormat:@"%i plays", self.playCountFilter];
  }
}

#pragma mark - view getters

- (UITableView *)tableView{
  if (!_tableView){
    _tableView = [[UITableView alloc] init];
    _tableView.backgroundColor = WHITE_SUBTLE;
    _tableView.scrollsToTop = NO;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
  }
  return _tableView;
}

@end
