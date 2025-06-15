//
//  TCSAlbumArtDetailView.h
//  vinylogue
//
//  Created by Christopher Trott on 3/18/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RACTuple;

@interface TCSAlbumArtDetailView : UIView

@property (nonatomic, readonly) UIImageView *albumImageView;
@property (nonatomic, readonly) UIImageView *albumImageBackgroundView;
@property (nonatomic, readonly) UILabel *artistNameLabel;
@property (nonatomic, readonly) UILabel *albumNameLabel;
@property (nonatomic, readonly) UILabel *releaseDateLabel;

// Data properties tied to views
@property (nonatomic, strong) NSString *albumImageURL;
@property (nonatomic, strong) NSString *artistName;
@property (nonatomic, strong) NSString *albumName;
@property (nonatomic, strong) NSDate *albumReleaseDate;

// Colors derived from album image
@property (atomic, readonly) UIColor *primaryAlbumColor;
@property (atomic, readonly) UIColor *secondaryAlbumColor;
@property (atomic, readonly) UIColor *textAlbumColor;
@property (atomic, readonly) UIColor *textShadowAlbumColor;

@end
