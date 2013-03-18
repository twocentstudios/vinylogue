//
//  TCSAlbumArtDetailView.m
//  vinylogue
//
//  Created by Christopher Trott on 3/18/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import "TCSAlbumArtDetailView.h"

#import <AFNetworking/UIImageView+AFNetworking.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <EXTScope.h>

@interface TCSAlbumArtDetailView ()

@property (nonatomic, strong) UIImageView *albumImageView;
@property (nonatomic, strong) UIImageView *albumImageBackgroundView;
@property (nonatomic, strong) UILabel *artistNameLabel;
@property (nonatomic, strong) UILabel *albumNameLabel;
@property (nonatomic, strong) UILabel *releaseDateLabel;

@property (nonatomic, strong) NSString *albumReleaseDateString;

@end

@implementation TCSAlbumArtDetailView

- (id)init{
  self = [super initWithFrame:CGRectZero];
  if (self) {
    [self addSubview:self.albumImageBackgroundView];
    [self addSubview:self.albumImageView];
    [self addSubview:self.artistNameLabel];
    [self addSubview:self.albumNameLabel];
    [self addSubview:self.releaseDateLabel];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateStyle = NSDateFormatterLongStyle;
    
    @weakify(self);
    // Set label text
    RAC(self.artistNameLabel.text) = [RACAble(self.artistName) map:^id(NSString *name) {
      return [name uppercaseString];
    }];
    RAC(self.albumNameLabel.text) = RACAble(self.albumName);
    RAC(self.releaseDateLabel.text) = [RACAble(self.albumReleaseDate) map:^id(NSDate *date) {
      NSString *annotatedString = [NSString stringWithFormat:@"Released: %@", [formatter stringFromDate:date]];
      return annotatedString;
    }];
    
    // Set album images
    [[RACAble(self.albumImageURL) map:^id(NSString *imageURLString) {
      return [NSURL URLWithString:imageURLString];
    }] subscribeNext:^(NSURL *imageURL) {
      @strongify(self);
      UIImage *placeholderImage = [UIImage imageNamed:@"placeholder"];
      [self.albumImageView setImageWithURL:imageURL placeholderImage:placeholderImage];
      [self.albumImageBackgroundView setImageWithURL:imageURL placeholderImage:placeholderImage];
      self.albumImageBackgroundView.layer.rasterizationScale = 0.03;
      self.albumImageBackgroundView.layer.shouldRasterize = YES;
    }];
  }
  return self;
}

- (void)layoutSubviews{
  [super layoutSubviews];
  
  CGRect r = self.bounds;
  CGFloat w = CGRectGetWidth(r);
  CGFloat t = CGRectGetMinY(r); // used to set y position and calculate height
  CGFloat centerX = CGRectGetMidX(r);
  static CGFloat viewHMargin = 30.0f;
  static CGFloat imageAndLabelMargin = 14.0f;
  static CGFloat interLabelMargin = -4.0f;
  CGFloat widthWithMargin = w - (viewHMargin * 2);

  // Calculate individual heights and widths
  self.albumImageView.width = widthWithMargin;
  self.albumImageView.height = self.albumImageView.width;
  [self setLabelSizeForLabel:self.artistNameLabel width:widthWithMargin];
  [self setLabelSizeForLabel:self.albumNameLabel width:widthWithMargin];
  [self setLabelSizeForLabel:self.releaseDateLabel width:widthWithMargin];
  
  // Set y position and calculate total height
  self.albumImageBackgroundView.top = t;
  t += viewHMargin;
  self.albumImageView.top = t;
  t += self.albumImageView.height;
  t += imageAndLabelMargin;
  self.artistNameLabel.top = t;
  t += self.artistNameLabel.height;
  t += interLabelMargin;
  self.albumNameLabel.top = t;
  t += self.albumNameLabel.height;
  t += interLabelMargin;
  self.releaseDateLabel.top = t;
  t += self.releaseDateLabel.height;
  t += viewHMargin;
  
  // Then set self.height based on that
  self.albumImageBackgroundView.height = t;
  self.albumImageBackgroundView.width = t;
  
  // self.height depends on component heights
  self.height = t;

  // Set x positions
  self.albumImageBackgroundView.x = centerX;
  self.albumImageView.x = centerX;
  self.artistNameLabel.x = centerX;
  self.albumNameLabel.x = centerX;
  self.releaseDateLabel.x = centerX;
}

- (void)setLabelSizeForLabel:(UILabel *)label width:(CGFloat)width{
  label.size = [label.text sizeWithFont:label.font constrainedToSize:CGSizeMake(width, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
}

- (UIImageView *)albumImageBackgroundView{
  if (!_albumImageBackgroundView){
    _albumImageBackgroundView = [[UIImageView alloc] init];
//    _albumImageBackgroundView.contentMode = UIViewContentModeCenter;
    _albumImageBackgroundView.layer.borderWidth = 4.0f;
    _albumImageBackgroundView.layer.borderColor = [UIColor redColor].CGColor;
    _albumImageBackgroundView.layer.masksToBounds = YES;
//    CIFilter* filter = [CIFilter filterWithName:@"gaussianBlur"];
//    [filter setValue:[NSNumber numberWithFloat:5] forKey:@"inputRadius"];
//    _albumImageBackgroundView.layer.filters = [NSArray arrayWithObject:filter];
  }
  return _albumImageBackgroundView;
}

- (UIImageView *)albumImageView{
  if (!_albumImageView){
    _albumImageView = [[UIImageView alloc] init];
  }
  return _albumImageView;
}

- (UILabel *)artistNameLabel{
  if (!_artistNameLabel){
    _artistNameLabel = [[UILabel alloc] init];
    _artistNameLabel.numberOfLines = 0;
    _artistNameLabel.font = FONT_AVN_REGULAR(15);
    _artistNameLabel.backgroundColor = CLEAR;
    _artistNameLabel.textColor = WHITEA(0.85f);
    _artistNameLabel.shadowColor = BLACKA(0.6f);
    _artistNameLabel.shadowOffset = SHADOW_BOTTOM;
    _artistNameLabel.textAlignment = NSTextAlignmentCenter;
  }
  return _artistNameLabel;
}

- (UILabel *)albumNameLabel{
  if (!_albumNameLabel){
    _albumNameLabel = [[UILabel alloc] init];
    _albumNameLabel.numberOfLines = 0;
    _albumNameLabel.font = FONT_AVN_REGULAR(30);
    _albumNameLabel.backgroundColor = CLEAR;
    _albumNameLabel.textColor = WHITE;
    _albumNameLabel.shadowColor = BLACKA(0.9f);
    _albumNameLabel.shadowOffset = SHADOW_BOTTOM;
    _albumNameLabel.textAlignment = NSTextAlignmentCenter;
  }
  return _albumNameLabel;
}

- (UILabel *)releaseDateLabel{
  if (!_releaseDateLabel){
    _releaseDateLabel = [[UILabel alloc] init];
    _releaseDateLabel.numberOfLines = 0;
    _releaseDateLabel.font = FONT_AVN_REGULAR(13);
    _releaseDateLabel.backgroundColor = CLEAR;
    _releaseDateLabel.textColor = WHITEA(0.7f);
    _releaseDateLabel.shadowColor = BLACKA(0.5f);
    _releaseDateLabel.shadowOffset = SHADOW_BOTTOM;
    _releaseDateLabel.textAlignment = NSTextAlignmentCenter;
  }
  return _releaseDateLabel;
}


@end
