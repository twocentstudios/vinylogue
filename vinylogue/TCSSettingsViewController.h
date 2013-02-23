//
//  TCSSettingsViewController.h
//  vinylogue
//
//  Created by Christopher Trott on 2/21/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <StoreKit/StoreKit.h>

@class RACSubject;

@interface TCSSettingsViewController : UIViewController <MFMailComposeViewControllerDelegate, SKStoreProductViewControllerDelegate>

@property (nonatomic, strong) RACSubject *playCountFilterSignal;

- (id)initWithPlayCountFilter:(NSUInteger)playCountFilter;

@end
