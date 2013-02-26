//
//  NSDictionary+TCSDictionarySafety.h
//  vinylogue
//
//  Created by Christopher Trott on 2/25/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (TCSDictionarySafety)

// If the original returned object is an array, it is returned as is
// If the original returned object is a dictionary, it is added to an array and returned
- (NSArray*)arrayForKey:(id)key;

@end
