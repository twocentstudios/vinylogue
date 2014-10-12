//
//  TCSUserNameViewController.m
//  vinylogue
//
//  Created by Christopher Trott on 2/21/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import "TCSUserNameViewController.h"

#import <ReactiveCocoa/ReactiveCocoa.h>
#import "TCSLastFMAPIClient.h"
#import "User.h"

@interface TCSUserNameViewController ()

@property (nonatomic, strong) UIImageView *logoImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UITextField *userNameField;
@property (nonatomic, strong) UILabel *notLoadingSymbolLabel;
@property (nonatomic, strong) UIImageView *loadingImageView;
@property (nonatomic, strong) UIBarButtonItem *doneBarButtonItem;

@property (atomic, strong) TCSLastFMAPIClient *lastFMClient;

@property (nonatomic) BOOL loading;

@end

@implementation TCSUserNameViewController

- (id)init{
  return [self initWithUserName:nil headerShowing:YES];
}

- (id)initWithHeaderShowing:(BOOL)showingHeader{
  return [self initWithUserName:nil headerShowing:showingHeader];
}

- (id)initWithUserName:(NSString *)userName headerShowing:(BOOL)showingHeader{
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    self.showHeader = showingHeader;
    self.userNameField.text = userName;
    self.userSignal = [RACSubject subject];
    self.lastFMClient = [TCSLastFMAPIClient client];
    
    // When navigation bar is present
    self.title = @"username";
  }
  return self;
}

- (void)loadView{
  self.view = [[UIView alloc] init];
  self.view.backgroundColor = WHITE_SUBTLE;
  
  self.logoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo"]];
  
  self.userNameField.delegate = self;
  
  if (self.showHeader){
    [self.view addSubview:self.logoImageView];
  }
  [self.view addSubview:self.titleLabel];
  [self.view addSubview:self.userNameField];
  
  self.doneBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doDone:)];
  self.navigationItem.rightBarButtonItem = self.doneBarButtonItem;
}

- (void)viewWillLayoutSubviews{
  CGRect r = self.view.bounds;
  
  // Set sizes
  [self.userNameField sizeToFit];
  self.userNameField.width = CGRectGetWidth(r);
  [self.titleLabel sizeToFit];
  
  // Set vertical position
  CGFloat d = 0;
  d += [self.topLayoutGuide length];
  d += 26.0f; // top margin
  
  if (self.showHeader){
    self.logoImageView.top = d;
    d += self.logoImageView.height;
    d += 20.0f; // logo <-> textField margin
  }
  
  self.userNameField.top = d;
  d += self.userNameField.height;
  d += 14.0f; // textField <-> titleLabel margin
  self.titleLabel.top = d;
  
  // Set horizontal position
  self.logoImageView.x = CGRectGetMidX(r);
  self.userNameField.left = CGRectGetMinX(r);
  self.titleLabel.x = CGRectGetMidX(r);
}

- (void)viewDidLoad{
  [super viewDidLoad];
	
  [[RACObserve(self, loading) distinctUntilChanged] subscribeNext:^(id x) {
    BOOL loading = [x boolValue];
    if (loading){
      [self.loadingImageView startAnimating];
      self.userNameField.leftView = self.loadingImageView;
      self.doneBarButtonItem.enabled = NO;
      self.userNameField.enabled = NO;
      self.titleLabel.text = @"validating user name...";
    }else{
      [self.loadingImageView stopAnimating];
      self.userNameField.leftView = self.notLoadingSymbolLabel;
      self.userNameField.enabled = YES;
      self.titleLabel.text = @"a last.fm username (ex. ybsc)";
    }
  }];
  
  [[RACObserve(self, editing) distinctUntilChanged] subscribeNext:^(id x) {
    BOOL editing = [x boolValue];
    if (editing){
      self.doneBarButtonItem.enabled = YES;
    }else{
      self.doneBarButtonItem.enabled = NO;
    }
  }];
}

- (void)didReceiveMemoryWarning{
  [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - private

- (void)doDone:(id)sender{
  self.loading = YES;
  [[[self.lastFMClient fetchUserForUserName:self.userNameField.text]
     deliverOn:[RACScheduler mainThreadScheduler]]
   subscribeNext:^(User *user) {
    [self.userSignal sendNext:user];
    [self.userSignal sendCompleted];
  } error:^(NSError *error) {
    [[[UIAlertView alloc] initWithTitle:@"Vinylogue" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    self.loading = NO;
  } completed:^{
    self.loading = NO;
  }];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField{
  self.editing = YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField{
  self.editing = NO;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
  [self doDone:textField];
  
  return YES;
}

#pragma mark - view getters

- (UILabel *)titleLabel{
  if (!_titleLabel){
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.font = FONT_AVN_ULTRALIGHT(17);
    _titleLabel.textColor = GRAYCOLOR(70);
    _titleLabel.backgroundColor = CLEAR;
  }
  return _titleLabel;
}

- (UITextField *)userNameField{
  if (!_userNameField){
    _userNameField = [[UITextField alloc] init];
    _userNameField.font = FONT_AVN_DEMIBOLD(60);
    _userNameField.textColor = BLUE_DARK;
    _userNameField.adjustsFontSizeToFitWidth = YES;
    _userNameField.minimumFontSize = 20;
    _userNameField.backgroundColor = BLACKA(0.05f);
    _userNameField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _userNameField.autocorrectionType = UITextAutocorrectionTypeNo;
    _userNameField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    _userNameField.keyboardAppearance = UIKeyboardAppearanceDefault;
    _userNameField.returnKeyType = UIReturnKeyDone;
    _userNameField.clearButtonMode = UITextFieldViewModeAlways;
    _userNameField.enablesReturnKeyAutomatically = YES;
    
    NSAttributedString *string = [[NSAttributedString alloc] initWithString:@"last.fm username" attributes:@{ NSFontAttributeName: FONT_AVN_ULTRALIGHT(30),
                                             NSForegroundColorAttributeName: WHITE, NSBackgroundColorAttributeName: CLEAR}];
    _userNameField.attributedPlaceholder = string;
    

    _userNameField.leftView = self.notLoadingSymbolLabel;
    _userNameField.leftViewMode = UITextFieldViewModeAlways;
    
  }
  return _userNameField;
}

- (UILabel *)notLoadingSymbolLabel{
  if (!_notLoadingSymbolLabel){
    _notLoadingSymbolLabel = [[UILabel alloc] init];
    _notLoadingSymbolLabel.text = @"♫";
    _notLoadingSymbolLabel.font = FONT_AVN_DEMIBOLD(50);
    _notLoadingSymbolLabel.textColor = GRAYCOLOR(160);
    _notLoadingSymbolLabel.textAlignment = NSTextAlignmentCenter;
    _notLoadingSymbolLabel.backgroundColor = CLEAR;
    [_notLoadingSymbolLabel sizeToFit];
    _notLoadingSymbolLabel.width += 20;
  }
  return _notLoadingSymbolLabel;
}

// Spinning record animation
- (UIImageView *)loadingImageView{
  if (!_loadingImageView){
    _loadingImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
    _loadingImageView.contentMode = UIViewContentModeCenter;
    NSMutableArray *animationImages = [NSMutableArray arrayWithCapacity:12];
    for (int i = 1; i < 13; i++){
      [animationImages addObject:[UIImage imageNamed:[NSString stringWithFormat:@"loading%02i", i]]];
    }
    [_loadingImageView setAnimationImages:animationImages];
    _loadingImageView.animationDuration = 0.5f;
    _loadingImageView.animationRepeatCount = 0;
  }
  return _loadingImageView;
}

@end
