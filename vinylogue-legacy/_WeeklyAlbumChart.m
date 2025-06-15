// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to WeeklyAlbumChart.m instead.

#import "_WeeklyAlbumChart.h"

const struct WeeklyAlbumChartAttributes WeeklyAlbumChartAttributes = {
	.albumImageURL = @"albumImageURL",
	.albumMbid = @"albumMbid",
	.albumName = @"albumName",
	.albumURL = @"albumURL",
	.artistMbid = @"artistMbid",
	.artistName = @"artistName",
	.playcount = @"playcount",
	.rank = @"rank",
};

const struct WeeklyAlbumChartRelationships WeeklyAlbumChartRelationships = {
	.weeklyChart = @"weeklyChart",
};

const struct WeeklyAlbumChartFetchedProperties WeeklyAlbumChartFetchedProperties = {
};

@implementation WeeklyAlbumChartID
@end

@implementation _WeeklyAlbumChart

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"WeeklyAlbumChart" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"WeeklyAlbumChart";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"WeeklyAlbumChart" inManagedObjectContext:moc_];
}

- (WeeklyAlbumChartID*)objectID {
	return (WeeklyAlbumChartID*)[super objectID];
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"playcountValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"playcount"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"rankValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"rank"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}

	return keyPaths;
}




@dynamic albumImageURL;






@dynamic albumMbid;






@dynamic albumName;






@dynamic albumURL;






@dynamic artistMbid;






@dynamic artistName;






@dynamic playcount;



- (int16_t)playcountValue {
	NSNumber *result = [self playcount];
	return [result shortValue];
}

- (void)setPlaycountValue:(int16_t)value_ {
	[self setPlaycount:[NSNumber numberWithShort:value_]];
}

- (int16_t)primitivePlaycountValue {
	NSNumber *result = [self primitivePlaycount];
	return [result shortValue];
}

- (void)setPrimitivePlaycountValue:(int16_t)value_ {
	[self setPrimitivePlaycount:[NSNumber numberWithShort:value_]];
}





@dynamic rank;



- (int16_t)rankValue {
	NSNumber *result = [self rank];
	return [result shortValue];
}

- (void)setRankValue:(int16_t)value_ {
	[self setRank:[NSNumber numberWithShort:value_]];
}

- (int16_t)primitiveRankValue {
	NSNumber *result = [self primitiveRank];
	return [result shortValue];
}

- (void)setPrimitiveRankValue:(int16_t)value_ {
	[self setPrimitiveRank:[NSNumber numberWithShort:value_]];
}





@dynamic weeklyChart;

	






@end
