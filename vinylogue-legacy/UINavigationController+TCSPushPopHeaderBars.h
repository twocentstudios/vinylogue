//
//  UINavigationController+TCSPushPopHeaderBars.h
//  vinylogue
//
//  Created by Christopher Trott on 3/25/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UINavigationController (TCSPushPopHeaderBars)

- (void)pushBarVisibility;
- (void)popBarVisibilityAnimated:(BOOL)animated;

@end
