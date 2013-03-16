

@class WeeklyChart;
@class User;
@class Album;

@interface WeeklyAlbumChart : NSObject

//@property (nonatomic, strong) NSString *albumImageURL;
//@property (nonatomic, strong) NSString *albumMbid;
//@property (nonatomic, strong) NSString *albumName;
//@property (nonatomic, strong) NSString *albumURL;
@property (nonatomic, strong) Album *album;
//@property (nonatomic, strong) NSString *artistMbid;
//@property (nonatomic, strong) NSString *artistName;
@property (nonatomic, strong) NSNumber *playcount;
@property (nonatomic, strong) NSNumber *rank;
@property (nonatomic, weak) WeeklyChart *weeklyChart;
@property (nonatomic, weak) User *user;

- (NSInteger)playcountValue;

@end
