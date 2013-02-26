//
//  NSDictionary+TCSDictionarySafety.m
//  vinylogue
//
//  Created by Christopher Trott on 2/25/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import "NSDictionary+TCSDictionarySafety.h"

@implementation NSDictionary (TCSDictionarySafety)

- (NSArray*)arrayForKey:(id)key{
  id obj = [self objectForKey:key];
  if ([obj isKindOfClass:[NSArray class]]){
    return obj;
  }else if ([obj isKindOfClass:[NSDictionary class]]){
    return @[ obj ];
  }else if (obj != nil){
    // Not sure if we should return nil here...
    return @[ obj ];
  }else{
    return nil;
  }
}

@end
