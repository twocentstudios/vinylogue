//
//  Artist.h
//  vinylogue
//
//  Created by Christopher Trott on 3/15/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Artist : NSObject

@property (nonatomic, strong) NSString *mbid;
@property (nonatomic, strong) NSString *name;

// YES if album info was loaded from primary source (getArtistInfo)
@property (nonatomic) BOOL detailLoaded;

@end
