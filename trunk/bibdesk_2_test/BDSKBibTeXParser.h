//
//  BDSKBibTeXParser.h
//  bd2xtest
//
//  Created by Christiaan Hofman on 2/6/06.
//  Copyright 2006. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BDSKDocument;


@interface BDSKBibTeXParser : NSObject {
}

+ (NSSet *)itemsFromData:(NSData *)data error:(NSError **)outError document:(BDSKDocument *)document;
+ (NSSet *)itemsFromData:(NSData *)data error:(NSError **)outError frontMatter:(NSMutableString *)frontMatter filePath:(NSString *)filePath document:(BDSKDocument *)document;
+ (NSArray *)personNamesFromBibTeXString:(NSString *)aString;
+ (NSDictionary *)splitPersonName:(NSString *)newName;
+ (NSString *)normalizedNameFromString:(NSString *)aString;

@end


@interface NSString (BDSKExtensions)

+ (NSString *)stringWithBytes:(const char *)byteString encoding:(NSStringEncoding)encoding;
- (NSString *)initWithBytes:(const char *)byteString encoding:(NSStringEncoding)encoding;

@end


@interface NSData (BDSKExtensions)

- (FILE *)openReadOnlyStandardIOFile;

@end
