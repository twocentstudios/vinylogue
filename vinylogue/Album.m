//
//  Album.m
//  vinylogue
//
//  Created by Christopher Trott on 3/15/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import "Album.h"

#import "Artist.h"

@implementation Album

+ (id)objectFromExternalDictionary:(NSDictionary *)dict{
  Album *newAlbum = [[Album alloc] init];
  [newAlbum populateFromExternalDictionary:dict];
  return newAlbum;
}

- (void)populateFromExternalDictionary:(NSDictionary *)dict{
  // Populate new data into the original album object
  
  if (!self.artist){
    self.artist = [[Artist alloc] init];
  }
  self.artist.name = [dict objectForKey:@"artist"];
  self.name = [dict objectForKey:@"name"];
  self.lastFMid = [dict objectForKey:@"id"];
  self.mbid = [dict objectForKey:@"mbid"];
  self.url = [dict objectForKey:@"url"];
  self.releaseDate = TCSDateByParsingLastFMAlbumReleaseDateString([dict objectForKey:@"releasedate"]);
  self.totalPlayCount = @([[dict objectForKey:@"userplaycount"] integerValue]);
  
  // Process image array
  NSArray *imageArray = [dict objectForKey:@"image"];
  NSString *imageThumbURL, *imageURL;
  TCSSetImageURLsForThumbAndImage(imageArray, &imageThumbURL, &imageURL);
  self.imageThumbURL = imageThumbURL;
  self.imageURL = imageURL;
  
  // Album about text
  self.about = [[dict objectForKey:@"wiki"] objectForKey:@"content"];
  self.about = TCSStringByStrippingHTMLTagsFromString(self.about);
  
  // Indicates Album object is complete
  self.detailLoaded = YES;
}

@end
