//
//  TCSSlideSelectView.h
//  vinylogue
//
//  Created by Christopher Trott on 2/18/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <ReactiveCocoa/ReactiveCocoa.h>

// This view has two layers. The back layer has two buttons
// that can be tapped to move left or right, and also
// shows a text field on each side configured to show
// where you're going to.
//
// The top view sits above a scrollview and can be slid left
// and right. By default, sliding the view right triggers a
// logical "left" action.
//
// Actions are triggered on an RACCommand for each side.
// These commands can be overridden by the slide view's super
// and customized.
@interface TCSSlideSelectView : UIView <UIScrollViewDelegate>

@property (nonatomic, strong) UIView *backView;
@property (nonatomic, strong) UIButton *backLeftButton;
@property (nonatomic, strong) UIButton *backRightButton;
@property (nonatomic, strong) UILabel *backLeftLabel;
@property (nonatomic, strong) UILabel *backRightLabel;

@property (nonatomic, strong) UIScrollView *scrollView;

@property (nonatomic, strong) UIView *frontView;
@property (nonatomic, strong) UILabel *topLabel;
@property (nonatomic, strong) UILabel *bottomLabel;

// Signals will be fired when the scroll view is dragged past the offset
@property (nonatomic) CGFloat pullLeftOffset;
@property (nonatomic) CGFloat pullRightOffset;

@property (nonatomic, strong) RACCommand *pullLeftCommand;
@property (nonatomic, strong) RACCommand *pullRightCommand;

@end
