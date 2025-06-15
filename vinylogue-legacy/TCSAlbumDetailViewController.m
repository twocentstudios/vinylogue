//
//  TCSAlbumDetailViewController.m
//  vinylogue
//
//  Created by Christopher Trott on 3/15/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import "TCSAlbumDetailViewController.h"
#import "TCSLastFMAPIClient.h"

#import "Artist.h"
#import "Album.h"
#import "WeeklyAlbumChart.h"
#import "WeeklyChart.h"

#import "TCSAlbumArtDetailView.h"
#import "TCSAlbumPlayCountDetailView.h"
#import "TCSAlbumAboutDetailView.h"

#import "UILabel+TCSLabelSizeCalculations.h"

#import <ReactiveCocoa/ReactiveCocoa.h>
#import <ReactiveCocoa/RACEXTScope.h>
#import <ReactiveCocoa/RACEXTKeyPathCoding.h>

// TEMP
@class TCSAlbumCoverView;
@class TCSPlayCountView;

@interface TCSAlbumDetailViewController ()

// Views
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UILabel *pullLabel;
@property (nonatomic, strong) TCSAlbumArtDetailView *albumDetailView;
@property (nonatomic, strong) TCSAlbumPlayCountDetailView *playCountView;
@property (nonatomic, strong) UISegmentedControl *metaDataSegmentedView;
@property (nonatomic, strong) TCSAlbumAboutDetailView *aboutView;

// Vars
@property (nonatomic, strong) TCSLastFMAPIClient *client;
@property (atomic, strong) WeeklyAlbumChart *weeklyAlbumChart;
@property (atomic, strong) WeeklyChart *weeklyChart;
@property (atomic, strong) Album *album;
@property (atomic, strong) User *user;

// State
@property (atomic) BOOL showingLoading;

@end

@implementation TCSAlbumDetailViewController

- (id)initWithWeeklyAlbumChart:(WeeklyAlbumChart *)weeklyAlbumChart{
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    self.weeklyAlbumChart = weeklyAlbumChart;
    self.weeklyChart = weeklyAlbumChart.weeklyChart;
    self.album = weeklyAlbumChart.album;
    self.user = weeklyAlbumChart.user;
    self.client = [TCSLastFMAPIClient clientForUser:self.user];
  }
  return self;
}

- (id)initWithAlbum:(Album *)album user:(User *)user{
  WeeklyAlbumChart *weeklyAlbumChart = [[WeeklyAlbumChart alloc] init];
  weeklyAlbumChart.album = album;
  weeklyAlbumChart.user = user;
  return [self initWithWeeklyAlbumChart:weeklyAlbumChart];
}

- (id)initWithAlbum:(Album *)album{
  return [self initWithAlbum:album user:nil];
}

- (void)loadView{
  self.view = [[UIView alloc] init];
  self.view.backgroundColor = WHITE_SUBTLE;
  self.view.autoresizesSubviews = YES;
  
  // Swiping left pops view controller
  UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(doSwipe:)];
  swipe.direction = UISwipeGestureRecognizerDirectionRight;
  [self.view addGestureRecognizer:swipe];
  
  [self.view addSubview:self.scrollView];
  [self.scrollView addSubview:self.pullLabel];
  [self.scrollView addSubview:self.albumDetailView];
  [self.scrollView addSubview:self.playCountView];
  [self.scrollView addSubview:self.aboutView];
}

- (void)viewDidLoad{
  [super viewDidLoad];
	 
  @weakify(self);
  
  RAC(self.albumDetailView, artistName) = RACObserve(self.album.artist, name);
  RAC(self.albumDetailView, albumName) = RACObserve(self.album, name);
  RAC(self.albumDetailView, albumReleaseDate) = RACObserve(self.album, releaseDate);
  RAC(self.albumDetailView, albumImageURL) = RACObserve(self.album, imageURL);
  
  RAC(self.aboutView, content) = RACObserve(self.album, about);
  self.pullLabel.text = @"← pull to go back";
  
  [RACObserve(self.album, about) subscribeNext:^(NSString *about) {
    @strongify(self);
    if (!about || [about isEqualToString:@""]){
      self.aboutView.header = @"";
    }else{
      self.aboutView.header = @"about this album";
    }
  }];
  
  [[[RACObserve(self.albumDetailView, primaryAlbumColor) map:^id(UIColor *color) {
    if (color == nil){
      return WHITE_SUBTLE;
    }else{
      return color;
    }
  }] deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(UIColor *color) {
    @strongify(self);
    [UIView animateWithDuration:1.1f
                          delay:0.0
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                       self.scrollView.backgroundColor = color;
//                       self.view.backgroundColor = color;
                     }
                     completion:NULL];
  }];
  
  RAC(self.playCountView, labelTextColor) = [RACObserve(self.albumDetailView, textAlbumColor) deliverOn:[RACScheduler mainThreadScheduler]];
  RAC(self.playCountView, labelTextShadowColor) = [RACObserve(self.albumDetailView, textShadowAlbumColor) deliverOn:[RACScheduler mainThreadScheduler]];
  
  [[[RACObserve(self.albumDetailView, textAlbumColor)
    ignore:nil]
    deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(UIColor *color) {
    @strongify(self);
    self.aboutView.labelTextColor = color;
    self.pullLabel.textColor = COLORA(color, 0.6);
  }];
  [[[RACObserve(self.albumDetailView, textShadowAlbumColor)
    ignore:nil]
    deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(UIColor *color) {
    @strongify(self);
    self.aboutView.labelTextShadowColor = color;
  }];
  
  RAC(self.playCountView, playCountWeek) = RACObserve(self.weeklyAlbumChart, playcount);
  RAC(self.playCountView, durationWeek) = [RACObserve(self.weeklyChart, from) map:^id(NSDate *date) {
    if (date != nil){
      NSDateComponents *components = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] components:NSYearForWeekOfYearCalendarUnit|NSYearCalendarUnit|NSWeekOfYearCalendarUnit fromDate:date];
      return [NSString stringWithFormat:@"week %li %li", (long)components.weekOfYear, (long)components.yearForWeekOfYear];
    }else{
      return @"week";
    }
  }];
  RAC(self.playCountView, playCountAllTime) = RACObserve(self.album, totalPlayCount);
  
  [RACObserve(self, showingLoading) subscribeNext:^(NSNumber *showingLoading) {
    BOOL isLoading = [showingLoading boolValue];
    @strongify(self);
    if (isLoading){
      self.title = @"loading...";
    }else{
      self.title = @"album";
    }
  }];
  
  if (self.album.detailLoaded == NO){
    self.showingLoading = YES;
    [[[self.client fetchAlbumDetailsForAlbum:self.album]
      deliverOn:[RACScheduler mainThreadScheduler]]
     subscribeNext:^(Album *album) {
       @strongify(self);
       [self.view setNeedsLayout];
     } error:^(NSError *error) {
       NSLog(@"Error fetching album details: %@", error);
       @strongify(self);
       self.showingLoading = NO;
     } completed:^{
       @strongify(self);
       self.showingLoading = NO;
     }];
  }

}

- (void)viewWillLayoutSubviews{
  
  CGRect r = self.view.bounds;
  CGFloat w = CGRectGetWidth(r);
  CGFloat t = CGRectGetMinY(r);
  static CGFloat viewHMargin = 26.0f;
//  static CGFloat viewVMargin = 24.0f;
  static CGFloat pullLabelMargin = 18.0f;
  CGFloat widthWithMargin = w - (viewHMargin * 2);

  ////////////////////////
  // Set width and heights
  [self.pullLabel setMultipleLineSizeForWidth:widthWithMargin];
  self.pullLabel.x = CGRectGetMidX(r);
  
  self.albumDetailView.width = w;
  [self.albumDetailView layoutSubviews];
  
  // playCountView sets its own desired height
  self.playCountView.width = w;
  [self.playCountView layoutSubviews];
  
  self.metaDataSegmentedView.width = w;
  // metaDataSegmentedView sets its own desired height
  
  self.aboutView.width = w;
  [self.aboutView layoutSubviews];
  
  ////////////////////////
  // Set top positions
  self.pullLabel.bottom = t - pullLabelMargin;
  self.albumDetailView.top = t;
  t += self.albumDetailView.height;
  self.playCountView.top = t;
  t += self.playCountView.height;
  self.metaDataSegmentedView.top = t;
  t += self.metaDataSegmentedView.height;
  self.aboutView.top = t;
  t += self.aboutView.height;
  
  self.scrollView.frame = r;
  [self.scrollView setContentSize:CGSizeMake(w, t)];
}

- (void)viewWillAppear:(BOOL)animated{
  [super viewWillAppear:animated];
  [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:animated];
  [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)viewWillDisappear:(BOOL)animated{
  [super viewWillDisappear:animated];
  [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:animated];
  [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)prefersStatusBarHidden {
  return YES;
}

- (void)doSwipe:(id)sender{
  [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
//  CGFloat contentOffset = scrollView.contentOffset.y;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
  CGFloat contentOffset = scrollView.contentOffset.y;
  if (contentOffset < -50.0){
    [self.navigationController popViewControllerAnimated:YES];
  }
}

#pragma mark - view getters

- (UIScrollView *)scrollView{
  if (!_scrollView){
    _scrollView = [[UIScrollView alloc] init];
    _scrollView.backgroundColor = CLEAR;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.showsVerticalScrollIndicator = YES;
    _scrollView.directionalLockEnabled = YES;
    _scrollView.alwaysBounceVertical = YES;
    _scrollView.delegate = self;
  }
  return _scrollView;
}

- (TCSAlbumArtDetailView *)albumDetailView{
  if (!_albumDetailView){
    _albumDetailView = [[TCSAlbumArtDetailView alloc] init];
  }
  return _albumDetailView;
}

- (TCSAlbumPlayCountDetailView *)playCountView{
  if (!_playCountView){
    _playCountView = [[TCSAlbumPlayCountDetailView alloc] init];
  }
  return _playCountView;
}

- (UILabel *)pullLabel{
  if (!_pullLabel){
    _pullLabel = [[UILabel alloc] init];
    _pullLabel.numberOfLines = 0;
    _pullLabel.font = FONT_AVN_REGULAR(16);
    _pullLabel.backgroundColor = CLEAR;
    _pullLabel.shadowOffset = SHADOW_BOTTOM;
    _pullLabel.textAlignment = NSTextAlignmentCenter;
  }
  return _pullLabel;
}

- (TCSAlbumAboutDetailView *)aboutView{
  if (!_aboutView){
    _aboutView = [[TCSAlbumAboutDetailView alloc] init];
  }
  return _aboutView;
}

@end



