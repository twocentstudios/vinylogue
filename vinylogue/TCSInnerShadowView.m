//
//  TCSInnerShadowView.m
//  vinylogue
//
//  Created by Christopher Trott on 2/20/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import "TCSInnerShadowView.h"

@interface TCSInnerShadowView ()

@property (nonatomic) CGFloat shadowRadius;
@property (nonatomic, strong) CALayer *innerLayer;

@end


@implementation TCSInnerShadowView

- (id)initWithColor:(UIColor *)mainColor shadowColor:(UIColor *)shadowColor shadowRadius:(CGFloat)shadowRadius
{
  self = [super initWithFrame:CGRectZero];
  if (self) {
    self.clipsToBounds = YES;
    
    self.backgroundColor = shadowColor;
    self.shadowRadius = shadowRadius;
    
    CALayer *innerLayer = [CALayer layer];
    [innerLayer setBackgroundColor:[mainColor CGColor]];
    [innerLayer setShadowOffset:CGSizeMake(0, 0)];
    [innerLayer setShadowColor:[shadowColor CGColor]];
    [innerLayer setShadowOpacity:1.0f];
    [innerLayer setShadowRadius:shadowRadius];
    [innerLayer setRasterizationScale:0.25];
    [innerLayer setShouldRasterize:YES];
    self.innerLayer = innerLayer;
    
    [self.layer insertSublayer:self.innerLayer atIndex:0];
  }
  return self;
}

- (void)layoutSubviews{
  [super layoutSubviews];
  
  self.innerLayer.frame = CGRectInset(self.bounds, self.shadowRadius, self.shadowRadius);
}

@end
