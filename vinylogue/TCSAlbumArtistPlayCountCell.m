//
//  TCSAlbumArtistPlayCountCell.m
//  vinylogue
//
//  Created by Christopher Trott on 2/18/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import "TCSAlbumArtistPlayCountCell.h"

#import "WeeklyAlbumChart.h"

@interface TCSAlbumArtistPlayCountCell ()

@property (nonatomic, strong) UILabel *playCountLabel;
@property (nonatomic, strong) UILabel *playCountTitleLabel;
@property (nonatomic, strong) UILabel *rankLabel;

@end

@implementation TCSAlbumArtistPlayCountCell

- (id)init{
  self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:NSStringFromClass([self class])];
  if (self) {
    self.contentView.backgroundColor = [UIColor redColor];
    
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
  
  self.playCountLabel.text = nil;
  self.playCountTitleLabel.text = nil;
  self.textLabel.text = nil;
  self.detailTextLabel.text = nil;
  self.rankLabel.text = nil;
  self.imageView.image = nil;
  
  [self setNeedsLayout];
}

- (void)setObject:(WeeklyAlbumChart *)object {
  self.textLabel.text = object.artistName;
  self.detailTextLabel.text = object.albumName;
  self.playCountLabel.text = [object.playcount stringValue];
  self.rankLabel.text = [object.rank stringValue];
  if (object.playcountValue == 1){
    self.playCountTitleLabel.text = NSLocalizedString(@"play", nil);
  }else{
    self.playCountTitleLabel.text = NSLocalizedString(@"plays", nil);
  }
}

- (void)layoutSubviews{
  [super layoutSubviews];
  
}

+ (CGFloat)heightForObject:(id)object atIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView{
  return 0;
}

- (void)configureTextLabel{

}

- (void)configureDetailTextLabel{
  
}

- (void)configureImageView{
  CALayer *layer = self.imageView.layer;
  layer.cornerRadius = 4;
}

- (UILabel *)playCountLabel{
  if (!_playCountLabel){
    _playCountLabel = [[UILabel alloc] init];
  }
  return _playCountLabel;
}

- (UILabel *)playCountTitleLabel{
  if (!_playCountTitleLabel){
    _playCountTitleLabel = [[UILabel alloc] init];
  }
  return _playCountTitleLabel;
}

- (UILabel *)rankLabel{
  if (!_rankLabel){
    _rankLabel = [[UILabel alloc] init];
  }
  return _rankLabel;
}

@end
