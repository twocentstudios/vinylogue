//
//  TCSSettingsViewController.m
//  vinylogue
//
//  Created by Christopher Trott on 2/21/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import "TCSSettingsViewController.h"

#import "TCSSimpleTableDataSource.h"
#import "TCSSettingsCells.h"

@interface TCSSettingsViewController ()

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) NSString *userName;
@property (nonatomic) NSUInteger playCountFilter;

@property (nonatomic, strong) TCSSimpleTableDataSource *dataSource;

@end

@implementation TCSSettingsViewController

- (id)initWithUserName:(NSString *)userName playCountFilter:(NSUInteger)playCountFilter{
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    self.userName = userName;
    self.playCountFilter = playCountFilter;
        
    // When navigation bar is present
    self.title = @"settings";
  }
  return self;
}

- (void)loadView{
  self.view = [[UIView alloc] init];
  [self.view addSubview:self.tableView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewWillLayoutSubviews{
  self.tableView.frame = self.view.bounds;
}

- (void)viewWillAppear:(BOOL)animated{
  [super viewWillAppear:animated];
  
  NSArray *tableLayout = @[ @{ kTCSimpleTableTypeKey: kTCSimpleTableHeaderKey,
                               kTCSimpleTableTitle: @"last.fm username" },
                            @{ kTCSimpleTableTypeKey: kTCSimpleTableCellKey,
                               kTCSimpleTableTitle: self.userName,
                               kTCSimpleTableSelector: @"doSetUserName" },
                            @{ kTCSimpleTableTypeKey: kTCSimpleTableHeaderKey,
                               kTCSimpleTableTitle: @"play count filter" },
                            @{ kTCSimpleTableTypeKey: kTCSimpleTableCellKey,
                               kTCSimpleTableTitle: [NSString stringWithFormat:@"< %i plays", self.playCountFilter],
                               kTCSimpleTableSelector: @"doSetFilter" },
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

#pragma mark - view getters

- (UITableView *)tableView{
  if (!_tableView){
    _tableView = [[UITableView alloc] init];
    _tableView.backgroundColor = CLEAR;
    _tableView.backgroundView = nil;
    _tableView.scrollsToTop = NO;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
  }
  return _tableView;
}

@end
