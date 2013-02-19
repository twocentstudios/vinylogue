//
//  TCSSlideSelectView.m
//  vinylogue
//
//  Created by Christopher Trott on 2/18/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import "TCSSlideSelectView.h"

@interface TCSSlideSelectView ()

@property (nonatomic, strong) UIView *backView;
@property (nonatomic, strong) UIImageView *backLeftImageView;
@property (nonatomic, strong) UIImageView *backRightImageView;
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
  
  
}

# pragma mark - view getters

- (UIView *)backView{
  if (!_backView){
    _backView = [[UIView alloc] init];
  }
  return _backView;
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

- (UIScrollView *)scrollView{
  if (!_scrollView){
    _scrollView = [[UIScrollView alloc] init];
  }
  return _scrollView;
}

- (UIView *)frontView{
  if (!_frontView){
    _frontView = [[UIView alloc] init];
  }
  return _frontView;
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
