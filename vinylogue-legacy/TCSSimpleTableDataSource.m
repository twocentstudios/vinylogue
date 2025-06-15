//
//  TCSimpleTableDataSource.m
//  InterestingThings
//
//  Created by Christopher Trott on 2/8/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import "TCSSimpleTableDataSource.h"

@interface TCSSimpleTableDataSource ()

@property (strong) NSArray *tableLayout;

@end

@implementation TCSSimpleTableDataSource

#pragma mark - NSObject

- (id)initWithTableLayout:(NSArray *)tableLayout controller:(id)controller{
  self = [super init];
  if (self) {
    self.tableLayout = tableLayout;
    self.cellClass = [UITableViewCell class];
    self.tableHeaderViewClass = [UITableViewCell class];
    self.tableFooterViewClass = [UITableViewCell class];
    self.cellVerticalMargin = 10;
    self.headerVerticalMargin = 10;
    self.footerVerticalMargin = 8;
    self.controller = controller;
  }
  return self;
}

- (id)initWithTableLayout:(NSArray *)tableLayout{
  return [self initWithTableLayout:tableLayout controller:nil];
}

#pragma mark - Table structure parsing

- (NSDictionary *)dictionaryForRow:(NSInteger)row{
  return [self.tableLayout objectAtIndex:(NSUInteger)row];
}

- (NSString *)cellTypeForRow:(NSInteger)row{
  return [[self dictionaryForRow:row] objectForKey:kTCSimpleTableTypeKey];
}

- (NSString *)cellTitleForRow:(NSInteger)row{
  return [[self dictionaryForRow:row] objectForKey:kTCSimpleTableTitle];
}

- (SEL)cellSelectorForRow:(NSInteger)row{
  NSString *selString = [[self dictionaryForRow:row] objectForKey:kTCSimpleTableSelector];
  return NSSelectorFromString(selString);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
  return [self.tableLayout count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
  NSInteger row = indexPath.row;
  NSString *type = [self cellTypeForRow:row];
  
  NSString *reuseIdentifer = type;
  UITableViewCell <TCSSimpleCell> *cell;
  Class cellClass;
  if ([type isEqualToString:kTCSimpleTableHeaderKey]){
    cellClass = self.tableHeaderViewClass;
  }else if([type isEqualToString:kTCSimpleTableFooterKey]){
    cellClass = self.tableFooterViewClass;
  }else{ //if type == Cell
    cellClass = self.cellClass;
  }
  
  cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifer];
  if (!cell) {
    cell = [[cellClass alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifer];
  }
  
  [cell setTitleText:[self cellTitleForRow:row]];
  
  return cell;
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
  NSInteger row = indexPath.row;
  NSString *type = [self cellTypeForRow:row];
  
  Class cellClass;
  CGFloat verticalMargin;
  if ([type isEqualToString:kTCSimpleTableHeaderKey]){
    cellClass = self.tableHeaderViewClass;
    verticalMargin = self.headerVerticalMargin;
  }else if([type isEqualToString:kTCSimpleTableFooterKey]){
    cellClass = self.tableFooterViewClass;
    verticalMargin = self.footerVerticalMargin;
  }else{ //if type == Cell
    cellClass = self.cellClass;
    verticalMargin = self.cellVerticalMargin;
  }
  
  UIFont *font = [(id <TCSSimpleCell>)cellClass font];
  NSString *text = [self cellTitleForRow:row];
  CGFloat textHeight = [text sizeWithFont:font constrainedToSize:CGSizeMake(tableView.width, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping].height;
  if (textHeight > 0){
    return textHeight + verticalMargin * 2;
  }else{
    return 0;
  }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
  SEL selector = [self cellSelectorForRow:indexPath.row];
  id cell = [tableView cellForRowAtIndexPath:indexPath];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
  if ([self.controller respondsToSelector:selector]){
    [self.controller performSelector:selector withObject:cell];
  }
#pragma clang diagnostic pop
  
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath{
  BOOL shouldHighlight = NO;
  
  SEL selector = [self cellSelectorForRow:indexPath.row];
  if (selector != nil){
    shouldHighlight = YES;
  }
  
  return shouldHighlight;
}

#pragma mark - setters

- (void)setCellClass:(Class)cellClass{
  if ([cellClass isSubclassOfClass:[UITableViewCell class]]) {
    _cellClass = cellClass;
  }
}

- (void)setTableHeaderViewClass:(Class)tableHeaderViewClass{
  if ([tableHeaderViewClass isSubclassOfClass:[UITableViewCell class]]){
    _tableHeaderViewClass = tableHeaderViewClass;
  }
}

- (void)setTableFooterViewClass:(Class)tableFooterViewClass{
  if ([tableFooterViewClass isSubclassOfClass:[UITableViewCell class]]){
    _tableFooterViewClass = tableFooterViewClass;
  }
}

@end
