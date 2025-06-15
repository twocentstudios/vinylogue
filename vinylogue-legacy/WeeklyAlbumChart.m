#import "WeeklyAlbumChart.h"

#import "Album.h"
#import "Artist.h"

@implementation WeeklyAlbumChart

+ (id)objectFromExternalDictionary:(NSDictionary *)dict{
  WeeklyAlbumChart *albumChart = [[WeeklyAlbumChart alloc] init];
  albumChart.album = [[Album alloc] init];
  albumChart.album.weeklyAlbumChart = albumChart;
  albumChart.album.artist = [[Artist alloc] init];
  albumChart.album.artist.name = [[dict objectForKey:@"artist"] objectForKey:@"#text"];
  albumChart.album.artist.mbid = [[dict objectForKey:@"artist"] objectForKey:@"mbid"];
  albumChart.album.name = [dict objectForKey:@"name"];
  albumChart.album.mbid = [dict objectForKey:@"mbid"];
  albumChart.album.url = [dict objectForKey:@"url"];
  albumChart.playcount = @([[dict objectForKey:@"playcount"] integerValue]);
  albumChart.rank = @([[[dict objectForKey:@"@attr"] objectForKey:@"rank"] integerValue]);
  return albumChart;
}

- (NSInteger)playcountValue{
  return [self.playcount integerValue];
}

@end
