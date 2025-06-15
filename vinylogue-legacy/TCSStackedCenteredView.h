//
//  TCStackedCenteredView.h
//  InterestingThings
//
//  Created by Christopher Trott on 2/6/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TCSStackedCenteredView : UIView

@property (nonatomic, readonly) BOOL fixedVerticalMarginMode;

@property (nonatomic) CGFloat verticalMargin;
@property (nonatomic) CGFloat interViewMargin;

@property (nonatomic, readonly) UIView *topHalfView;

@property (nonatomic, readonly) UIView *topView;
@property (nonatomic, readonly) UIView *topMiddleView;
@property (nonatomic, readonly) UIView *bottomMiddleView;
@property (nonatomic, readonly) UIView *bottomView;

- (id)initWithTopView:(UIView *)topView
        topMiddleView:(UIView *)topMiddleView
     bottomMiddleView:(UIView *)bottomMiddleView
           bottomView:(UIView *)bottomView;

- (id)initWithTopHalfView:(UIView *)topHalfView
     bottomMiddleView:(UIView *)bottomMiddleView
           bottomView:(UIView *)bottomView;

@end
