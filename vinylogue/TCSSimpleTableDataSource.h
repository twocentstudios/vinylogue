//
//  TCSimpleTableDataSource.h
//  InterestingThings
//
//  Created by Christopher Trott on 2/8/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kTCSimpleTableTypeKey @"type"
  #define kTCSimpleTableHeaderKey @"header"
  #define kTCSimpleTableCellKey @"cell"
  #define kTCSimpleTableFooterKey @"footer"
#define kTCSimpleTableTitle @"title"
#define kTCSimpleTableSelector @"selector"

@protocol TCSSimpleCell <NSObject>

- (void)setTitleText:(NSString *)text;
+ (UIFont *)font;

@end

@interface TCSSimpleTableDataSource : NSObject <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) id controller;

@property (readonly) NSArray *tableLayout;

@property (nonatomic, strong) Class cellClass;
@property (nonatomic, strong) Class tableHeaderViewClass;
@property (nonatomic, strong) Class tableFooterViewClass;

@property (nonatomic) CGFloat cellVerticalMargin;
@property (nonatomic) CGFloat headerVerticalMargin;
@property (nonatomic) CGFloat footerVerticalMargin;

- (id)initWithTableLayout:(NSArray *)tableLayout;
- (id)initWithTableLayout:(NSArray *)tableLayout controller:(id)controller;

@end
