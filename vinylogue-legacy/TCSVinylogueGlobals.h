//
//  TCSVinylogueGlobals.h
//  vinylogue
//
//  Created by Christopher Trott on 2/21/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#ifndef vinylogue_TCSVinylogueGlobals_h
#define vinylogue_TCSVinylogueGlobals_h

// Comment the below line to get non-verbose logs
#define VERBOSE_LOGS

#ifdef DEBUG
  #ifdef VERBOSE_LOGS
    #	define DLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
  #else
    # define DLog(...) NSLog(__VA_ARGS__)
  #endif
#else
  #	define DLog(...)
#endif

#define kTCSUserDefaultsLastFMUserName @"lastFMUserName"
#define kTCSUserDefaultsPlayCountFilter @"playCountFilter"
#define kTCSUserDefaultsLastFMFriendsList @"lastFMFriendsList"

#endif
