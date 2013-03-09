//
//  TCSSlideSelectView.m
//  vinylogue
//
//  Created by Christopher Trott on 2/18/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import "TCSSlideSelectView.h"
#import "TCSInnerShadowView.h"

#import "ReactiveCocoa/UIControl+RACSignalSupport.h"
#import <EXTScope.h>

static CGFloat buttonAlpha = 0.3f;

@interface TCSSlideSelectView ()

@property (nonatomic, strong) UIView *backView;
@property (nonatomic, strong) UIButton *backLeftButton;
@property (nonatomic, strong) UIButton *backRightButton;
@property (nonatomic, strong) UILabel *backLeftLabel;
@property (nonatomic, strong) UILabel *backRightLabel;

@property (nonatomic, strong) UIScrollView *scrollView;

@property (nonatomic, strong) UIView *frontView;
@property (nonatomic, strong) UILabel *topLabel;
@property (nonatomic, strong) UILabel *bottomLabel;

@end

@implementation TCSSlideSelectView

- (id)init{
  self = [super initWithFrame:CGRectZero];
  if (self) {
    [self addSubview:self.backView];
    
    [self.backView addSubview:self.backLeftLabel];
    [self.backView addSubview:self.backRightLabel];
    
    [self.backView addSubview:self.scrollView];
    
    // Buttons technically sit above the scrollview in order to intercept touches
    [self.backView addSubview:self.backLeftButton];
    [self.backView addSubview:self.backRightButton];
    
    [self.scrollView addSubview:self.frontView];
    [self.frontView addSubview:self.topLabel];
    [self.frontView addSubview:self.bottomLabel];
    
    // Set up commands
    self.pullLeftOffset = 40;
    self.pullRightOffset = 40;
    self.pullLeftCommand = [RACCommand command];
    self.pullRightCommand = [RACCommand command];
  }
  return self;
}

- (void)layoutSubviews{
  [super layoutSubviews];
  
  CGRect r = self.bounds;
  
  // Size and position main subviews
  self.backView.frame = r;
  self.scrollView.frame = r;
  self.scrollView.contentSize = r.size;
  
  static CGFloat titleViewInset = 50.0f; // distance from left and right
  self.frontView.width = CGRectGetWidth(r) - titleViewInset * 2.0f;
  self.frontView.height = CGRectGetHeight(r);
  self.frontView.center = self.contentCenter;
  
  // Size and position backView subviews
  static CGFloat backButtonInset = 8.0f; // distance from edge
  self.backLeftButton.left = CGRectGetMinX(r) + backButtonInset;
  self.backLeftButton.y = CGRectGetMidY(r);
  self.backRightButton.right = CGRectGetMaxX(r) - backButtonInset;
  self.backRightButton.y = CGRectGetMidY(r);
  
  self.backLeftLabel.size = [self sizeForLabel:self.backLeftLabel];
  self.backRightLabel.size = [self sizeForLabel:self.backRightLabel];
  static CGFloat backLabelInset = 16.0f; // distance from backButton
  self.backLeftLabel.left = self.backLeftButton.right + backLabelInset;
  self.backLeftLabel.y = CGRectGetMidY(r);
  self.backRightLabel.right = self.backRightButton.left - backLabelInset;
  self.backRightLabel.y = CGRectGetMidY(r);
  
  // Size and position frontView subviews
  r = self.frontView.bounds;
  self.topLabel.size = [self sizeForLabel:self.topLabel];
  self.bottomLabel.size = [self sizeForLabel:self.bottomLabel];
  static CGFloat topLabelOffset = 2.0f; // distance from superview center to bottom of label
  static CGFloat bottomLabelOffset = -3.0f; // distance from superview center to top of label
  self.topLabel.bottom = CGRectGetMidY(r) - topLabelOffset;
  self.topLabel.x = CGRectGetMidX(r);
  self.bottomLabel.top = CGRectGetMidY(r) + bottomLabelOffset;
  self.bottomLabel.x = CGRectGetMidX(r);

}

- (CGSize)sizeForLabel:(UILabel *)label{
  return [label.text sizeWithFont:label.font constrainedToSize:label.superview.bounds.size lineBreakMode:NSLineBreakByWordWrapping];
}

# pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
  [self showBackButtons:NO];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{

}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
  //  DLog(@"ENDED DRAGGING at offset: %f", scrollView.contentOffset.x);
  CGFloat offset = scrollView.contentOffset.x;
  if (offset <= -self.pullLeftOffset){
    [self.pullLeftCommand execute:nil];
  }else if(offset >= self.pullRightOffset){
    [self.pullRightCommand execute:nil];
  }
  [self showBackButtons:YES];
}

# pragma mark - private

- (void)doLeftButton:(UIButton *)button{
  [self.pullLeftCommand execute:nil];
}

- (void)doRightButton:(UIButton *)button{
  [self.pullRightCommand execute:nil];
}

- (void)showBackButtons:(BOOL)showing{
  @weakify(self)
  [UIView animateWithDuration:0.25f animations:^{
    @strongify(self);
    self.backLeftButton.alpha = showing*buttonAlpha;
    self.backRightButton.alpha = showing*buttonAlpha;
  }];
}

# pragma mark - view getters

- (UIView *)backView{
  if (!_backView){
    _backView = (UIView *)[[TCSInnerShadowView alloc] initWithColor:BLUE_PERI shadowColor:BLUE_PERI_SHADOW shadowRadius:3];
  }
  return _backView;
}

- (UIScrollView *)scrollView{
  if (!_scrollView){
    _scrollView = [[UIScrollView alloc] init];
    _scrollView.scrollEnabled = YES;
    _scrollView.alwaysBounceHorizontal = YES;
    _scrollView.alwaysBounceVertical = NO;
    _scrollView.directionalLockEnabled = YES;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.scrollsToTop = NO;
    _scrollView.backgroundColor = [UIColor clearColor];
    _scrollView.decelerationRate = UIScrollViewDecelerationRateFast;
    _scrollView.delegate = self;
  }
  return _scrollView;
}

- (UIView *)frontView{
  if (!_frontView){
    _frontView = [UIView viewWithDrawRectBlock:^(CGRect rect) {
      CGContextRef c = UIGraphicsGetCurrentContext();
      CGRect r = rect;
      
      CGContextSaveGState(c);
      {
        CGFloat cornerRadius = 14.0f;
        UIBezierPath *roundedPath = [UIBezierPath bezierPathWithRoundedRect:r cornerRadius:cornerRadius];
        CGContextAddPath(c, roundedPath.CGPath);
        CGContextClip(c);
        
        // Fill background
        [BLUE_PERI setFill];
        CGContextFillRect(c, r);
        
//        CGFloat borderWidth = 1.0f;
//        CGRect leftBorder = CGRectMake(CGRectGetMinX(r), CGRectGetMinY(r), borderWidth, CGRectGetHeight(r));
//        CGRect rightBorder = CGRectMake(CGRectGetMaxX(r)-borderWidth, CGRectGetMinY(r), borderWidth, CGRectGetHeight(r));
//        
//        // Fill left & right borders
//        [RGBCOLOR(0, 47, 18) setFill];
//        CGContextFillRect(c, leftBorder);
//        CGContextFillRect(c, rightBorder);
        
      }
      CGContextRestoreGState(c);
    }];
    
    _frontView.opaque = NO;
    _frontView.clipsToBounds = NO;
    _frontView.layer.masksToBounds = NO;
    CALayer *layer = _frontView.layer;
    layer.shadowColor = [BLUE_PERI_SHADOW CGColor];
    layer.shadowOffset = CGSizeMake(0, 0);
    layer.shadowOpacity = 1.0f;
    layer.shadowRadius = 1.5;
    layer.cornerRadius = 4.0f;
  }
  return _frontView;
}

- (UIButton *)backLeftButton{
  if (!_backLeftButton){
    _backLeftButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_backLeftButton setImage:[UIImage imageNamed:@"leftArrow"] forState:UIControlStateNormal];
    _backLeftButton.showsTouchWhenHighlighted = YES;
    _backLeftButton.alpha = buttonAlpha;
    _backLeftButton.size = CGSizeMake(30, 30);
    [_backLeftButton addTarget:self action:@selector(doLeftButton:) forControlEvents:UIControlEventTouchUpInside];
  }
  return _backLeftButton;
}

- (UIButton *)backRightButton{
  if (!_backRightButton){
    _backRightButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_backRightButton setImage:[UIImage imageNamed:@"rightArrow"] forState:UIControlStateNormal];
    _backRightButton.showsTouchWhenHighlighted = YES;
    _backRightButton.alpha = buttonAlpha;
    _backRightButton.size = CGSizeMake(30, 30);
    [_backRightButton addTarget:self action:@selector(doRightButton:) forControlEvents:UIControlEventTouchUpInside];
  }
  return _backRightButton;
}

- (UILabel *)backLeftLabel{
  if (!_backLeftLabel){
    _backLeftLabel = [[UILabel alloc] init];
    _backLeftLabel.backgroundColor = CLEAR;
    _backLeftLabel.font = FONT_AVN_MEDIUM(18);
    _backLeftLabel.textColor = WHITE_SUBTLE;
  }
  return _backLeftLabel;
}

- (UILabel *)backRightLabel{
  if (!_backRightLabel){
    _backRightLabel = [[UILabel alloc] init];
    _backRightLabel.backgroundColor = CLEAR;
    _backRightLabel.font = FONT_AVN_MEDIUM(18);
    _backRightLabel.textColor = WHITE_SUBTLE;
  }
  return _backRightLabel;
}

- (UILabel *)topLabel{
  if (!_topLabel){
    _topLabel = [[UILabel alloc] init];
    _topLabel.backgroundColor = CLEAR;
    _topLabel.font = FONT_AVN_ULTRALIGHT(18);
    _topLabel.textColor = BLACKA(0.5f);
    _topLabel.userInteractionEnabled = YES;
  }
  return _topLabel;
}

- (UILabel *)bottomLabel{
  if (!_bottomLabel){
    _bottomLabel = [[UILabel alloc] init];
    _bottomLabel.backgroundColor = CLEAR;
    _bottomLabel.font = FONT_AVN_MEDIUM(19);
    _bottomLabel.textColor = GRAYCOLOR(120);
    _bottomLabel.userInteractionEnabled = YES;
  }
  return _bottomLabel;
}

@end
