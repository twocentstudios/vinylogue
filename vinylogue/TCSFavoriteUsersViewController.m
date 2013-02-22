//
//  TCSFavoriteUsersViewController.m
//  vinylogue
//
//  Created by Christopher Trott on 2/22/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import "TCSFavoriteUsersViewController.h"

#import "TCSUserNameViewController.h"
#import "TCSSettingsViewController.h"
#import "TCSWeeklyAlbumChartViewController.h"

#import "TCSSimpleTableDataSource.h"
#import "TCSUserStore.h"
#import "TCSSettingsCells.h"

#import <ReactiveCocoa/ReactiveCocoa.h>
#import <EXTScope.h>

@interface TCSFavoriteUsersViewController ()

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIBarButtonItem *settingsButton;
@property (nonatomic, strong) UIBarButtonItem *addButton;

@property (nonatomic, strong) NSString *userName;
@property (nonatomic) NSUInteger playCountFilter;
@property (nonatomic, strong) TCSUserStore *userStore; // array of strings

@end

@implementation TCSFavoriteUsersViewController

- (id)initWithUserStore:(TCSUserStore *)userStore playCountFilter:(NSUInteger)playCountFilter{
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    self.playCountFilter = playCountFilter;
    self.userStore = userStore;
    
    // When navigation bar is present
    self.title = @"scrobblers";
  }
  return self;
}

- (void)loadView{
  self.view = [[UIView alloc] init];
  [self.view addSubview:self.tableView];
  
  UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
  [button setImage:[UIImage imageNamed:@"settings"] forState:UIControlStateNormal];
  [button addTarget:self action:@selector(doSettings:) forControlEvents:UIControlEventTouchUpInside];
  button.adjustsImageWhenHighlighted = YES;
  button.showsTouchWhenHighlighted = YES;
  button.size = CGSizeMake(40, 40);
  self.settingsButton = [[UIBarButtonItem alloc] initWithCustomView:button];
  self.navigationItem.leftBarButtonItem = self.settingsButton;
  
  self.addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(doAddFriend:)];
  self.addButton.tintColor = BAR_BUTTON_TINT;
  
  self.editButtonItem.tintColor = BAR_BUTTON_TINT;
  self.navigationItem.rightBarButtonItem = self.editButtonItem;
  
  UIBarButtonItem *backButton = [[UIBarButtonItem alloc] init];
  backButton.tintColor = BAR_BUTTON_TINT;
  self.navigationItem.backBarButtonItem = backButton;
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
  
  [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated{
  [super viewDidAppear:animated];
  
  // Ugly hack to get rid of automatically added bottom borders
  [self removeStupidTableHeaderBorders];
}

- (void)didReceiveMemoryWarning{
  [super didReceiveMemoryWarning];

}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated{
  [super setEditing:editing animated:animated];
  [self.tableView setEditing:editing animated:animated];
  if (editing){
    self.navigationItem.leftBarButtonItem = self.addButton;
  }else{
    self.navigationItem.leftBarButtonItem = self.settingsButton;
  }
}

#pragma mark - private

- (void)removeStupidTableHeaderBorders{
  NSArray *allTableViewSubviews = [self.tableView subviews];
  for (UIView *view in allTableViewSubviews){
    if ([view isKindOfClass:[TCSSettingsHeaderCell class]]){
      [[[view subviews] lastObject] removeFromSuperview];
    }
  }
  [self.tableView setNeedsDisplay];
}

- (NSString *)userNameForIndexPath:(NSIndexPath *)indexPath{
  NSString *userName;
  if (indexPath.section == 0){
    userName = [self.userStore userName];
  }else if (indexPath.section == 1){
    userName = [self.userStore friendAtIndex:indexPath.row];
  }else{
    userName = @"";
    NSAssert(NO, @"Outside of section bounds");
  }
  return userName;
}

- (NSString *)titleForHeaderInSection:(NSInteger)section{
  if (section == 0){
    return @"me";
  }else{
    return @"friends";
  }
}

#pragma mark - actions

- (void)doSettings:(UIBarButtonItem *)button{
  @weakify(self);
  TCSSettingsViewController *settingsViewController = [[TCSSettingsViewController alloc] initWithPlayCountFilter:self.playCountFilter];
  
  // Subscribe to the play count filter signal and set ours if it changes
  [[settingsViewController playCountFilterSignal] subscribeNext:^(NSNumber *playCountFilter) {
    @strongify(self);
    self.playCountFilter = [playCountFilter unsignedIntegerValue];
  }];
  [self.navigationController pushViewController:settingsViewController animated:YES];
}

- (void)doAddFriend:(UIBarButtonItem *)button{
  @weakify(self);
  TCSUserNameViewController *userNameViewController = [[TCSUserNameViewController alloc] initWithUserName:nil headerShowing:NO];
  [[[[userNameViewController userNameSignal]
     distinctUntilChanged]
    filter:^BOOL(id x) {
      return (x != nil);
    }]
   subscribeNext:^(NSString *userName) {
     @strongify(self);
     [self.userStore addFriendWithUserName:userName];
   }];
  [self.navigationController pushViewController:userNameViewController animated:YES];

}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
  return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
  if (section == 0){
    return 1;
  }else if (section == 1){
    return [self.userStore friendsCount];
  }else{
    return 0;
  }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
  
  Class cellClass;
  if (indexPath.section == 0){
    cellClass = [TCSBigSettingsCell class];
  }else{
    cellClass = [TCSSettingsCell class];
  }
  
  NSString *CellIdentifier = NSStringFromClass(cellClass);
  TCSSettingsCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (!cell) {
    cell = [[cellClass alloc] init];
  }
  
  NSString *userName = [self userNameForIndexPath:indexPath];
  [cell setTitleText:userName];
  cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
  
  return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
  return (indexPath.section == 1);
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath{
  return (indexPath.section == 1);
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath{
  [self.userStore moveFriendAtIndex:fromIndexPath.row toIndex:toIndexPath.row];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
  if (editingStyle == UITableViewCellEditingStyleDelete) {
		[self.userStore removeFriendAtIndex:indexPath.row];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
  }
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
  static CGFloat verticalMargin = 10;
  
  UIFont *font = [TCSSettingsHeaderCell font];
  NSString *title = [self titleForHeaderInSection:section];
  
  CGFloat textHeight = [title sizeWithFont:font constrainedToSize:CGSizeMake(tableView.width, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping].height;
  if (textHeight > 0){
    return textHeight + verticalMargin * 2;
  }else{
    return 0;
  }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
  NSString *title = [self titleForHeaderInSection:section];
  
  TCSSettingsHeaderCell *cell = [[TCSSettingsHeaderCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"header"];
  [cell setTitleText:title];
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  
  NSString *userName = [self userNameForIndexPath:indexPath];
  
  TCSWeeklyAlbumChartViewController *albumChartController = [[TCSWeeklyAlbumChartViewController alloc] initWithUserName:userName playCountFilter:self.playCountFilter];
  [self.navigationController pushViewController:albumChartController animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
  static CGFloat verticalMargin = 7;
  
  UIFont *font = [TCSSettingsCell font];
  NSString *userName = [self userNameForIndexPath:indexPath];
  
  CGFloat textHeight = [userName sizeWithFont:font constrainedToSize:CGSizeMake(tableView.width, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping].height;
  if (textHeight > 0){
    return textHeight + verticalMargin * 2;
  }else{
    return 0;
  }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{

}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath{
  NSString *userName = [self userNameForIndexPath:indexPath];
  
  TCSUserNameViewController *userNameController = [[TCSUserNameViewController alloc] initWithUserName:userName headerShowing:NO];
  @weakify(self);
  [[userNameController userNameSignal] subscribeNext:^(NSString *userName){
    @strongify(self);
    if (indexPath.section == 0){
      [self.userStore setUserName:userName];
    }else{
      [self.userStore replaceFriendAtIndex:indexPath.row withUserName:userName];
    }
  }];
  [self.navigationController pushViewController:userNameController animated:YES];
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath{
  // rows can't be moved to section 0
  if (proposedDestinationIndexPath.section == 0){
    return [NSIndexPath indexPathForRow:0 inSection:1];
  }
  return proposedDestinationIndexPath;
}

#pragma mark - view getters

- (UITableView *)tableView{
  if (!_tableView){
    _tableView = [[UITableView alloc] init];
    _tableView.backgroundColor = WHITE_SUBTLE;
    _tableView.scrollsToTop = NO;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.dataSource = self;
    _tableView.delegate = self;
  }
  return _tableView;
}

@end
