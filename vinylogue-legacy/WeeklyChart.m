#import "WeeklyChart.h"

@implementation WeeklyChart

+ (id)objectFromExternalDictionary:(NSDictionary *)dict{
  WeeklyChart *chart = [[WeeklyChart alloc] init];
  chart.from = [NSDate dateWithTimeIntervalSince1970:[[dict objectForKey:@"from"] doubleValue]];
  chart.to = [NSDate dateWithTimeIntervalSince1970:[[dict objectForKey:@"to"] doubleValue]];
  return chart;
}

@end