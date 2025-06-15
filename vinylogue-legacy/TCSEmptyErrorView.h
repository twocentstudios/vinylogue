//
//  TCSEmptyErrorView.h
//  vinylogue
//
//  Created by Christopher Trott on 2/20/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TCSEmptyErrorView : NSObject

+ (UIView *)errorViewWithTitle:(NSString *)title
                   actionTitle:(NSString *)actionTitle
                  actionTarget:(id)target
                actionSelector:(SEL)selector;

+ (UIView *)emptyViewWithTitle:(NSString *)title
                      subtitle:(NSString *)subtitle;

@end
