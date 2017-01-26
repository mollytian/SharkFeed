//
//  FlickrURL.h
//  Shark Feed
//
//  Created by Molly Tian on 8/13/16.
//  Copyright © 2016 Molly Tian. All rights reserved.
//

#import <Foundation/Foundation.h>

#define FlickrAPIKey @"​949e98778755d1982f537d56236bbb42"


// key paths to photos or places at top-level of Flickr results
#define FLICKR_RESULTS_PHOTOS @"photos.photo"
#define FLICKR_RESULTS_PLACES @"places.place"

#define FLICKR_PHOTO_TITLE @"title"

typedef enum {
    FlickrPhotoFormatSquare = 1,     // small square 75x75
    FlickrPhotoFormatSmall = 2,      // small, 240 on longest side
    FlickrPhotoFormatLarge = 3,      // large, 1024 on longest side*
    FlickrPhotoFormatXLarge = 4,     // large, 1600 on longest side*
    FlickrPhotoFormatXXLarge = 5,    // large, 2048 on longest side*
    FlickrPhotoFormatOriginal = 64   // high resolution
} FlickrPhotoFormat;

@interface FlickrURL : NSObject

+ (NSURL *)URLforPhoto:(NSDictionary *)photo format:(FlickrPhotoFormat)format;
+ (NSURL *)URLforPhotoInformation:(id)flickrPhotoId;
+ (NSURL *)URLforSearchString:(NSString *)searchString ofPage: (NSNumber *)page;

@end
