//
//  TCSSlideSelectView.h
//  vinylogue
//
//  Created by Christopher Trott on 2/18/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TCSSlideSelectView : UIView

@property (nonatomic, strong) UIView *backView;
@property (nonatomic, strong) UIImageView *backLeftImageView;
@property (nonatomic, strong) UIImageView *backRightImageView;
@property (nonatomic, strong) UILabel *backLeftLabel;
@property (nonatomic, strong) UILabel *backRightLabel;

@property (nonatomic, strong) UIScrollView *scrollView;

@property (nonatomic, strong) UIView *frontView;
@property (nonatomic, strong) UILabel *topLabel;
@property (nonatomic, strong) UILabel *bottomLabel;

@end
