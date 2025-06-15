//
//  UINavigationController+TCSPushPopHeaderBars.m
//  vinylogue
//
//  Created by Christopher Trott on 3/25/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import "UINavigationController+TCSPushPopHeaderBars.h"

@interface TCSBarVisibilityObject : NSObject

@property (nonatomic) BOOL navigationBarHidden;
@property (nonatomic) BOOL toolBarHidden;
@property (nonatomic) BOOL statusBarHidden;

@end

@implementation TCSBarVisibilityObject

@end

@implementation UINavigationController (TCSPushPopHeaderBars)

- (void)pushBarVisibility{
  TCSBarVisibilityObject *obj = [[TCSBarVisibilityObject alloc] init];
  obj.navigationBarHidden = [self isNavigationBarHidden];
  obj.toolBarHidden = [self isToolbarHidden];
  obj.statusBarHidden = [[UIApplication sharedApplication] isStatusBarHidden];
  [[[self class] barVisibilityStack] addObject:obj];
}

- (void)popBarVisibilityAnimated:(BOOL)animated{
  TCSBarVisibilityObject *obj = [[[self class] barVisibilityStack] lastObject];
  if (obj != nil){
    [self setNavigationBarHidden:obj.navigationBarHidden animated:animated];
    [self setToolbarHidden:obj.toolBarHidden animated:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:obj.statusBarHidden withAnimation:(animated ? UIStatusBarAnimationFade : UIStatusBarAnimationNone)];
  }
}

+ (NSMutableArray *)barVisibilityStack{
  static NSMutableArray *stack;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    stack = [@[] mutableCopy];
  });
  return stack;
}

@end

