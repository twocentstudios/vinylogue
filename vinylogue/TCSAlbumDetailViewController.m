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

#import <ReactiveCocoa/ReactiveCocoa.h>
#import <EXTScope.h>
#import <EXTKeyPathCoding.h>

// TEMP
@class TCSAlbumCoverView;
@class TCSPlayCountView;

@interface TCSAlbumDetailViewController ()

// Views
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) TCSAlbumArtDetailView *albumDetailView;
@property (nonatomic, strong) TCSAlbumPlayCountDetailView *playCountView;
@property (nonatomic, strong) UISegmentedControl *metaDataSegmentedView;
@property (nonatomic, strong) UILabel *aboutHeaderLabel;
@property (nonatomic, strong) UILabel *aboutLabel;

// Vars
@property (nonatomic, strong) TCSLastFMAPIClient *client;
@property (atomic, strong) Album *album;
@property (nonatomic, strong) User *user;

// State
@property (atomic) BOOL showingLoading;

@end

@implementation TCSAlbumDetailViewController

// TEMP
- (void)doDebug:(id)sender{
  NSLog(@"Debug");
}

- (id)initWithAlbum:(Album *)album user:(User *)user{
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    self.album = album;
    self.user = user;
    self.client = [TCSLastFMAPIClient clientForUser:self.user];
    
    // TEMP
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(doDebug:)];
  }
  return self;
}

- (id)initWithAlbum:(Album *)album{
  return [self initWithAlbum:album user:nil];
}

- (void)loadView{
  self.view = [[UIView alloc] init];
  self.view.autoresizesSubviews = YES;
    
  [self.view addSubview:self.scrollView];
  [self.scrollView addSubview:self.albumDetailView];
  [self.scrollView addSubview:self.playCountView];
  [self.scrollView addSubview:self.aboutHeaderLabel];
  [self.scrollView addSubview:self.aboutLabel];
}

- (void)viewDidLoad{
  [super viewDidLoad];
	
  @weakify(self);
  
  RACBind(self.albumDetailView.artistName) = RACBind(self.album.artist.name);
  RACBind(self.albumDetailView.albumName) = RACBind(self.album.name);
  RACBind(self.albumDetailView.albumReleaseDate) = RACBind(self.album.releaseDate);
  RACBind(self.albumDetailView.albumImageURL) = RACBind(self.album.imageURL);
  RACBind(self.aboutLabel.text) = RACBind(self.album.about);
  
  [RACAbleWithStart(self.album.about) subscribeNext:^(NSString *about) {
    @strongify(self);
    if (!about || [about isEqualToString:@""]){
      self.aboutHeaderLabel.text = @"";
    }else{
      self.aboutHeaderLabel.text = @"about this album";
    }
  }];
  
  [[[RACAbleWithStart(self.albumDetailView.primaryAlbumColor) map:^id(UIColor *color) {
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
                     }
                     completion:NULL];
  }];
  
  RACBind(self.playCountView.labelTextColor) = RACBind(self.albumDetailView.textAlbumColor);
  RACBind(self.playCountView.labelTextShadowColor) = RACBind(self.albumDetailView.textShadowAlbumColor);
  
  [[RACAble(self.albumDetailView.textAlbumColor) deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(UIColor *color) {
    self.aboutHeaderLabel.textColor = color;
    self.aboutLabel.textColor = color;
  }];
  [[RACAble(self.albumDetailView.textShadowAlbumColor) deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(UIColor *color) {
    self.aboutHeaderLabel.shadowColor = color;
  }];
  
  RACBind(self.playCountView.playCountWeek) = RACBind(self.album.weeklyAlbumChart.playcount);
  RAC(self.playCountView.durationWeek) = [RACAbleWithStart(self.album.weeklyAlbumChart.weeklyChart.from) map:^id(NSDate *date) {
    NSDateComponents *components = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] components:NSYearForWeekOfYearCalendarUnit|NSYearCalendarUnit|NSWeekOfYearCalendarUnit fromDate:date];
    return [NSString stringWithFormat:@"week %i %i", components.weekOfYear, components.yearForWeekOfYear];
  }];
  RACBind(self.playCountView.playCountAllTime) = RACBind(self.album.totalPlayCount);
  
  [RACAbleWithStart(self.showingLoading) subscribeNext:^(NSNumber *showingLoading) {
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
    [[self.client fetchAlbumDetailsForAlbum:self.album]
     subscribeNext:^(Album *album) {
      
    } error:^(NSError *error) {
      NSLog(@"Error fetching album details: %@", error);
      self.showingLoading = NO;
    } completed:^{
      self.showingLoading = NO;
    }];
  }

}

- (void)viewWillLayoutSubviews{
  
  CGRect r = self.view.bounds;
  CGFloat w = CGRectGetWidth(r);
  CGFloat t = CGRectGetMinY(r);
  static CGFloat viewHMargin = 26.0f;
  static CGFloat viewVMargin = 24.0f;
  CGFloat widthWithMargin = w - (viewHMargin * 2);

  ////////////////////////
  // Set width and heights
  self.albumDetailView.width = w;
  [self.albumDetailView layoutSubviews];
  
  // playCountView sets its own desired height
  self.playCountView.width = w;
  [self.playCountView layoutSubviews];
  
  self.metaDataSegmentedView.width = w;
  // metaDataSegmentedView sets its own desired height
  
  [self setLabelSizeForLabel:self.aboutHeaderLabel width:widthWithMargin];
  [self setLabelSizeForLabel:self.aboutLabel width:widthWithMargin];
  self.aboutHeaderLabel.left = viewHMargin;
  self.aboutLabel.left = viewHMargin;
  
  ////////////////////////
  // Set top positions
  self.albumDetailView.top = t;
  t += self.albumDetailView.height;
  self.playCountView.top = t;
  t += self.playCountView.height;
  self.metaDataSegmentedView.top = t;
  t += self.metaDataSegmentedView.height;
  t += viewVMargin;
  self.aboutHeaderLabel.top = t;
  t += self.aboutHeaderLabel.height;
  self.aboutLabel.top = t;
  t += self.aboutLabel.height;
  t += viewVMargin;
  
  self.scrollView.frame = r;
  [self.scrollView setContentSize:CGSizeMake(w, t)];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setLabelSizeForLabel:(UILabel *)label width:(CGFloat)width{
  label.size = [label.text sizeWithFont:label.font constrainedToSize:CGSizeMake(width, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
}


- (UIScrollView *)scrollView{
  if (!_scrollView){
    _scrollView = [[UIScrollView alloc] init];
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.showsVerticalScrollIndicator = YES;
    _scrollView.directionalLockEnabled = YES;
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

- (UILabel *)aboutHeaderLabel{
  if (!_aboutHeaderLabel){
    _aboutHeaderLabel = [[UILabel alloc] init];
    _aboutHeaderLabel.numberOfLines = 0;
    _aboutHeaderLabel.font = FONT_AVN_DEMIBOLD(24);
    _aboutHeaderLabel.backgroundColor = CLEAR;
    _aboutHeaderLabel.shadowOffset = SHADOW_BOTTOM;
    _aboutHeaderLabel.textAlignment = NSTextAlignmentLeft;
  }
  return _aboutHeaderLabel;
}

- (UILabel *)aboutLabel{
  if (!_aboutLabel){
    _aboutLabel = [[UILabel alloc] init];
    _aboutLabel.numberOfLines = 0;
    _aboutLabel.font = FONT_AVN_REGULAR(16);
    _aboutLabel.backgroundColor = CLEAR;
    _aboutLabel.shadowOffset = SHADOW_BOTTOM;
    _aboutLabel.textAlignment = NSTextAlignmentLeft;
  }
  return _aboutLabel;
}

@end



