

@class WeeklyChart;
@class User;
@class Album;

@interface WeeklyAlbumChart : NSObject

@property (nonatomic, strong) Album *album;
@property (nonatomic, strong) NSNumber *playcount;
@property (nonatomic, strong) NSNumber *rank;
@property (nonatomic, strong) WeeklyChart *weeklyChart;
@property (nonatomic, strong) User *user;

- (NSInteger)playcountValue;

@end
