//
//  UILabel+TCSLabelSizeCalculations.h
//  vinylogue
//
//  Created by Christopher Trott on 3/19/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UILabel (TCSLabelSizeCalculations)

- (void)setSingleLineSizeForWidth:(CGFloat)width;
- (void)setMultipleLineSizeForWidth:(CGFloat)width;

@end
