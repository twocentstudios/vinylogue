//
//  LastFMObject.m
//  vinylogue
//
//  Created by Christopher Trott on 3/20/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import "LastFMObject.h"

@implementation LastFMObject

// This should be implemented by subclasses
+ (id)objectFromExternalDictionary:(NSDictionary *)dict{
  return [[[self class] alloc] init];
}

#pragma mark - utility

// image array: array of dictionaries containing #text and size attributes
// imageThumbURL: will be set with proper URL for thumb
// imageURL: will be set with proper URL for image
void TCSSetImageURLsForThumbAndImage(NSArray *imageArray, NSString **imageThumbURL, NSString **imageURL){
  NSMutableDictionary *newAlbumDict = [NSMutableDictionary dictionaryWithCapacity:[imageArray count]];
  for (NSDictionary *imgDict in imageArray){
    [newAlbumDict setObject:[imgDict objectForKey:@"#text"] forKey:[imgDict objectForKey:@"size"]];
  }
  NSString *largestImageURL = nil;
  NSString *currentImageURL = nil;
  largestImageURL = [newAlbumDict objectForKey:@"small"];
  currentImageURL = [newAlbumDict objectForKey:@"medium"];
  if (currentImageURL != nil)
    largestImageURL = currentImageURL;
  currentImageURL = [newAlbumDict objectForKey:@"large"];
  if (currentImageURL != nil)
    largestImageURL = currentImageURL;
  *imageThumbURL = largestImageURL; // set imageThumbURL with large image (or medium or small)
  currentImageURL = [newAlbumDict objectForKey:@"extralarge"];
  if (currentImageURL != nil)
    largestImageURL = currentImageURL;
  currentImageURL = [newAlbumDict objectForKey:@"mega"];
  if (currentImageURL != nil)
    largestImageURL = currentImageURL;
  *imageURL = largestImageURL; // set imageURL with mega image (or extralarge or large etc.)
}

// Strips HTML tags and converts &quot; to "
NSString *TCSStringByStrippingHTMLTagsFromString(NSString *htmlString){
  if (htmlString == nil)
    return nil;
  
  NSError *error = nil;
  NSString *output = nil;
  
  NSRegularExpression *regexTagStart = [NSRegularExpression
                                        regularExpressionWithPattern:@"<\\s*\\w.*?>"
                                        options:0
                                        error:&error];
  NSRegularExpression *regexTagEnd = [NSRegularExpression
                                      regularExpressionWithPattern:@"<\\/.*?>"
                                      options:0
                                      error:&error];
  output = [regexTagStart stringByReplacingMatchesInString:htmlString options:0 range:NSMakeRange(0, [htmlString length]) withTemplate:@""];
  output = [regexTagEnd stringByReplacingMatchesInString:output options:0 range:NSMakeRange(0, [output length]) withTemplate:@""];
  output = [output stringByReplacingOccurrencesOfString:@"&quot;" withString:@"\""];
  
  return output;
}


// Date is assumed to be in the format: "    20 Sep 2011, 00:00"
NSDate *TCSDateByParsingLastFMAlbumReleaseDateString(NSString *dateString){
  if (dateString == nil)
    return nil;
  
  static dispatch_once_t onceMark;
  static NSDateFormatter *formatter = nil;
  dispatch_once(&onceMark, ^{
    formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd MM yyyy"];
  });
  
  // Strip leading whitespace
  NSString *outputStr = [dateString copy];
  outputStr = [outputStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
  if ([outputStr isEqualToString:@""])
    return nil;
  
  // Strip everything past the comma
  NSRange commaRange = [outputStr rangeOfString:@","];
  if (commaRange.location == NSNotFound)
    return nil;
  
  outputStr = [outputStr substringToIndex:commaRange.location];
  
  // Do the conversion
  NSDate *outputDate = [formatter dateFromString:outputStr];
  
  return outputDate;
}

@end
