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
#import "User.h"
#import "TCSSettingsCells.h"

#import "UILabel+TCSLabelSizeCalculations.h"

#import <ReactiveCocoa/ReactiveCocoa.h>
#import <EXTScope.h>


// TEMP
#import "TCSLastFMAPIClient.h"

@interface TCSFavoriteUsersViewController ()

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIBarButtonItem *settingsButton;

@property (nonatomic, strong) UIView *footerContainerView;
@property (nonatomic, strong) UIButton *addFriendButton;
@property (nonatomic, strong) UIButton *importButton;
@property (nonatomic, strong) UILabel *friendHintLabel;

@property (nonatomic) NSUInteger playCountFilter;
@property (nonatomic, strong) TCSUserStore *userStore; // array of strings

@property (nonatomic) BOOL hidingFooterView;

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
  
  [self.footerContainerView addSubview:self.addFriendButton];
  [self.footerContainerView addSubview:self.importButton];
  [self.footerContainerView addSubview:self.friendHintLabel];
  [self.tableView setTableFooterView:self.footerContainerView];
  [self showOrHideTableFooter:NO];
  
  UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
  [button setImage:[UIImage imageNamed:@"settings"] forState:UIControlStateNormal];
  [button addTarget:self action:@selector(doSettings:) forControlEvents:UIControlEventTouchUpInside];
  button.adjustsImageWhenHighlighted = YES;
  button.showsTouchWhenHighlighted = YES;
  button.size = CGSizeMake(40, 40);
  self.settingsButton = [[UIBarButtonItem alloc] initWithCustomView:button];
  self.navigationItem.leftBarButtonItem = self.settingsButton;
    
   self.navigationItem.rightBarButtonItem = self.editButtonItem;
  
  UIBarButtonItem *backButton = [[UIBarButtonItem alloc] init];
  self.navigationItem.backBarButtonItem = backButton;
}

- (void)viewDidLoad{
  [super viewDidLoad];
  
  @weakify(self);
  
  // Prompts for a user name if it's nil (Should only be needed for first run)
  [[[RACAbleWithStart(self.userStore.user) distinctUntilChanged] filter:^BOOL(id value) {
    return (value == nil);
  }] subscribeNext:^(id x) {
    @strongify(self);
    TCSUserNameViewController *userNameController = [[TCSUserNameViewController alloc] initWithHeaderShowing:YES];
    [userNameController.userSignal subscribeNext:^(User *user) {
      @strongify(self);
      [self.userStore setUser:user];
    }completed:^{
      [userNameController dismissViewControllerAnimated:YES completion:NULL];
    }];
    [self presentViewController:userNameController animated:NO completion:NULL];
  }];
  
}

- (void)viewWillLayoutSubviews{
  CGRect r = self.view.bounds;
  CGFloat w = CGRectGetWidth(r);
  self.tableView.frame = r;
  
  const CGFloat buttonWidth = w/2.0f;
  const CGFloat viewHMargin = 20.0f;
  const CGFloat viewVMargin = 20.0f;
  const CGFloat labelWidth = w - (viewHMargin * 2);
  self.footerContainerView.width = w;
  self.addFriendButton.width = buttonWidth;
  self.importButton.width = buttonWidth;
  [self.friendHintLabel setMultipleLineSizeForWidth:labelWidth];
  
  CGFloat l = CGRectGetMinX(self.footerContainerView.bounds);
  self.addFriendButton.left = l;
  l += self.addFriendButton.width;
  self.importButton.left = l;
  l += self.importButton.width;
  
  self.friendHintLabel.x = CGRectGetMidX(r);

  CGFloat t = CGRectGetMinY(self.footerContainerView.bounds);
  self.addFriendButton.top = t;
  self.importButton.top = t;
  t += self.addFriendButton.height;
  self.friendHintLabel.top = t;
  t += self.friendHintLabel.height;
  t += viewVMargin;
  
  self.footerContainerView.height = t;
  // set the table footer view after we've set the height
  // so that the table can set its contentSize correctly
  [self.tableView setTableFooterView:self.footerContainerView];
}

- (void)viewWillAppear:(BOOL)animated{
  [super viewWillAppear:animated];
  
  [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated{
  [super viewDidAppear:animated];
  
  // Ugly hack to get rid of automatically added bottom borders
//  [self removeStupidTableHeaderBorders];
}

- (void)didReceiveMemoryWarning{
  [super didReceiveMemoryWarning];

}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated{
  [super setEditing:editing animated:animated];
  [self.tableView setEditing:editing animated:animated];
  [self showOrHideTableFooter:YES];
}

#pragma mark - private

- (void)showOrHideTableFooter:(BOOL)animated{
  BOOL wasHidingFooterView = self.hidingFooterView;
  self.hidingFooterView = !((self.editing == YES) || (self.userStore.friendsCount == 0));
  if (wasHidingFooterView == self.hidingFooterView){
    return;
  }else{
    @weakify(self);
    [UIView animateWithDuration:(animated ? 0.4 : 0) animations:^{
      @strongify(self);
      self.footerContainerView.hidden = NO;
      self.footerContainerView.alpha = (float)!self.hidingFooterView;
    }];
  }
}

- (void)removeStupidTableHeaderBorders{
  NSArray *allTableViewSubviews = [self.tableView subviews];
  for (UIView *view in allTableViewSubviews){
    if ([view isKindOfClass:[TCSSettingsHeaderCell class]]){
      for (UIView *subview in [view subviews]){
        if (subview.height == 1){
          [subview removeFromSuperview];
        }
      }
    }
  }
  [self.tableView setNeedsDisplay];
}

- (NSString *)userNameForIndexPath:(NSIndexPath *)indexPath{
  User *user = [self userForIndexPath:indexPath];
  if (user){
    return user.userName;
  }else{
    return @"";
  }
}

- (User *)userForIndexPath:(NSIndexPath *)indexPath{
  User *user;
  if (indexPath.section == 0){
    user = [self.userStore user];
  }else if (indexPath.section == 1){
    user = [self.userStore friendAtIndex:indexPath.row];
  }else{
    user = nil;
    NSAssert(NO, @"Outside of section bounds");
  }
  return user;
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

- (void)doAddFriend:(id)button{
  @weakify(self);
  TCSUserNameViewController *userNameController = [[TCSUserNameViewController alloc] initWithUserName:nil headerShowing:NO];
  [[[[userNameController userSignal]
     distinctUntilChanged]
    filter:^BOOL(id x) {
      return (x != nil);
    }]
   subscribeNext:^(User *user) {
     @strongify(self);
     [self.userStore addFriend:user];
   }completed:^{
     [self.navigationController popViewControllerAnimated:YES];
   }];
  [self.navigationController pushViewController:userNameController animated:YES];

}

- (void)doImportFriends:(id)button{
  TCSLastFMAPIClient *client = [TCSLastFMAPIClient clientForUser:self.userStore.user];
  [[[client fetchFriends] deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(NSArray *friends) {
    [self.userStore addFriends:friends];
    [self.tableView reloadData];
  }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
  return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
  if (section == 0){
    return 1;
  }else if (section == 1){
    [self showOrHideTableFooter:YES];
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

  User *user = [self userForIndexPath:indexPath];

  if (!self.editing){
    TCSWeeklyAlbumChartViewController *albumChartController = [[TCSWeeklyAlbumChartViewController alloc] initWithUser:user playCountFilter:self.playCountFilter];
    [self.navigationController pushViewController:albumChartController animated:YES];
  }else{    
    TCSUserNameViewController *userNameController = [[TCSUserNameViewController alloc] initWithUserName:user.userName headerShowing:NO];
    @weakify(self);
    [[userNameController userSignal] subscribeNext:^(User *user){
      @strongify(self);
      if (indexPath.section == 0){
        [self.userStore setUser:user];
      }else{
        [self.userStore replaceFriendAtIndex:indexPath.row withFriend:user];
      }
    }completed:^{
      [self.navigationController popViewControllerAnimated:YES];
    }];
    [self.navigationController pushViewController:userNameController animated:YES];
  }
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
    _tableView.allowsSelectionDuringEditing = YES;
  }
  return _tableView;
}

- (UIView *)footerContainerView{
  if (!_footerContainerView){
    _footerContainerView = [[UIView alloc] init];
    _footerContainerView.hidden = YES;
    self.hidingFooterView = YES;
  }
  return _footerContainerView;
}

- (UIButton *)addFriendButton{
  if (!_addFriendButton){
    _addFriendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_addFriendButton addTarget:self action:@selector(doAddFriend:) forControlEvents:UIControlEventTouchUpInside];
    [_addFriendButton setTitle:@"add a friend" forState:UIControlStateNormal];
    [_addFriendButton setTitleColor:BLUE_DARK forState:UIControlStateNormal];
    [_addFriendButton setShowsTouchWhenHighlighted:YES];
    _addFriendButton.titleLabel.font = FONT_AVN_ULTRALIGHT(18);
    _addFriendButton.backgroundColor = CLEAR;
    _addFriendButton.height = 50;
  }
  return _addFriendButton;
}

- (UIButton *)importButton{
  if (!_importButton){
    _importButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_importButton addTarget:self action:@selector(doImportFriends:) forControlEvents:UIControlEventTouchUpInside];
    [_importButton setTitle:@"import friends" forState:UIControlStateNormal];
    [_importButton setTitleColor:BLUE_DARK forState:UIControlStateNormal];
    [_importButton setShowsTouchWhenHighlighted:YES];
    _importButton.titleLabel.font = FONT_AVN_ULTRALIGHT(18);
    _importButton.backgroundColor = CLEAR;
    _importButton.height = 50;
  }
  return _importButton;
}

- (UILabel *)friendHintLabel{
  if (!_friendHintLabel){
    _friendHintLabel = [[UILabel alloc] init];
    _friendHintLabel.numberOfLines = 0;
    _friendHintLabel.backgroundColor = CLEAR;
    _friendHintLabel.font = FONT_AVN_REGULAR(12);
    _friendHintLabel.textColor = COLORA(BLUE_DARK, 0.4);
    _friendHintLabel.textAlignment = NSTextAlignmentCenter;
    _friendHintLabel.text = @"your vinylogue friend list is kept separate\nfrom your last.fm friends list\n\n'import' will add only your last.fm friends\nnot already in this list";
  }
  return _friendHintLabel;
}


@end
