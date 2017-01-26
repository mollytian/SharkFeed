//
//  FlickrURL.m
//  Shark Feed
//
//  Created by Molly Tian on 8/13/16.
//  Copyright © 2016 Molly Tian. All rights reserved.
//

#import "FlickrURL.h"

@implementation FlickrURL


+ (NSURL *)URLForQuery:(NSString *)query
{
    query = [NSString stringWithFormat:@"%@&format=json&nojsoncallback=1&api_key=949e98778755d1982f537d56236bbb42", query];
    query = [query stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    return [NSURL URLWithString:query];
}

+ (NSURL *)URLforPhoto:(NSDictionary *)photo format:(FlickrPhotoFormat)format;
{
    return [NSURL URLWithString:[self urlStringForPhoto:photo format:format]];
}

+ (NSString *)urlStringForPhoto:(NSDictionary *)photo format:(FlickrPhotoFormat)format
{
    id farm = [photo objectForKey:@"farm"];
    id server = [photo objectForKey:@"server"];
    id photo_id = [photo objectForKey:@"id"];
    id secret = [photo objectForKey:@"secret"];
    if (format == FlickrPhotoFormatOriginal) secret = [photo objectForKey:@"originalsecret"];
    
    NSString *fileType = @"jpg";
    if (format == FlickrPhotoFormatOriginal) fileType = [photo objectForKey:@"originalformat"];
    
    if (!farm || !server || !photo_id || !secret) return nil;
    
    NSString *formatString = @"s";
    switch (format) {
        case FlickrPhotoFormatSquare:    formatString = @"s"; break;
        case FlickrPhotoFormatSmall:    formatString = @"m"; break;
        case FlickrPhotoFormatLarge:     formatString = @"b"; break;
        case FlickrPhotoFormatXLarge:   formatString = @"h"; break;
        case FlickrPhotoFormatXXLarge:   formatString = @"k"; break;
        case FlickrPhotoFormatOriginal:  formatString = @"o"; break;
    }
    
    return [NSString stringWithFormat:@"https://farm%@.static.flickr.com/%@/%@_%@_%@.%@", farm, server, photo_id, secret, formatString, fileType];
}

+ (NSURL *)URLforPhotoInformation:(id)flickrPlaceId
{
    return [self URLForQuery:[NSString stringWithFormat:@"https://api.flickr.com/services/rest/?method=flickr.photos.getInfo&photo_id=%@",flickrPlaceId]];
}

+ (NSURL *)URLforSearchString:(NSString *)searchString ofPage:(NSNumber *)page{
    
    return [self URLForQuery:[NSString stringWithFormat:@"https://api.flickr.com/services/rest/?method=flickr.photos.search&text=%@&page=%@&extras=url_t,url_c,url_l,url_o", searchString, [NSString stringWithFormat:@"%@", page]]];
}


@end
