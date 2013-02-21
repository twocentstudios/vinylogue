//
//  TCSSlideSelectView.m
//  vinylogue
//
//  Created by Christopher Trott on 2/18/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import "TCSSlideSelectView.h"
#import "TCSInnerShadowView.h"

@interface TCSSlideSelectView ()

@end

@implementation TCSSlideSelectView

- (id)init{
  self = [super initWithFrame:CGRectZero];
  if (self) {
    [self.backView addSubview:self.backLeftImageView];
    [self.backView addSubview:self.backRightImageView];
    [self.backView addSubview:self.backLeftLabel];
    [self.backView addSubview:self.backRightLabel];
    
    [self.frontView addSubview:self.topLabel];
    [self.frontView addSubview:self.bottomLabel];
    
    [self addSubview:self.backView];
    [self addSubview:self.scrollView];
    [self.scrollView addSubview:self.frontView];
    
    // Set up commands
    self.pullLeftOffset = 50;
    self.pullRightOffset = 50;
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
  
  CGFloat titleViewInset = 50.0f; // distance from left and right
  self.frontView.width = CGRectGetWidth(r) - titleViewInset * 2.0f;
  self.frontView.height = CGRectGetHeight(r);
  self.frontView.center = self.contentCenter;
  
  // Size and position backView subviews
  CGFloat backImageInset = 14.0f; // distance from edge
  self.backLeftImageView.left = CGRectGetMinX(r) + backImageInset;
  self.backLeftImageView.y = CGRectGetMidY(r);
  self.backRightImageView.right = CGRectGetMaxX(r) - backImageInset;
  self.backRightImageView.y = CGRectGetMidY(r);
  
  self.backLeftLabel.size = [self sizeForLabel:self.backLeftLabel];
  self.backRightLabel.size = [self sizeForLabel:self.backRightLabel];
  CGFloat backLabelInset = 20.0f; // distance from backImage
  self.backLeftLabel.left = self.backLeftImageView.right + backLabelInset;
  self.backLeftLabel.y = CGRectGetMidY(r);
  self.backRightLabel.right = self.backRightImageView.left - backLabelInset;
  self.backRightLabel.y = CGRectGetMidY(r);
  
  // Size and position frontView subviews
  r = self.frontView.bounds;
  self.topLabel.size = [self sizeForLabel:self.topLabel];
  self.bottomLabel.size = [self sizeForLabel:self.bottomLabel];
  CGFloat topLabelOffset = 2.0f; // distance from superview center to bottom of label
  CGFloat bottomLabelOffset = -3.0f; // distance from superview center to top of label
  self.topLabel.bottom = CGRectGetMidY(r) - topLabelOffset;
  self.topLabel.x = CGRectGetMidX(r);
  self.bottomLabel.top = CGRectGetMidY(r) + bottomLabelOffset;
  self.bottomLabel.x = CGRectGetMidX(r);

}

- (CGSize)sizeForLabel:(UILabel *)label{
  return [label.text sizeWithFont:label.font constrainedToSize:label.superview.bounds.size lineBreakMode:NSLineBreakByWordWrapping];
}

# pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
  CGFloat offset = scrollView.contentOffset.x;
  if (offset < -self.pullLeftOffset){
    [scrollView setContentOffset:CGPointMake(-self.pullLeftOffset, 0)];
  }else if(offset > self.pullRightOffset){
    [scrollView setContentOffset:CGPointMake(self.pullLeftOffset, 0)];
  }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
  //  NSLog(@"ENDED DRAGGING at offset: %f", scrollView.contentOffset.x);
  CGFloat offset = scrollView.contentOffset.x;
  if (offset <= -self.pullLeftOffset){
    [self.pullLeftCommand execute:nil];
  }else if(offset >= self.pullRightOffset){
    [self.pullRightCommand execute:nil];
  }
}

# pragma mark - view getters

- (UIView *)backView{
  if (!_backView){
    UIColor *shadowGreen = RGBCOLOR(0, 55, 22);
    _backView = (UIView *)[[TCSInnerShadowView alloc] initWithColor:GREEN_DARK shadowColor:shadowGreen shadowRadius:3];
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
        // Fill background
        [GREEN_KELLY setFill];
        CGContextFillRect(c, r);
        
        CGFloat borderWidth = 1.0f;
        CGRect leftBorder = CGRectMake(CGRectGetMinX(r), CGRectGetMinY(r), borderWidth, CGRectGetHeight(r));
        CGRect rightBorder = CGRectMake(CGRectGetMaxX(r)-borderWidth, CGRectGetMinY(r), borderWidth, CGRectGetHeight(r));
        
        // Fill left & right borders
        [RGBCOLOR(0, 47, 18) setFill];
        CGContextFillRect(c, leftBorder);
        CGContextFillRect(c, rightBorder);
        
      }
      CGContextRestoreGState(c);
    }];
    UIColor *shadowGreen = RGBCOLOR(0, 48, 19);
    
    _frontView.clipsToBounds = NO;
    _frontView.layer.masksToBounds = NO;
    CALayer *layer = _frontView.layer;
    layer.shadowColor = [shadowGreen CGColor];
    layer.shadowOffset = CGSizeMake(0, 0);
    layer.shadowOpacity = 1.0f;
    layer.shadowRadius = 1.5;
  }
  return _frontView;
}

- (UIImageView *)backLeftImageView{
  if (!_backLeftImageView){
    _backLeftImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"leftArrow"]];
  }
  return _backLeftImageView;
}

- (UIImageView *)backRightImageView{
  if (!_backRightImageView){
    _backRightImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"rightArrow"]];
  }
  return _backRightImageView;
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
  }
  return _topLabel;
}

- (UILabel *)bottomLabel{
  if (!_bottomLabel){
    _bottomLabel = [[UILabel alloc] init];
    _bottomLabel.backgroundColor = CLEAR;
    _bottomLabel.font = FONT_AVN_MEDIUM(19);
    _bottomLabel.textColor = WHITE_SUBTLE;
  }
  return _bottomLabel;
}

@end
