// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to WeeklyChart.h instead.

#import <CoreData/CoreData.h>


extern const struct WeeklyChartAttributes {
	__unsafe_unretained NSString *from;
	__unsafe_unretained NSString *to;
} WeeklyChartAttributes;

extern const struct WeeklyChartRelationships {
	__unsafe_unretained NSString *weeklyAlbumChart;
} WeeklyChartRelationships;

extern const struct WeeklyChartFetchedProperties {
} WeeklyChartFetchedProperties;

@class WeeklyAlbumChart;




@interface WeeklyChartID : NSManagedObjectID {}
@end

@interface _WeeklyChart : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (WeeklyChartID*)objectID;




@property (nonatomic, strong) NSDate* from;


//- (BOOL)validateFrom:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSDate* to;


//- (BOOL)validateTo:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSSet* weeklyAlbumChart;

- (NSMutableSet*)weeklyAlbumChartSet;





@end

@interface _WeeklyChart (CoreDataGeneratedAccessors)

- (void)addWeeklyAlbumChart:(NSSet*)value_;
- (void)removeWeeklyAlbumChart:(NSSet*)value_;
- (void)addWeeklyAlbumChartObject:(WeeklyAlbumChart*)value_;
- (void)removeWeeklyAlbumChartObject:(WeeklyAlbumChart*)value_;

@end

@interface _WeeklyChart (CoreDataGeneratedPrimitiveAccessors)


- (NSDate*)primitiveFrom;
- (void)setPrimitiveFrom:(NSDate*)value;




- (NSDate*)primitiveTo;
- (void)setPrimitiveTo:(NSDate*)value;





- (NSMutableSet*)primitiveWeeklyAlbumChart;
- (void)setPrimitiveWeeklyAlbumChart:(NSMutableSet*)value;


@end
