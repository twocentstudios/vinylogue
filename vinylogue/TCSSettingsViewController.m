//
//  TCSSettingsViewController.m
//  vinylogue
//
//  Created by Christopher Trott on 2/21/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import "TCSSettingsViewController.h"

#import "TCSUserNameViewController.h"
#import "TCSSinglePageWebViewController.h"
#import <MessageUI/MessageUI.h>
#import <StoreKit/StoreKit.h>

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
                               kTCSimpleTableSelector: @"doDeveloperTwitter" },
                            @{ kTCSimpleTableTypeKey: kTCSimpleTableHeaderKey,
                               kTCSimpleTableTitle: @"artist & album data" },
                            @{ kTCSimpleTableTypeKey: kTCSimpleTableCellKey,
                               kTCSimpleTableTitle: @"last.fm",
                               kTCSimpleTableSelector: @"doLastFMWebsite" }
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
  if ([MFMailComposeViewController canSendMail]){
    MFMailComposeViewController *mailVC = [[MFMailComposeViewController alloc] init];
    [mailVC setMailComposeDelegate:self];
    [mailVC setToRecipients:@[@"support@twocentstudios.com"]];
    [mailVC setSubject:@"vinylogue: Support Request"];
    
    NSString *messageBody =
    [NSString stringWithFormat:@"\n\n\n\n-------------------\nDEBUG INFO:\nApp Version: %@\nApp Build: %@\nDevice: %@\nOS Version: %@", [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)@"CFBundleShortVersionString"],
     [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey],
     [[UIDevice currentDevice] model],
     [[UIDevice currentDevice] systemVersion]];
    
    [mailVC setMessageBody:messageBody isHTML:NO];
    [self presentViewController:mailVC animated:YES completion:NULL];
  }else{
    DLog(@"Mail unsupported");
  }
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error{
  if (result == MFMailComposeResultSent){
    DLog(@"Mail sent");
  }else if(result == MFMailComposeResultSaved){
    DLog(@"Mail saved");
  }else if(result == MFMailComposeResultFailed){
    DLog(@"Mail sending failed");
  }
  [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)doRate{
  NSString *urlString = @"http://appstore.com/vinylogue-for-last.fm";
  
  if (NSStringFromClass([SKStoreProductViewController class]) != nil) {
    SKStoreProductViewController *storeVC = [[SKStoreProductViewController alloc] init];
    NSNumber *appId = [NSNumber numberWithInteger:617471119];
    [storeVC loadProductWithParameters:@{SKStoreProductParameterITunesItemIdentifier:appId} completionBlock:nil];
    [self presentViewController:storeVC animated:YES completion:NULL];
    storeVC.delegate = self;
  }else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:urlString]]){
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
  }else{
    DLog(@"Error opening url");
  }
}

- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController{
  [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)doViewLicenses{
  TCSSinglePageWebViewController *webVC = [[TCSSinglePageWebViewController alloc] initWithLocalHTMLFileName:@"licenses"];
  [self presentViewController:webVC animated:YES completion:NULL];
}

- (void)doDeveloperWebsite{
  NSString *urlString = @"http://twocentstudios.com";
  if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:urlString]]){
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
  }
}

- (void)doDeveloperTwitter{
  NSString *urlString = @"http://twitter.com/twocentstudios";
  if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:urlString]]){
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
  }
}

- (void)doLastFMWebsite{
  NSString *urlString = @"http://last.fm";
  if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:urlString]]){
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
  }
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
