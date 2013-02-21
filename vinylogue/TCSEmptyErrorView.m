//
//  TCSEmptyErrorView.m
//  vinylogue
//
//  Created by Christopher Trott on 2/20/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import "TCSEmptyErrorView.h"
#import "TCSStackedCenteredView.h"

@implementation TCSEmptyErrorView

+ (UIView *)errorViewWithTitle:(NSString *)title
                   actionTitle:(NSString *)actionTitle
                  actionTarget:(id)target
                actionSelector:(SEL)selector{
  UILabel *symbolLabel = [[UILabel alloc] init];
  symbolLabel.text = @"✕";
  [[self class] makeSymbolLabel:symbolLabel];
  
  UILabel *titleLabel = [[UILabel alloc] init];
  titleLabel.text = title;
  [[self class] makeMessageSubtitleLabel:titleLabel];
  
  UIButton *actionButton;
  if ((target != nil) && (selector != nil)){
    actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [actionButton setTitle:actionTitle forState:UIControlStateNormal];
    [actionButton addTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];
    [[self class] makeActionButton:actionButton];
  }

  TCSStackedCenteredView *stackView = [[TCSStackedCenteredView alloc] initWithTopHalfView:symbolLabel bottomMiddleView:titleLabel bottomView:actionButton];
  
  return stackView;
}


+ (UIView *)emptyViewWithTitle:(NSString *)title
                      subtitle:(NSString *)subtitle{
  UILabel *symbolLabel = [[UILabel alloc] init];
  symbolLabel.text = @"♫";
  [[self class] makeSymbolLabel:symbolLabel];
  
  UILabel *titleLabel = [[UILabel alloc] init];
  titleLabel.text = title;
  [[self class] makeMessageTitleLabel:titleLabel];
  
  UILabel *subtitleLabel = [[UILabel alloc] init];
  subtitleLabel.text = subtitle;
  [[self class] makeMessageSubtitleLabel:subtitleLabel];
  
  TCSStackedCenteredView *stackView = [[TCSStackedCenteredView alloc] initWithTopHalfView:symbolLabel bottomMiddleView:titleLabel bottomView:subtitleLabel];
  
  return stackView;
}

#pragma mark - Label generators

+ (void)makeSymbolLabel:(UILabel *)label{
  label.font = FONT_AVN_MEDIUM(100);
  label.numberOfLines = 1;
  label.textAlignment = NSTextAlignmentCenter;
  label.backgroundColor = CLEAR;
  label.textColor = BLUE_DARK;
  label.shadowColor = WHITE;
  label.shadowOffset = SHADOW_TOP;
  [[self class] resizeLabel:label];
}

+ (void)makeMessageTitleLabel:(UILabel *)label{
  label.font = FONT_AVN_MEDIUM(36);
  label.numberOfLines = 0;
  label.lineBreakMode = NSLineBreakByWordWrapping;
  label.textAlignment = NSTextAlignmentCenter;
  label.backgroundColor = CLEAR;
  label.textColor = BLUE_DARK;
  label.shadowColor = WHITE;
  label.shadowOffset = SHADOW_TOP;
  [[self class] resizeLabel:label];
}

+ (void)makeMessageSubtitleLabel:(UILabel *)label{
  label.font = FONT_AVN_ULTRALIGHT(13);
  label.numberOfLines = 0;
  label.lineBreakMode = NSLineBreakByWordWrapping;
  label.textAlignment = NSTextAlignmentCenter;
  label.backgroundColor = CLEAR;
  label.textColor = GRAYCOLOR(60);
  [[self class] resizeLabel:label];
}

+ (void)makeActionButton:(UIButton *)button{
  UILabel *label = [button titleLabel];
  label.font = FONT_AVN_DEMIBOLD(16);
  [button setTitleColor:WHITE_SUBTLE forState:UIControlStateNormal];
  [button setBackgroundImage:[[UIImage imageNamed:@"blueButton"] resizableImageWithCapInsets:UIEdgeInsetsMake(4, 4, 4, 4) resizingMode:UIImageResizingModeStretch] forState:UIControlStateNormal];
  button.reversesTitleShadowWhenHighlighted = YES;
  [button sizeToFit];
  button.height += 10.0f;
  button.width += 20.0f;
}

# pragma mark - Utilities

+ (void)resizeLabel:(UILabel *)label{
  static CGFloat width = 200;
  CGFloat height = [label.text sizeWithFont:label.font constrainedToSize:CGSizeMake(width, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping].height;
  label.frame = CGRectMake(0, 0, width, height);
}
@end
