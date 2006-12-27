//
//  BDSKZoomRecord.h
//  yaz
//
//  Created by Adam Maxwell on 12/26/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <yaz/zoom.h>

@interface BDSKZoomRecord : NSObject
{
    ZOOM_record          _record;
    NSMutableDictionary *_representations;
}

+ (NSArray *)validKeys;

// encoding of 0 (not used) means that only UTF-8 will be tried
+ (void)setFallbackEncoding:(NSStringEncoding)enc;

+ (id)recordWithZoomRecord:(ZOOM_record)record;
- (id)initWithZoomRecord:(ZOOM_record)record;

- (NSString *)renderedString;
- (NSString *)rawString;

@end
