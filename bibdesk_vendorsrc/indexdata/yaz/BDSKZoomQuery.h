//
//  BDSKZoomQuery.h
//  yaz
//
//  Created by Adam Maxwell on 12/26/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <yaz/zoom.h>

@interface BDSKZoomQuery : NSObject <NSCopying>
{
    ZOOM_query  _query;
    NSString   *_config;
    NSString   *_queryString;
}

+ (id)queryWithCCLString:(NSString *)queryString config:(NSString *)confString;
- (id)initWithCCLString:(NSString *)queryString config:(NSString *)confString;
- (ZOOM_query)zoomQuery;
@end

@interface BDSKZoomCCLQueryFormatter : NSFormatter
@end
