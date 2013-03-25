//
//  TCSAlbumPlayCountDetailView.m
//  vinylogue
//
//  Created by Christopher Trott on 3/18/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import "TCSAlbumPlayCountDetailView.h"

#import "UILabel+TCSLabelSizeCalculations.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <EXTScope.h>

@interface TCSAlbumPlayCountDetailView ()

@property (nonatomic, strong) UILabel *playCountWeekLabel;
@property (nonatomic, strong) UILabel *playWeekLabel;
@property (nonatomic, strong) UILabel *durationWeekLabel;

@property (nonatomic, strong) UILabel *playCountAllTimeLabel;
@property (nonatomic, strong) UILabel *playAllTimeLabel;
@property (nonatomic, strong) UILabel *durationAllTimeLabel;

@end

@implementation TCSAlbumPlayCountDetailView

- (id)init{
  self = [super initWithFrame:CGRectZero];
  if (self) {
    self.backgroundColor = CLEAR;
    self.labelTextColor = WHITE; // defaults
    self.labelTextShadowColor = BLACK;
    
    [self addSubview:self.playCountWeekLabel];
    [self addSubview:self.playWeekLabel];
    [self addSubview:self.durationWeekLabel];
    [self addSubview:self.playCountAllTimeLabel];
    [self addSubview:self.playAllTimeLabel];
    [self addSubview:self.durationAllTimeLabel];

    @weakify(self);
    // Set label text
    RAC(self.playCountWeekLabel.text) = [RACAble(self.playCountWeek) map:^id(NSNumber *count) {
      if (count == nil){
        return @"?";
      }else{
        return [NSString stringWithFormat:@"%i", [count integerValue]];
      }
    }];
    RAC(self.playCountAllTimeLabel.text) = [RACAble(self.playCountAllTime) map:^id(NSNumber *count) {
      if (count == nil){
        return @"?";
      }else{
        return [NSString stringWithFormat:@"%i", [count integerValue]];
      }
    }];
    RACBind(self.durationWeekLabel.text) = RACBind(self.durationWeek);
    self.playWeekLabel.text = @"plays";
    self.playAllTimeLabel.text = @"plays";
    self.durationAllTimeLabel.text = @"all-time";
    
    [[RACAbleWithStart(self.labelTextColor) deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(UIColor *color) {
      @strongify(self);
      self.playCountWeekLabel.textColor = COLORA(color, 0.85);
      self.playWeekLabel.textColor = COLORA(color, 0.7);
      self.durationWeekLabel.textColor = COLORA(color, 0.7);
      self.playCountAllTimeLabel.textColor = COLORA(color, 0.85);
      self.playAllTimeLabel.textColor = COLORA(color, 0.7);
      self.durationAllTimeLabel.textColor = COLORA(color, 0.7);
    }];
    
    [[RACAbleWithStart(self.labelTextShadowColor) deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(UIColor *color) {
      @strongify(self);
      self.playCountWeekLabel.shadowColor = COLORA(color, 0.6);
      self.playWeekLabel.shadowColor = COLORA(color, 0.5);
      self.durationWeekLabel.shadowColor = COLORA(color, 0.5);
      self.playCountAllTimeLabel.shadowColor = COLORA(color, 0.6);
      self.playAllTimeLabel.shadowColor = COLORA(color, 0.5);
      self.durationAllTimeLabel.shadowColor = COLORA(color, 0.5);
    }];
  }
  return self;
}

- (void)layoutSubviews{
  [super layoutSubviews];
  
  const CGRect r = self.bounds;
  const CGFloat w = CGRectGetWidth(r);
  CGFloat tl, tr;
  tl = tr = CGRectGetMinY(r); // used to set y position and calculate height
  const CGFloat centerXL = CGRectGetMidX(r)/2.0f;
  const CGFloat centerXR = CGRectGetMidX(r)*3.0f/2.0f;
  const CGFloat viewHMargin = 6.0f;
  const CGFloat viewVMargin = 10.0f;
  const CGFloat interLabelMargin = -3.0f;
  const CGFloat widthWithMargin = w/2.0 - (viewHMargin * 2);
  
  // Calculate individual heights and widths
  [self setLabelSizeForLabel:self.playCountWeekLabel width:widthWithMargin];
  [self setLabelSizeForLabel:self.playWeekLabel width:widthWithMargin];
  [self setLabelSizeForLabel:self.durationWeekLabel width:widthWithMargin];
  [self setLabelSizeForLabel:self.playCountAllTimeLabel width:widthWithMargin];
  [self setLabelSizeForLabel:self.playAllTimeLabel width:widthWithMargin];
  [self setLabelSizeForLabel:self.durationAllTimeLabel width:widthWithMargin];
  
  // Set y position and calculate total height
  tl += viewVMargin;
  self.playCountWeekLabel.top = tl;
  tl += self.playCountWeekLabel.height;
  tl += interLabelMargin*2;
  self.playWeekLabel.top = tl;
  tl += self.playWeekLabel.height;
  tl += interLabelMargin;
  self.durationWeekLabel.top = tl;
  tl += self.durationWeekLabel.height;
  tl += viewVMargin;
  
  tr += viewVMargin;
  self.playCountAllTimeLabel.top = tr;
  tr += self.playCountAllTimeLabel.height;
  tr += interLabelMargin*2;
  self.playAllTimeLabel.top = tr;
  tr += self.playAllTimeLabel.height;
  tr += interLabelMargin;
  self.durationAllTimeLabel.top = tr;
  tr += self.durationAllTimeLabel.height;
  tr += viewVMargin;
  
  // self.height depends on component heights
  self.height = MAX(tl, tr);
  
  // Set x positions
  self.playCountWeekLabel.x = centerXL;
  self.playWeekLabel.x = centerXL;
  self.durationWeekLabel.x = centerXL;
  self.playCountAllTimeLabel.x = centerXR;
  self.playAllTimeLabel.x = centerXR;
  self.durationAllTimeLabel.x = centerXR;
}

- (void)setLabelSizeForLabel:(UILabel *)label width:(CGFloat)width{
  label.size = [label.text sizeWithFont:label.font constrainedToSize:CGSizeMake(width, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
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
    const CGRect leftCenterBorder = CGRectMake(CGRectGetMidX(r)-borderHeight/2.0f, CGRectGetMinY(r)+borderHeight, borderHeight, CGRectGetHeight(r)-borderHeight*2);
    const CGRect rightCenterBorder = CGRectMake(CGRectGetMidX(r)+borderHeight/2.0f, CGRectGetMinY(r)+borderHeight, borderHeight, CGRectGetHeight(r)-borderHeight*2);
    
    // Fill top & left center border
    [WHITEA(0.35f) setFill];
    CGContextFillRect(c, topBorder);
    CGContextFillRect(c, leftCenterBorder);
    
    // Fill bottom & right center border
    [BLACKA(0.25f) setFill];
    CGContextFillRect(c, bottomBorder);
    CGContextFillRect(c, rightCenterBorder);
    
  }
  CGContextRestoreGState(c);
}

#pragma mark -- view getters

- (UILabel *)playCountWeekLabel{
  if (!_playCountWeekLabel){
    _playCountWeekLabel = [[UILabel alloc] init];
    _playCountWeekLabel.numberOfLines = 1;
    _playCountWeekLabel.font = FONT_AVN_DEMIBOLD(30);
    _playCountWeekLabel.backgroundColor = CLEAR;
    _playCountWeekLabel.shadowOffset = SHADOW_BOTTOM;
    _playCountWeekLabel.textAlignment = NSTextAlignmentCenter;
  }
  return _playCountWeekLabel;
}

- (UILabel *)playWeekLabel{
  if (!_playWeekLabel){
    _playWeekLabel = [[UILabel alloc] init];
    _playWeekLabel.numberOfLines = 1;
    _playWeekLabel.font = FONT_AVN_ULTRALIGHT(14);
    _playWeekLabel.backgroundColor = CLEAR;
    _playWeekLabel.shadowOffset = SHADOW_BOTTOM;
    _playWeekLabel.textAlignment = NSTextAlignmentCenter;
  }
  return _playWeekLabel;
}

- (UILabel *)durationWeekLabel{
  if (!_durationWeekLabel){
    _durationWeekLabel = [[UILabel alloc] init];
    _durationWeekLabel.numberOfLines = 0;
    _durationWeekLabel.font = FONT_AVN_REGULAR(18);
    _durationWeekLabel.backgroundColor = CLEAR;
    _durationWeekLabel.shadowOffset = SHADOW_BOTTOM;
    _durationWeekLabel.textAlignment = NSTextAlignmentCenter;
  }
  return _durationWeekLabel;
}

- (UILabel *)playCountAllTimeLabel{
  if (!_playCountAllTimeLabel){
    _playCountAllTimeLabel = [[UILabel alloc] init];
    _playCountAllTimeLabel.numberOfLines = self.playCountWeekLabel.numberOfLines;
    _playCountAllTimeLabel.font = self.playCountWeekLabel.font;
    _playCountAllTimeLabel.backgroundColor = self.playCountWeekLabel.backgroundColor;
    _playCountAllTimeLabel.shadowOffset = self.playCountWeekLabel.shadowOffset;
    _playCountAllTimeLabel.textAlignment = self.playCountWeekLabel.textAlignment;
  }
  return _playCountAllTimeLabel;
}

- (UILabel *)playAllTimeLabel{
  if (!_playAllTimeLabel){
    _playAllTimeLabel = [[UILabel alloc] init];
    _playAllTimeLabel.numberOfLines = self.playWeekLabel.numberOfLines;
    _playAllTimeLabel.font = self.playWeekLabel.font;
    _playAllTimeLabel.backgroundColor = self.playWeekLabel.backgroundColor;
    _playAllTimeLabel.shadowOffset = self.playWeekLabel.shadowOffset;
    _playAllTimeLabel.textAlignment = self.playWeekLabel.textAlignment;
  }
  return _playAllTimeLabel;
}

- (UILabel *)durationAllTimeLabel{
  if (!_durationAllTimeLabel){
    _durationAllTimeLabel = [[UILabel alloc] init];
    _durationAllTimeLabel.numberOfLines = self.durationWeekLabel.numberOfLines;
    _durationAllTimeLabel.font = self.durationWeekLabel.font;
    _durationAllTimeLabel.backgroundColor = self.durationWeekLabel.backgroundColor;
    _durationAllTimeLabel.shadowOffset = self.durationWeekLabel.shadowOffset;
    _durationAllTimeLabel.textAlignment = self.durationWeekLabel.textAlignment;
  }
  return _durationAllTimeLabel;
}

@end
