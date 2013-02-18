//
//  TCSLastFMAPIClient.h
//  vinylogue
//
//  Created by Christopher Trott on 2/17/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import "AFRESTClient.h"
#import "AFIncrementalStore.h"

@interface TCSLastFMAPIClient : AFRESTClient <AFIncrementalStoreHTTPClient>

@property (copy) NSString *userName;

+ (TCSLastFMAPIClient *)sharedClient;

@end
