//
//  TCStackedCenteredView.m
//  InterestingThings
//
//  Created by Christopher Trott on 2/6/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import "TCSStackedCenteredView.h"

@implementation TCSStackedCenteredView

- (id)initWithTopView:(UIView *)topView
        topMiddleView:(UIView *)topMiddleView
     bottomMiddleView:(UIView *)bottomMiddleView
           bottomView:(UIView *)bottomView{
  self = [super initWithFrame:CGRectZero];
  if (self) {
    self.verticalMargin = 20;
    _fixedVerticalMarginMode = YES;
    
    _topView = topView;
    _topMiddleView = topMiddleView;
    _bottomMiddleView = bottomMiddleView;
    _bottomView = bottomView;
    
    [self addSubview:_topView];
    [self addSubview:_topMiddleView];
    [self addSubview:_bottomMiddleView];
    [self addSubview:_bottomView];
    
    self.backgroundColor = CLEAR;
  }
  return self;
}

- (id)initWithTopHalfView:(UIView *)topHalfView
         bottomMiddleView:(UIView *)bottomMiddleView
               bottomView:(UIView *)bottomView{
  self = [super initWithFrame:CGRectZero];
  if (self) {
    self.interViewMargin = 4;
    _fixedVerticalMarginMode = NO;

    _topHalfView = topHalfView;
    _bottomMiddleView = bottomMiddleView;
    _bottomView = bottomView;
    
    [self addSubview:_topHalfView];
    [self addSubview:_bottomMiddleView];
    [self addSubview:_bottomView];
    
    self.backgroundColor = CLEAR;
  }
  return self;
}

- (void)layoutSubviews{
  CGRect r = self.bounds;
    
  self.topView.x = CGRectGetMidX(r);
  self.topMiddleView.x = CGRectGetMidX(r);
  self.topHalfView.x = CGRectGetMidX(r);
  self.bottomMiddleView.x = CGRectGetMidX(r);
  self.bottomView.x = CGRectGetMidX(r);
  
  if (self.fixedVerticalMarginMode) {
    CGFloat availableHeight = CGRectGetHeight(r) - self.verticalMargin * 2;
    CGFloat individualHeight = availableHeight/4.0f;

    CGFloat c = 0; // centerY moving down the page
    c += self.verticalMargin;
    
    c += individualHeight/2.0f;
    self.topView.y = c;
    c += individualHeight;
    self.topMiddleView.y = c;
    c += individualHeight;
    self.bottomMiddleView.y = c;
    c += individualHeight;
    self.bottomView.y = c;
  }else{
    CGFloat totalSubViewsHeight = self.topHalfView.height + self.bottomMiddleView.height + self.bottomView.height;
    totalSubViewsHeight += (self.topHalfView && self.bottomMiddleView) ? self.interViewMargin : 0;
    totalSubViewsHeight += (self.bottomMiddleView && self.bottomView) ? self.interViewMargin : 0;
    totalSubViewsHeight += (self.topHalfView && !self.bottomMiddleView && self.bottomView) ? self.interViewMargin : 0;
    CGFloat verticalMargin = roundf((CGRectGetHeight(r) - totalSubViewsHeight)/2.0f);
    
    CGFloat c = 0; // view top moving down the page
    c += verticalMargin;
    
    if (self.topHalfView){
      self.topHalfView.top = c;
      c += self.topHalfView.height;
    }
      
    if (self.topHalfView && (self.bottomMiddleView || self.bottomView))
      c += self.interViewMargin;
    
    if (self.bottomMiddleView){
      self.bottomMiddleView.top = c;
      c += self.bottomMiddleView.height;
    }
    
    if (self.bottomMiddleView && self.bottomView)
      c += self.interViewMargin;
    
    if (self.bottomView){
      self.bottomView.top = c;
      c += self.bottomView.height;
    }
  }
}

@end
