//
//  TCSUserNameViewController.m
//  vinylogue
//
//  Created by Christopher Trott on 2/21/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import "TCSUserNameViewController.h"

#import <ReactiveCocoa/ReactiveCocoa.h>

@interface TCSUserNameViewController ()

@property (nonatomic, strong) UIImageView *logoImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UITextField *userNameField;

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
    self.userNameSignal = [RACSubject subject];
    
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
}

- (void)viewWillLayoutSubviews{
  CGRect r = self.view.bounds;
  
  // Set sizes
  self.userNameField.height = [self heightForTextField:self.userNameField];
  self.userNameField.width = CGRectGetWidth(r);
  self.titleLabel.size = [self sizeForLabel:self.titleLabel];
  
  // Set vertical position
  CGFloat d = 0;
  d += 34.0f; // top margin
  
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
	
}

- (void)didReceiveMemoryWarning{
  [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
  [self.userNameSignal sendNext:textField.text];
  [self.userNameSignal sendCompleted];
  
  // Dismiss self
  if (self.presentingViewController){
    [self dismissViewControllerAnimated:YES completion:NULL];
  }
  if (self.navigationController){
    [self.navigationController popViewControllerAnimated:YES];
  }
  
  // Save to backing store
  [[NSUserDefaults standardUserDefaults] setObject:textField.text forKey:kTCSUserDefaultsLastFMUserName];
  [[NSUserDefaults standardUserDefaults] synchronize];
  
  return YES;
}

#pragma mark - view getters

- (CGSize)sizeForLabel:(UILabel *)label{
  return [label.text sizeWithFont:label.font constrainedToSize:label.superview.bounds.size lineBreakMode:NSLineBreakByWordWrapping];
}

- (CGFloat)heightForTextField:(UITextField *)textField{
  return [@"TEST" sizeWithFont:textField.font forWidth:self.view.width lineBreakMode:NSLineBreakByTruncatingTail].height;
}

- (UILabel *)titleLabel{
  if (!_titleLabel){
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.font = FONT_AVN_ULTRALIGHT(17);
    _titleLabel.textColor = GRAYCOLOR(70);
    _titleLabel.backgroundColor = CLEAR;
    _titleLabel.text = @"(yours or a friend's)";
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
    _userNameField.keyboardAppearance = UIKeyboardAppearanceAlert;
    _userNameField.returnKeyType = UIReturnKeyDone;
    _userNameField.clearButtonMode = UITextFieldViewModeAlways;
    _userNameField.enablesReturnKeyAutomatically = YES;
    
    NSAttributedString *string = [[NSAttributedString alloc] initWithString:@"last.fm username" attributes:@{ NSFontAttributeName: FONT_AVN_ULTRALIGHT(30),
                                             NSForegroundColorAttributeName: WHITE, NSBackgroundColorAttributeName: CLEAR}];
    _userNameField.attributedPlaceholder = string;
    
    UILabel *symbol = [[UILabel alloc] init];
    symbol.text = @"♫";
    symbol.font = FONT_AVN_DEMIBOLD(50);
    symbol.textColor = GRAYCOLOR(160);
    symbol.textAlignment = NSTextAlignmentCenter;
    symbol.backgroundColor = CLEAR;
    symbol.size = [symbol.text sizeWithFont:symbol.font];
    symbol.width += 20;
    _userNameField.leftView = symbol;
    _userNameField.leftViewMode = UITextFieldViewModeAlways;
    
  }
  return _userNameField;
}

@end
