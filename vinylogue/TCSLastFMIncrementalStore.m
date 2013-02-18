//
//  TCSLastFMIncrementalStore.m
//  vinylogue
//
//  Created by Christopher Trott on 2/17/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import "TCSLastFMIncrementalStore.h"
#import "TCSLastFMAPIClient.h"

@implementation TCSLastFMIncrementalStore

+ (void)initialize {
  [NSPersistentStoreCoordinator registerStoreClass:self forStoreType:[self type]];
}

+ (NSString *)type {
  return NSStringFromClass(self);
}

+ (NSManagedObjectModel *)model {
  return [[NSManagedObjectModel alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"vinylogue" withExtension:@"xcdatamodeld"]];
}

- (id<AFIncrementalStoreHTTPClient>)HTTPClient {
  return [TCSLastFMAPIClient sharedClient];
}

@end
