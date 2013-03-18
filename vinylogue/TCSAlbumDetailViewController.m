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

#import "TCSAlbumArtDetailView.h"

#import <ReactiveCocoa/ReactiveCocoa.h>
#import <EXTScope.h>
#import <EXTKeyPathCoding.h>

// TEMP
@class TCSAlbumCoverView;
@class TCSPlayCountView;

@interface TCSAlbumDetailViewController ()

// Views
@property (nonatomic, strong) TCSAlbumArtDetailView *albumDetailView;
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
  
  [self.view addSubview:self.albumDetailView];
  [self.view addSubview:self.playCountView];
}

- (void)viewDidLoad{
  [super viewDidLoad];
	
  @weakify(self);
  
  RACBind(self.albumDetailView.artistName) = RACBind(self.album.artist.name);
  RACBind(self.albumDetailView.albumName) = RACBind(self.album.name);
  RACBind(self.albumDetailView.albumReleaseDate) = RACBind(self.album.releaseDate);
  RACBind(self.albumDetailView.albumImageURL) = RACBind(self.album.imageURL);
  
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
  self.albumDetailView.width = w;
  [self.albumDetailView layoutSubviews];
  
  self.playCountView.width = w;
  // playCountView sets its own desired height
  
  self.metaDataSegmentedView.width = w;
  // metaDataSegmentedView sets its own desired height
  
  // TODO: set this width
  [self setLabelSizeForLabel:self.bioLabel width:w];
  
  ////////////////////////
  // Set top positions
  self.albumDetailView.top = t;
  t += self.albumDetailView.height;
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

- (TCSAlbumArtDetailView *)albumDetailView{
  if (!_albumDetailView){
    _albumDetailView = [[TCSAlbumArtDetailView alloc] init];
  }
  return _albumDetailView;
}

@end



