//
//  TCSAlbumDetailViewController.h
//  vinylogue
//
//  Created by Christopher Trott on 3/15/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Album;
@class User;

@interface TCSAlbumDetailViewController : UIViewController

- (id)initWithAlbum:(Album *)album;
- (id)initWithAlbum:(Album *)album user:(User *)user;

@end
