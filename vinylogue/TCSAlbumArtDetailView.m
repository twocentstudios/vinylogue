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
#import <ReactiveCocoa/RACEXTScope.h>
#import "UIImage+TCSImageRepresentativeColors.h"
#import "UILabel+TCSLabelSizeCalculations.h"

@interface TCSAlbumArtDetailView ()

@property (nonatomic, strong) UIImageView *albumImageView;
@property (nonatomic, strong) UIImageView *albumImageBackgroundView;
@property (nonatomic, strong) UILabel *artistNameLabel;
@property (nonatomic, strong) UILabel *albumNameLabel;
@property (nonatomic, strong) UILabel *releaseDateLabel;
@property (nonatomic, strong) UIImageView *loadingImageView;

@property (nonatomic, strong) NSString *albumReleaseDateString;

@property (atomic, strong) UIColor *primaryAlbumColor;
@property (atomic, strong) UIColor *secondaryAlbumColor;
@property (atomic, strong) UIColor *textAlbumColor;
@property (atomic, strong) UIColor *textShadowAlbumColor;

@property (atomic) BOOL loadingAlbumImage;

@end

@implementation TCSAlbumArtDetailView

- (id)init{
  self = [super initWithFrame:CGRectZero];
  if (self) {
    self.backgroundColor = BLACKA(0.05);
    self.clipsToBounds = YES;
    
    [self addSubview:self.albumImageBackgroundView];
    [self addSubview:self.albumImageView];
    [self addSubview:self.artistNameLabel];
    [self addSubview:self.albumNameLabel];
    [self addSubview:self.releaseDateLabel];
    [self addSubview:self.loadingImageView];
    
    self.loadingAlbumImage = NO;
    UIImage *placeholderImage = [UIImage imageNamed:@"recordPlaceholder"];
    self.albumImageView.image = placeholderImage;
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateStyle = NSDateFormatterLongStyle;
    
    @weakify(self);
    // Set label text
    RAC(self.artistNameLabel, text) = [RACObserve(self, artistName) map:^id(NSString *name) {
      return [name uppercaseString];
    }];
    RAC(self.albumNameLabel, text) = RACObserve(self, albumName);
    RAC(self.releaseDateLabel, text) = [RACObserve(self, albumReleaseDate) map:^id(NSDate *date) {
      if (date != nil){
        NSString *annotatedString = [NSString stringWithFormat:@"Released: %@", [formatter stringFromDate:date]];
        return annotatedString;
      }else{
        return @"";
      }
    }];
    
    // Set album images
    RACSignal *albumImageURLSignal = RACObserve(self, albumImageURL);
    [[[[albumImageURLSignal filter:^BOOL(NSString *imageURLString) {
      return ((imageURLString != nil) && (![imageURLString isEqualToString:@""]));
    }] map:^id(NSString *imageURLString) {
      return [NSURL URLWithString:imageURLString];
    }] deliverOn:[RACScheduler mainThreadScheduler]]
     subscribeNext:^(NSURL *imageURL) {
       @strongify(self);
       self.loadingAlbumImage = YES;
       NSURLRequest *request = [NSURLRequest requestWithURL:imageURL cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:10];
       [self.albumImageView setImageWithURLRequest:request placeholderImage:self.albumImageView.image success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
         @strongify(self);
         self.albumImageView.image = image;
         self.albumImageBackgroundView.image = image;
         self.albumImageBackgroundView.layer.rasterizationScale = 0.03;
         self.albumImageBackgroundView.layer.shouldRasterize = YES;
         
         // Calculate album image derived colors on background thread
         [[RACScheduler scheduler] schedule:^{
           @strongify(self);
           RACTuple *t = [image getRepresentativeColors];
           self.primaryAlbumColor = t.first;
           self.secondaryAlbumColor = t.second;
           self.textAlbumColor = t.fourth;
           self.textShadowAlbumColor = t.fifth;
         }];
         self.loadingAlbumImage = NO;
       } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
         @strongify(self);
         self.loadingAlbumImage = NO;
       }];
     }];
      
    // Set label text colors when the album derived color changes
    [[RACObserve(self, textAlbumColor)
      deliverOn:[RACScheduler mainThreadScheduler]]
     subscribeNext:^(UIColor *color) {
      @strongify(self);
      self.artistNameLabel.textColor = COLORA(color, 0.85);
      self.albumNameLabel.textColor = color;
      self.releaseDateLabel.textColor = COLORA(color, 0.7);
    }];
    
    [[RACObserve(self, textShadowAlbumColor)
      deliverOn:[RACScheduler mainThreadScheduler]]
     subscribeNext:^(UIColor *color) {
       @strongify(self);
      self.artistNameLabel.shadowColor = COLORA(color, 0.85);
      self.albumNameLabel.shadowColor = color;
      self.releaseDateLabel.shadowColor = COLORA(color, 0.7);
    }];
    
    [[RACObserve(self, loadingAlbumImage) deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(NSNumber *loadingNumber) {
      BOOL loading = [loadingNumber boolValue];
      @strongify(self);
      if (loading){
        self.loadingImageView.hidden = NO;
        [self.loadingImageView startAnimating];
      }else{
        self.loadingImageView.hidden = YES;
        [self.loadingImageView stopAnimating];
      }
    }];
  }
  return self;
}

- (void)layoutSubviews{
  [super layoutSubviews];
  
  const CGRect r = self.bounds;
  const CGFloat w = CGRectGetWidth(r);
  CGFloat t = CGRectGetMinY(r); // used to set y position and calculate height
  const CGFloat centerX = CGRectGetMidX(r);
  const CGFloat viewHMargin = 30.0f;
  const CGFloat imageAndLabelMargin = 14.0f;
  const CGFloat interLabelMargin = -1.0f;
  const CGFloat widthWithMargin = w - (viewHMargin * 2);

  // Calculate individual heights and widths
  self.loadingImageView.x = centerX;
  self.albumImageView.width = widthWithMargin;
  self.albumImageView.height = self.albumImageView.width;
  [self setLabelSizeForLabel:self.artistNameLabel width:widthWithMargin];
  [self setLabelSizeForLabel:self.albumNameLabel width:widthWithMargin];
  [self setLabelSizeForLabel:self.releaseDateLabel width:widthWithMargin];
  
  // Set y position and calculate total height
  self.loadingImageView.y = t;
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

- (void)drawRect:(CGRect)rect{
  CGContextRef c = UIGraphicsGetCurrentContext();
  
  const CGRect r = rect;
  
  CGContextSaveGState(c);
  {
    // Fill background
    [self.backgroundColor setFill];
    CGContextFillRect(c, r);
    
    const CGFloat borderHeight = 1.0f;
    CGRect topBorder = CGRectMake(CGRectGetMinX(r), CGRectGetMinY(r), CGRectGetWidth(r), borderHeight);
    CGRect bottomBorder = CGRectMake(CGRectGetMinX(r), CGRectGetMaxY(r)-borderHeight, CGRectGetWidth(r), borderHeight);
    
    // Fill top & bottom border (inset)
    [BLACKA(0.1f) setFill];
    CGContextFillRect(c, topBorder);
    CGContextFillRect(c, bottomBorder);
  }
  CGContextRestoreGState(c);
}

- (UIImageView *)albumImageBackgroundView{
  if (!_albumImageBackgroundView){
    _albumImageBackgroundView = [[UIImageView alloc] init];
    _albumImageBackgroundView.layer.masksToBounds = YES;
    _albumImageBackgroundView.clipsToBounds = YES;
    _albumImageBackgroundView.alpha = 0.2f;
  }
  return _albumImageBackgroundView;
}

- (UIImageView *)albumImageView{
  if (!_albumImageView){
    _albumImageView = [[UIImageView alloc] init];
//    _albumImageView.layer.masksToBounds = YES;
//    _albumImageView.layer.cornerRadius = 4; // Can't do this yet until we can mask it without removing the shadow
    _albumImageView.layer.borderWidth = 1;
    _albumImageView.layer.borderColor = BLACKA(0.2f).CGColor;
    _albumImageView.layer.shadowColor = BLACK.CGColor;
    _albumImageView.layer.shadowOffset = CGSizeMake(0, 1);
    _albumImageView.layer.shadowOpacity = 0.2f;
  }
  return _albumImageView;
}

- (UILabel *)artistNameLabel{
  if (!_artistNameLabel){
    _artistNameLabel = [[UILabel alloc] init];
    _artistNameLabel.numberOfLines = 0;
    _artistNameLabel.font = FONT_AVN_REGULAR(15);
    _artistNameLabel.backgroundColor = CLEAR;
    _artistNameLabel.shadowOffset = SHADOW_BOTTOM;
    _artistNameLabel.textAlignment = NSTextAlignmentCenter;
  }
  return _artistNameLabel;
}

- (UILabel *)albumNameLabel{
  if (!_albumNameLabel){
    _albumNameLabel = [[UILabel alloc] init];
    _albumNameLabel.numberOfLines = 0;
    _albumNameLabel.font = FONT_AVN_DEMIBOLD(30);
    _albumNameLabel.backgroundColor = CLEAR;
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
    _releaseDateLabel.shadowOffset = SHADOW_BOTTOM;
    _releaseDateLabel.textAlignment = NSTextAlignmentCenter;
  }
  return _releaseDateLabel;
}

// Spinning record animation
- (UIImageView *)loadingImageView{
  if (!_loadingImageView){
    _loadingImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    NSMutableArray *animationImages = [NSMutableArray arrayWithCapacity:12];
    for (int i = 1; i < 13; i++){
      [animationImages addObject:[UIImage imageNamed:[NSString stringWithFormat:@"loading%02i", i]]];
    }
    [_loadingImageView setAnimationImages:animationImages];
    _loadingImageView.animationDuration = 0.5f;
    _loadingImageView.animationRepeatCount = 0;
  }
  return _loadingImageView;
}

@end
