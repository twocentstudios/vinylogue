//
//  UIImage+TCSImageRepresentativeColors.h
//  vinylogue
//
//  Created by Christopher Trott on 3/18/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RACTuple;

@interface UIImage (TCSImageRepresentativeColors)

// Returns an RACTuple with the primaryColor, secondaryColor, averageColor, textColor, and textShadowColor for the image;
- (RACTuple *)getRepresentativeColors;

@end
