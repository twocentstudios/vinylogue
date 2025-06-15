//
//  UILabel+TCSLabelSizeCalculations.m
//  vinylogue
//
//  Created by Christopher Trott on 3/19/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import "UILabel+TCSLabelSizeCalculations.h"

@implementation UILabel (TCSLabelSizeCalculations)

- (void)setSingleLineSizeForWidth:(CGFloat)width{
  self.size = [self.text sizeWithFont:self.font forWidth:width lineBreakMode:NSLineBreakByTruncatingTail];
}

- (void)setMultipleLineSizeForWidth:(CGFloat)width{
  self.size = [self.text sizeWithFont:self.font constrainedToSize:CGSizeMake(width, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
}

@end
