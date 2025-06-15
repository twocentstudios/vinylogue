//
//  LastFMObject.h
//  vinylogue
//
//  Created by Christopher Trott on 3/20/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LastFMObject : NSObject

+ (id)objectFromExternalDictionary:(NSDictionary *)dict;

void TCSSetImageURLsForThumbAndImage(NSArray *imageArray, NSString **imageThumbURL, NSString **imageURL);
NSString *TCSStringByStrippingHTMLTagsFromString(NSString *htmlString);
NSDate *TCSDateByParsingLastFMAlbumReleaseDateString(NSString *dateString);

@end
