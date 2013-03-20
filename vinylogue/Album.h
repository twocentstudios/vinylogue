//
//  Album.h
//  vinylogue
//
//  Created by Christopher Trott on 3/15/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Artist;
@class WeeklyAlbumChart;

@interface Album : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSString *imageURL;
@property (nonatomic, strong) NSString *imageThumbURL;
@property (nonatomic, strong) NSString *mbid;
@property (nonatomic, strong) NSString *lastFMid;
@property (nonatomic, strong) NSDate *releaseDate;
@property (nonatomic, strong) Artist *artist;
@property (nonatomic, weak) WeeklyAlbumChart *weeklyAlbumChart;
@property (nonatomic, strong) NSNumber *totalPlayCount;
@property (nonatomic, strong) NSString *about;

// YES if album info was loaded from primary source (getAlbumInfo)
@property (nonatomic) BOOL detailLoaded;

@end
