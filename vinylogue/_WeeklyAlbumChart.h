// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to WeeklyAlbumChart.h instead.

#import <CoreData/CoreData.h>


extern const struct WeeklyAlbumChartAttributes {
	__unsafe_unretained NSString *albumImageURL;
	__unsafe_unretained NSString *albumMbid;
	__unsafe_unretained NSString *albumName;
	__unsafe_unretained NSString *albumURL;
	__unsafe_unretained NSString *artistMbid;
	__unsafe_unretained NSString *artistName;
	__unsafe_unretained NSString *playcount;
	__unsafe_unretained NSString *rank;
} WeeklyAlbumChartAttributes;

extern const struct WeeklyAlbumChartRelationships {
	__unsafe_unretained NSString *weeklyChart;
} WeeklyAlbumChartRelationships;

extern const struct WeeklyAlbumChartFetchedProperties {
} WeeklyAlbumChartFetchedProperties;

@class WeeklyChart;










@interface WeeklyAlbumChartID : NSManagedObjectID {}
@end

@interface _WeeklyAlbumChart : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (WeeklyAlbumChartID*)objectID;




@property (nonatomic, strong) NSString* albumImageURL;


//- (BOOL)validateAlbumImageURL:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* albumMbid;


//- (BOOL)validateAlbumMbid:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* albumName;


//- (BOOL)validateAlbumName:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* albumURL;


//- (BOOL)validateAlbumURL:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* artistMbid;


//- (BOOL)validateArtistMbid:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* artistName;


//- (BOOL)validateArtistName:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* playcount;


@property int16_t playcountValue;
- (int16_t)playcountValue;
- (void)setPlaycountValue:(int16_t)value_;

//- (BOOL)validatePlaycount:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* rank;


@property int16_t rankValue;
- (int16_t)rankValue;
- (void)setRankValue:(int16_t)value_;

//- (BOOL)validateRank:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) WeeklyChart* weeklyChart;

//- (BOOL)validateWeeklyChart:(id*)value_ error:(NSError**)error_;





@end

@interface _WeeklyAlbumChart (CoreDataGeneratedAccessors)

@end

@interface _WeeklyAlbumChart (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveAlbumImageURL;
- (void)setPrimitiveAlbumImageURL:(NSString*)value;




- (NSString*)primitiveAlbumMbid;
- (void)setPrimitiveAlbumMbid:(NSString*)value;




- (NSString*)primitiveAlbumName;
- (void)setPrimitiveAlbumName:(NSString*)value;




- (NSString*)primitiveAlbumURL;
- (void)setPrimitiveAlbumURL:(NSString*)value;




- (NSString*)primitiveArtistMbid;
- (void)setPrimitiveArtistMbid:(NSString*)value;




- (NSString*)primitiveArtistName;
- (void)setPrimitiveArtistName:(NSString*)value;




- (NSNumber*)primitivePlaycount;
- (void)setPrimitivePlaycount:(NSNumber*)value;

- (int16_t)primitivePlaycountValue;
- (void)setPrimitivePlaycountValue:(int16_t)value_;




- (NSNumber*)primitiveRank;
- (void)setPrimitiveRank:(NSNumber*)value;

- (int16_t)primitiveRankValue;
- (void)setPrimitiveRankValue:(int16_t)value_;





- (WeeklyChart*)primitiveWeeklyChart;
- (void)setPrimitiveWeeklyChart:(WeeklyChart*)value;


@end
