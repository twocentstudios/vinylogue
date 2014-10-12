//
//  TCSAlbumAboutDetailView.m
//  vinylogue
//
//  Created by Christopher Trott on 3/19/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import "TCSAlbumAboutDetailView.h"

#import "UILabel+TCSLabelSizeCalculations.h"

#import <ReactiveCocoa/ReactiveCocoa.h>
#import <ReactiveCocoa/RACEXTScope.h>

@interface TCSAlbumAboutDetailView ()

@property (nonatomic, strong) UILabel *headerLabel;
@property (nonatomic, strong) UILabel *contentLabel;

@end

@implementation TCSAlbumAboutDetailView

- (id)init{
  self = [super initWithFrame:CGRectZero];
  if (self) {
    self.backgroundColor = BLACKA(0.05);
    self.contentMode = UIViewContentModeRedraw;
    self.labelTextColor = BLACK; // defaults
    self.labelTextShadowColor = WHITE;

    [self addSubview:self.headerLabel];
    [self addSubview:self.contentLabel];
    
    @weakify(self);
    RAC(self.headerLabel, text) = RACObserve(self, header);
    RAC(self.contentLabel, text) = RACObserve(self, content);
    
    [[RACObserve(self, labelTextColor) deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(UIColor *color) {
      @strongify(self);
      self.headerLabel.textColor = COLORA(color, 0.6);
      self.contentLabel.textColor = COLORA(color, 0.95);
    }];
    
    [[RACObserve(self, labelTextShadowColor) deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(UIColor *color) {
      @strongify(self);
      self.headerLabel.shadowColor = COLORA(color, 0.3);
      self.contentLabel.shadowColor = COLORA(color, 0.2);
    }];
  }
  return self;
}

- (void)layoutSubviews{
  [super layoutSubviews];
  
  const CGRect r = self.bounds;
  const CGFloat w = CGRectGetWidth(r);
  CGFloat t = CGRectGetMinY(r);
  const CGFloat viewHMargin = 26.0f;
  const CGFloat viewVMargin = 48.0f;
  const CGFloat widthWithMargin = w - (viewHMargin * 2);
  
  [self.headerLabel setMultipleLineSizeForWidth:widthWithMargin];
  [self.contentLabel setMultipleLineSizeForWidth:widthWithMargin];
  self.headerLabel.left = viewHMargin;
  self.contentLabel.left = viewHMargin;

  t += viewVMargin;
  self.headerLabel.top = t;
  t += self.headerLabel.height;
  self.contentLabel.top = t;
  t += self.contentLabel.height;
  t += viewVMargin;
  
  self.height = t;
}

- (void)drawRect:(CGRect)rect{
  CGContextRef c = UIGraphicsGetCurrentContext();
  
  const CGRect r = rect;
  
  CGContextSaveGState(c);
  {
    // Fill background
    [self.backgroundColor setFill];
    CGContextFillRect(c, r);
    
    const CGFloat borderHeight = 1.0f;
    const CGRect topBorder = CGRectMake(CGRectGetMinX(r), CGRectGetMinY(r), CGRectGetWidth(r), borderHeight);
    const CGRect bottomBorder = CGRectMake(CGRectGetMinX(r), CGRectGetMaxY(r)-borderHeight, CGRectGetWidth(r), borderHeight);
    
    // Fill top & left center border
    [BLACKA(0.05f) setFill];
    CGContextFillRect(c, topBorder);
    
    // Fill bottom & right center border
    [BLACKA(0.1f) setFill];
    CGContextFillRect(c, bottomBorder);
    
  }
  CGContextRestoreGState(c);
}

- (UILabel *)headerLabel{
  if (!_headerLabel){
    _headerLabel = [[UILabel alloc] init];
    _headerLabel.numberOfLines = 0;
    _headerLabel.font = FONT_AVN_DEMIBOLD(24);
    _headerLabel.backgroundColor = CLEAR;
    _headerLabel.shadowOffset = SHADOW_BOTTOM;
    _headerLabel.textAlignment = NSTextAlignmentLeft;
    _headerLabel.opaque = NO;
  }
  return _headerLabel;
}

- (UILabel *)contentLabel{
  if (!_contentLabel){
    _contentLabel = [[UILabel alloc] init];
    _contentLabel.numberOfLines = 0;
    _contentLabel.font = FONT_AVN_REGULAR(16);
    _contentLabel.backgroundColor = CLEAR;
    _contentLabel.shadowOffset = SHADOW_BOTTOM;
    _contentLabel.textAlignment = NSTextAlignmentLeft;
  }
  return _contentLabel;
}

@end
