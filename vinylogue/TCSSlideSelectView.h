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

@property (nonatomic, readonly) UIView *backView;
@property (nonatomic, readonly) UIButton *backLeftButton;
@property (nonatomic, readonly) UIButton *backRightButton;
@property (nonatomic, readonly) UILabel *backLeftLabel;
@property (nonatomic, readonly) UILabel *backRightLabel;

@property (nonatomic, readonly) UIScrollView *scrollView;

@property (nonatomic, readonly) UIView *frontView;
@property (nonatomic, readonly) UILabel *topLabel;
@property (nonatomic, readonly) UILabel *bottomLabel;

@property (nonatomic, getter = isEnabled) BOOL enabled;

// Signals will be fired when the scroll view is dragged past the offset
@property (nonatomic) CGFloat pullLeftOffset;
@property (nonatomic) CGFloat pullRightOffset;

@property (nonatomic, strong) RACCommand *pullLeftCommand;
@property (nonatomic, strong) RACCommand *pullRightCommand;


@end
