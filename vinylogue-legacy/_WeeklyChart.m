// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to WeeklyChart.m instead.

#import "_WeeklyChart.h"

const struct WeeklyChartAttributes WeeklyChartAttributes = {
	.from = @"from",
	.to = @"to",
};

const struct WeeklyChartRelationships WeeklyChartRelationships = {
	.weeklyAlbumChart = @"weeklyAlbumChart",
};

const struct WeeklyChartFetchedProperties WeeklyChartFetchedProperties = {
};

@implementation WeeklyChartID
@end

@implementation _WeeklyChart

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"WeeklyChart" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"WeeklyChart";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"WeeklyChart" inManagedObjectContext:moc_];
}

- (WeeklyChartID*)objectID {
	return (WeeklyChartID*)[super objectID];
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	

	return keyPaths;
}




@dynamic from;






@dynamic to;






@dynamic weeklyAlbumChart;

	
- (NSMutableSet*)weeklyAlbumChartSet {
	[self willAccessValueForKey:@"weeklyAlbumChart"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"weeklyAlbumChart"];
  
	[self didAccessValueForKey:@"weeklyAlbumChart"];
	return result;
}
	






@end
