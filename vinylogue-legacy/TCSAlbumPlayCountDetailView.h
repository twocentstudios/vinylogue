//
//  TCSAlbumPlayCountDetailView.h
//  vinylogue
//
//  Created by Christopher Trott on 3/18/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TCSAlbumPlayCountDetailView : UIView

@property (nonatomic, readonly) UILabel *playCountWeekLabel;
@property (nonatomic, readonly) UILabel *playWeekLabel;
@property (nonatomic, readonly) UILabel *durationWeekLabel;

@property (nonatomic, readonly) UILabel *playCountAllTimeLabel;
@property (nonatomic, readonly) UILabel *playAllTimeLabel;
@property (nonatomic, readonly) UILabel *durationAllTimeLabel;

// Data properties tied to views
@property (nonatomic, strong) NSNumber *playCountWeek;
@property (nonatomic, strong) NSString *durationWeek;
@property (nonatomic, strong) NSNumber *playCountAllTime;
@property (nonatomic, strong) UIColor *labelTextColor;
@property (nonatomic, strong) UIColor *labelTextShadowColor;

@end
