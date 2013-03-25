//
//  TCSAlbumAboutDetailView.h
//  vinylogue
//
//  Created by Christopher Trott on 3/19/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TCSAlbumAboutDetailView : UIView

// Views
@property (nonatomic, readonly) UILabel *headerLabel;
@property (nonatomic, readonly) UILabel *contentLabel;

// Data properties tied to views
@property (nonatomic, strong) NSString *header;
@property (nonatomic, strong) NSString *content;
@property (nonatomic, strong) UIColor *labelTextColor;
@property (nonatomic, strong) UIColor *labelTextShadowColor;

@end
