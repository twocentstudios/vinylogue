//
//  TCSSlideSelectView.m
//  vinylogue
//
//  Created by Christopher Trott on 2/18/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import "TCSSlideSelectView.h"

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
  
  CGFloat titleViewInset = 40.0f; // distance from left and right
  self.frontView.width = CGRectGetWidth(r) - titleViewInset * 2.0f;
  self.frontView.height = CGRectGetHeight(r);
  self.frontView.center = self.contentCenter;
  
  // Size and position backView subviews
  CGFloat backImageInset = 10.0f; // distance from edge
  self.backLeftImageView.left = CGRectGetMinX(r) + backImageInset;
  self.backLeftImageView.y = CGRectGetMidY(r);
  self.backRightImageView.right = CGRectGetMaxX(r) - backImageInset;
  self.backRightImageView.y = CGRectGetMidY(r);
  
  self.backLeftLabel.size = [self sizeForLabel:self.backLeftLabel];
  self.backRightLabel.size = [self sizeForLabel:self.backRightLabel];
  CGFloat backLabelInset = 6.0f; // distance from backImage
  self.backLeftLabel.left = self.backLeftImageView.right + backLabelInset;
  self.backLeftLabel.y = CGRectGetMidY(r);
  self.backRightLabel.right = self.backRightImageView.left - backLabelInset;
  self.backRightLabel.y = CGRectGetMidY(r);
  
  // Size and position frontView subviews
  r = self.frontView.bounds;
  self.topLabel.size = [self sizeForLabel:self.topLabel];
  self.bottomLabel.size = [self sizeForLabel:self.bottomLabel];
  CGFloat topLabelOffset = 2.0f; // distance from superview center to bottom of label
  CGFloat bottomLabelOffset = 2.0f; // distance from superview center to top of label
  self.topLabel.bottom = CGRectGetMidY(r) - topLabelOffset;
  self.topLabel.x = CGRectGetMidX(r);
  self.bottomLabel.top = CGRectGetMidY(r) + bottomLabelOffset;
  self.bottomLabel.x = CGRectGetMidX(r);

}

- (CGSize)sizeForLabel:(UILabel *)label{
  return [label.text sizeWithFont:label.font constrainedToSize:label.superview.bounds.size lineBreakMode:NSLineBreakByWordWrapping];
}

# pragma mark - view getters

- (UIView *)backView{
  if (!_backView){
    _backView = [[UIView alloc] init];
    _backView.backgroundColor = [UIColor greenColor];
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
//    _scrollView.delegate = self;
  }
  return _scrollView;
}

- (UIView *)frontView{
  if (!_frontView){
    _frontView = [[UIView alloc] init];
    _frontView.backgroundColor = [UIColor redColor];
  }
  return _frontView;
}

- (UIImageView *)backLeftImageView{
  if (!_backLeftImageView){
    _backLeftImageView = [[UIImageView alloc] init];
  }
  return _backLeftImageView;
}

- (UIImageView *)backRightImageView{
  if (!_backRightImageView){
    _backRightImageView = [[UIImageView alloc] init];
  }
  return _backRightImageView;
}

- (UILabel *)backLeftLabel{
  if (!_backLeftLabel){
    _backLeftLabel = [[UILabel alloc] init];
  }
  return _backLeftLabel;
}

- (UILabel *)backRightLabel{
  if (!_backRightLabel){
    _backRightLabel = [[UILabel alloc] init];
  }
  return _backRightLabel;
}

- (UILabel *)topLabel{
  if (!_topLabel){
    _topLabel = [[UILabel alloc] init];
  }
  return _topLabel;
}

- (UILabel *)bottomLabel{
  if (!_bottomLabel){
    _bottomLabel = [[UILabel alloc] init];
  }
  return _bottomLabel;
}

@end
