//
//  TCSAlbumArtistPlayCountCell.m
//  vinylogue
//
//  Created by Christopher Trott on 2/18/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import "TCSAlbumArtistPlayCountCell.h"

#import "WeeklyAlbumChart.h"
#import "Album.h"
#import "Artist.h"

#import <ReactiveCocoa/ReactiveCocoa.h>
#import <ReactiveCocoa/RACEXTScope.h>
#import <AFNetworking/UIImageView+AFNetworking.h>

static CGFloat marginHorzOut = 12.0f;
static CGFloat marginHorzIn = 9.0f;
static CGFloat marginVertInAlbum = -2.0f;
static CGFloat marginVertInPlays = -10.0f;
static CGFloat imageViewSide = 80.0f;
static CGFloat playsWidth = 50.0f;
static NSString *placeholderImageName = @"recordPlaceholderThumb";

@interface TCSAlbumArtistPlayCountCell ()

@property (nonatomic, strong) UILabel *playCountLabel;
@property (nonatomic, strong) UILabel *playCountTitleLabel;
@property (nonatomic, strong) UILabel *rankLabel;
@property (nonatomic, strong) UIView *backView;
@property (nonatomic, strong) UIView *backSelectedView;

@property (nonatomic, strong) NSString *imageURLCache;

@end

@implementation TCSAlbumArtistPlayCountCell

- (id)init{
  self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:NSStringFromClass([self class])];
  if (self) {
    self.selectionStyle = UITableViewCellSelectionStyleGray;
    
    self.backgroundView = self.backView;
    self.selectedBackgroundView = self.backSelectedView;
        
    [self configureTextLabel];
    [self configureDetailTextLabel];
    [self configureImageView];
    [self.contentView addSubview:self.playCountLabel];
    [self.contentView addSubview:self.playCountTitleLabel];
    [self.contentView addSubview:self.rankLabel];
    
  }
  return self;
}

- (void)prepareForReuse {
  [super prepareForReuse];
  
  self.imageURLCache = nil;
  
//  self.object = nil;
  
//  [self setImageURL:nil];
  
//  self.playCountLabel.text = nil;
//  self.playCountTitleLabel.text = nil;
//  self.textLabel.text = nil;
//  self.detailTextLabel.text = nil;
//  self.rankLabel.text = nil;
//  self.imageView.image = nil;
//
//  [self setNeedsLayout];
}

- (void)setObject:(WeeklyAlbumChart *)object {
  if (_object == object)
    return;
  
  _object = object;
  self.textLabel.text = [object.album.artist.name uppercaseString];
  self.detailTextLabel.text = object.album.name;
  self.playCountLabel.text = [object.playcount stringValue];
  self.rankLabel.text = [object.rank stringValue];
  
  [self refreshImage];

  if (object.playcountValue == 1){
    self.playCountTitleLabel.text = NSLocalizedString(@"play", nil);
  }else{
    self.playCountTitleLabel.text = NSLocalizedString(@"plays", nil);
  }
}


- (void)refreshImage{
  static UIImage *placeHolderImage = nil;
  if (!placeHolderImage)
    placeHolderImage = [UIImage imageNamed:placeholderImageName];
  
  @weakify(self);
  if (self.imageView.image == nil){
    self.imageView.image = placeHolderImage;
  }else if(![self.object.album.imageThumbURL isEqualToString:self.imageURLCache]){
    // prevent setting imageView unnecessarily
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.object.album.imageThumbURL] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:10];
    [self.imageView setImageWithURLRequest:request placeholderImage:placeHolderImage success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
      @strongify(self);
      self.imageView.image = image;
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {

    }];
    self.imageURLCache = self.object.album.imageThumbURL;
  }
}

- (void)layoutSubviews{
  [super layoutSubviews];
  
  const CGRect r = self.contentView.bounds;
  
  // Define widths
  const CGFloat artistAlbumWidth = [[self class] artistAlbumWidthForContentWidth:CGRectGetWidth(r)];
  
  // Calculate and set sizes of controls
  self.imageView.size = CGSizeMake(imageViewSide, imageViewSide);
  
  self.textLabel.size = [self.textLabel.text sizeWithFont:self.textLabel.font constrainedToSize:CGSizeMake(artistAlbumWidth, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
  self.textLabel.width = artistAlbumWidth;
  self.detailTextLabel.size = [self.detailTextLabel.text sizeWithFont:self.detailTextLabel.font constrainedToSize:CGSizeMake(artistAlbumWidth, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
  self.detailTextLabel.width = artistAlbumWidth;
  
  self.playCountLabel.size = [self.playCountLabel.text sizeWithFont:self.playCountLabel.font forWidth:playsWidth lineBreakMode:NSLineBreakByTruncatingTail];
  self.playCountLabel.width = playsWidth;
  self.playCountTitleLabel.size = [self.playCountTitleLabel.text sizeWithFont:self.playCountTitleLabel.font forWidth:playsWidth lineBreakMode:NSLineBreakByTruncatingTail];
  self.playCountTitleLabel.width = playsWidth;
  
  // Lay out horizontally
  CGFloat x = 0;
  x += marginHorzOut;
  self.imageView.left = x;
  x += self.imageView.width;
  x += marginHorzIn;
  self.textLabel.left = x;
  self.detailTextLabel.left = x;
  x += self.textLabel.width;
  x += marginHorzIn;
  self.playCountLabel.left = x;
  self.playCountTitleLabel.left = x;
  x += self.playCountLabel.width;
  x += marginHorzOut;
  NSAssert(x == CGRectGetWidth(r), @"Horizontal layout should traverse to the bounds of the contentView");
  
  // Lay out vertically
  self.imageView.y = CGRectGetMidY(r);
  
  const CGFloat albumArtistVertMargin = (CGRectGetHeight(r) - marginVertInAlbum - self.textLabel.height - self.detailTextLabel.height)/2.0f;
  CGFloat y = 0;
  y += albumArtistVertMargin;
  self.textLabel.top = y;
  y += self.textLabel.height;
  y += marginVertInAlbum;
  self.detailTextLabel.top = y;
  y += self.detailTextLabel.height;
  y += albumArtistVertMargin;
  NSAssert(y == CGRectGetHeight(r), @"Vertical layout should traverse to the bounds of the contentView");
  
  const CGFloat playCountVertMargin = (CGRectGetHeight(r) - marginVertInPlays - self.playCountLabel.height - self.playCountTitleLabel.height)/2.0f;
  y = 0;
  y += playCountVertMargin;
  self.playCountLabel.top = y;
  y += self.playCountLabel.height;
  y += marginVertInPlays;
  self.playCountTitleLabel.top = y;
  y += self.playCountTitleLabel.height;
  y += playCountVertMargin;
    NSAssert(y == CGRectGetHeight(r), @"Vertical layout should traverse to the bounds of the contentView");
  
}

+ (CGFloat)heightForObject:(id)object atIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView{
  WeeklyAlbumChart *chart = (WeeklyAlbumChart *)object;
  
  // Even though this isn't true, we have to assume the tableView.width == cell.contentView.width
  const CGFloat width = tableView.width;
  const CGFloat artistAlbumWidth = [[self class] artistAlbumWidthForContentWidth:width];
  
//  static CGFloat minimumHeight = 70.0f;
  const CGFloat marginVert = 10.0f;
  
  const CGSize artistSize = [chart.album.name sizeWithFont:[[self class] textLabelFont] constrainedToSize:CGSizeMake(artistAlbumWidth, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
  const CGSize albumSize = [chart.album.name sizeWithFont:[[self class] detailTextLabelFont] constrainedToSize:CGSizeMake(artistAlbumWidth, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
  
  const CGFloat artistAlbumHeight = marginVert*2 + artistSize.height + marginVertInAlbum + albumSize.height;
  const CGFloat imageHeight = marginVert*2 + imageViewSide;
  
  return MAX(artistAlbumHeight, imageHeight);
}

+ (CGFloat)artistAlbumWidthForContentWidth:(CGFloat)width{
  return (width - marginHorzOut*2 - marginHorzIn*2 - imageViewSide - playsWidth);
}

# pragma mark - view getters

+ (UIFont *)textLabelFont{ return FONT_AVN_ULTRALIGHT(12); }
+ (UIFont *)detailTextLabelFont{ return FONT_AVN_REGULAR(16); }
+ (UIFont *)playCountLabelFont{ return FONT_AVN_REGULAR(28); }
+ (UIFont *)playCountTitleLabelFont{ return FONT_AVN_ULTRALIGHT(15); }
+ (UIFont *)rankLabelFont{ return [UIFont systemFontOfSize:12]; }

- (void)configureTextLabel{
  self.textLabel.backgroundColor = CLEAR;
  self.textLabel.font = [[self class] textLabelFont];
  self.textLabel.numberOfLines = 0;
  self.textLabel.textColor = BLUE_DARK;
  self.textLabel.shadowColor = WHITEA(0.8f);
  self.textLabel.shadowOffset = SHADOW_TOP;
}

- (void)configureDetailTextLabel{
  self.detailTextLabel.backgroundColor = CLEAR;
  self.detailTextLabel.font = [[self class] detailTextLabelFont];
  self.detailTextLabel.numberOfLines = 0;
  self.detailTextLabel.textColor = BLUE_DARK;
  self.detailTextLabel.shadowColor = BLACKA(0.25f);
  self.detailTextLabel.shadowOffset = SHADOW_BOTTOM;
}

- (void)configureImageView{
  CALayer *layer = [self.imageView layer];
  layer.masksToBounds = YES;
  layer.cornerRadius = 2;
  layer.borderWidth = 1;
  layer.borderColor = [BLACKA(0.2f) CGColor];
//  self.imageView.image = [UIImage imageNamed:@"Default"];
}

- (UILabel *)playCountLabel{
  if (!_playCountLabel){
    _playCountLabel = [[UILabel alloc] init];
    _playCountLabel.font = [[self class] playCountLabelFont];
    _playCountLabel.textAlignment = NSTextAlignmentCenter;
    _playCountLabel.numberOfLines = 1;
    _playCountLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    _playCountLabel.backgroundColor = CLEAR;
    _playCountLabel.textColor = BLUE_BOLD;
    _playCountLabel.shadowColor = WHITEA(0.8f);
    _playCountLabel.shadowOffset = SHADOW_TOP;
  }
  return _playCountLabel;
}

- (UILabel *)playCountTitleLabel{
  if (!_playCountTitleLabel){
    _playCountTitleLabel = [[UILabel alloc] init];
    _playCountTitleLabel.font = [[self class] playCountTitleLabelFont];
    _playCountTitleLabel.textAlignment = NSTextAlignmentCenter;
    _playCountTitleLabel.numberOfLines = 1;
    _playCountTitleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    _playCountTitleLabel.backgroundColor = CLEAR;
    _playCountTitleLabel.textColor = GRAYCOLOR(126);
  }
  return _playCountTitleLabel;
}

- (UILabel *)rankLabel{
  if (!_rankLabel){
    _rankLabel = [[UILabel alloc] init];
    _rankLabel.font = [[self class] rankLabelFont];
  }
  return _rankLabel;
}

- (UIView *)backView{
  if (!_backView){
    _backView = [UIView viewWithDrawRectBlock:^(CGRect rect) {
      CGContextRef c = UIGraphicsGetCurrentContext();
      
      CGRect r = rect;
      
      CGContextSaveGState(c);
      {
        // Fill background
        [WHITE_SUBTLE setFill];
        CGContextFillRect(c, r);
        
        CGFloat borderHeight = 1.0f;
        CGRect topBorder = CGRectMake(CGRectGetMinX(r), CGRectGetMinY(r), CGRectGetWidth(r), borderHeight);
        CGRect bottomBorder = CGRectMake(CGRectGetMinX(r), CGRectGetMaxY(r)-borderHeight, CGRectGetWidth(r), borderHeight);
        
        // Fill top border
        [WHITEA(0.8f) setFill];
        CGContextFillRect(c, topBorder);
        
        // Fill bottom border
        [BLACKA(0.1f) setFill];
        CGContextFillRect(c, bottomBorder);
      }
      CGContextRestoreGState(c);
    }];
  }
  return _backView;
}

- (UIView *)backSelectedView{
  if (!_backSelectedView){
    _backSelectedView = [UIView viewWithDrawRectBlock:^(CGRect rect) {
      CGContextRef c = UIGraphicsGetCurrentContext();
      
      CGRect r = rect;
      
      CGContextSaveGState(c);
      {
        // Fill background
        [BLUE_DARK setFill];
        CGContextFillRect(c, r);
        
        CGFloat borderHeight = 1.0f;
        CGRect topBorder = CGRectMake(CGRectGetMinX(r), CGRectGetMinY(r), CGRectGetWidth(r), borderHeight);
        CGRect bottomBorder = CGRectMake(CGRectGetMinX(r), CGRectGetMaxY(r)-borderHeight, CGRectGetWidth(r), borderHeight);
        
        // Fill top border
        [WHITEA(0.8f) setFill];
        CGContextFillRect(c, topBorder);
        
        // Fill bottom border
        [BLACKA(0.1f) setFill];
        CGContextFillRect(c, bottomBorder);
      }
      CGContextRestoreGState(c);
    }];
  }
  return _backSelectedView;
}


@end
