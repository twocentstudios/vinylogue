//
//  TCSUserNameViewController.h
//  vinylogue
//
//  Created by Christopher Trott on 2/21/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RACSubject;

@interface TCSUserNameViewController : UIViewController <UITextFieldDelegate>

@property (nonatomic) BOOL showHeader;
@property (nonatomic, strong) RACSubject *userSignal;

- (id)initWithHeaderShowing:(BOOL)showingHeader;
- (id)initWithUserName:(NSString *)userName headerShowing:(BOOL)showingHeader;

@end
