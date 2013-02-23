//
//  TCSinglePageWebViewController.h
//  InterestingThings
//
//  Created by Christopher Trott on 2/12/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TCSSinglePageWebViewController : UIViewController <UIWebViewDelegate>

// Open a single page from a URL on the internet
- (id)initWithRemoteURLString:(NSString *)remoteURL;

// Open a single html file from the app bundle. File name should NOT include ".html".
- (id)initWithLocalHTMLFileName:(NSString *)htmlFileNameWithoutExtension;

@end
