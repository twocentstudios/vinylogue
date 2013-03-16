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

#import <ReactiveCocoa/ReactiveCocoa.h>
#import <EXTScope.h>
#import <EXTKeyPathCoding.h>

// TEMP
@class TCSAlbumCoverView;
@class TCSPlayCountView;

@interface TCSAlbumDetailViewController ()

// Views
@property (nonatomic, strong) UIView *albumCoverView; //TCSAlbumCoverView
@property (nonatomic, strong) UILabel *artistNameLabel;
@property (nonatomic, strong) UILabel *albumNameLabel;
@property (nonatomic, strong) UILabel *releaseDateLabel;
@property (nonatomic, strong) UIView *playCountView; //TCSPlayCountView
@property (nonatomic, strong) UISegmentedControl *metaDataSegmentedView;
@property (nonatomic, strong) UILabel *bioLabel;

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
  
  [self.view addSubview:self.albumCoverView];
  [self.view addSubview:self.artistNameLabel];
  [self.view addSubview:self.albumNameLabel];
  [self.view addSubview:self.releaseDateLabel];
  [self.view addSubview:self.playCountView];
}

- (void)viewDidLoad{
  [super viewDidLoad];
	
  @weakify(self);
  
  RACBind(self.artistNameLabel.text) = RACBind(self.album.artist.name);
  RACBind(self.albumNameLabel.text) = RACBind(self.album.name);
  [[[RACAbleWithStart(self.album.releaseDate) filter:^BOOL(id value) {
    return (value != nil);
  }] map:^id(NSDate *date) {
    return [date description];
  }] toProperty:@keypath(self.releaseDateLabel.text) onObject:self];
  
  [RACAbleWithStart(self.showingLoading) subscribeNext:^(NSNumber *showingLoading) {
    BOOL isLoading = [showingLoading boolValue];
    @strongify(self);
    if (isLoading){
      self.title = @"Loading...";
    }else{
      self.title = @"Album";
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
  static CGFloat viewHMargin = 10.0f;
  
  ////////////////////////
  // Set width and heights
  self.albumCoverView.width = w;
  self.albumCoverView.height = w;
  
  CGFloat centeredLabelMargin = 10.0f;
  CGFloat centeredLabelWidth = w - centeredLabelMargin * 2;
  [self setLabelSizeForLabel:self.artistNameLabel width:centeredLabelWidth];
  [self setLabelSizeForLabel:self.albumNameLabel width:centeredLabelWidth];
  [self setLabelSizeForLabel:self.releaseDateLabel width:centeredLabelWidth];
  
  self.playCountView.width = w;
  // playCountView sets its own desired height
  
  self.metaDataSegmentedView.width = w;
  // metaDataSegmentedView sets its own desired height
  
  [self setLabelSizeForLabel:self.bioLabel width:centeredLabelWidth];
  
  ////////////////////////
  // Set top positions
  self.albumCoverView.top = t;
  t += self.albumCoverView.height;
  self.artistNameLabel.top = t;
  t += self.artistNameLabel.height;
  self.albumNameLabel.top = t;
  t += self.albumNameLabel.height;
  self.releaseDateLabel.top = t;
  t += self.releaseDateLabel.height;
  self.playCountView.top = t;
  t += self.playCountView.height;
  self.metaDataSegmentedView.top = t;
  t += self.metaDataSegmentedView.height;
  self.bioLabel.top = t;
  t += self.bioLabel.height;
  
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setLabelSizeForLabel:(UILabel *)label width:(CGFloat)width{
  label.width = width;
  label.height = 60.0f;
}

- (UILabel *)artistNameLabel{
  if (!_artistNameLabel){
    _artistNameLabel = [[UILabel alloc] init];
  }
  return _artistNameLabel;
}

- (UILabel *)albumNameLabel{
  if (!_albumNameLabel){
    _albumNameLabel = [[UILabel alloc] init];
  }
  return _albumNameLabel;
}

- (UILabel *)releaseDateLabel{
  if (!_releaseDateLabel){
    _releaseDateLabel = [[UILabel alloc] init];
  }
  return _releaseDateLabel;
}

@end



