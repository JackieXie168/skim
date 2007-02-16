//
//  PDFPage_SKExtensions.h
//  Skim
//
//  Created by Christiaan Hofman on 2/16/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>


@interface PDFPage (SKExtensions)

- (NSImage *)image;
- (NSImage *)thumbnailWithSize:(float)size shadowBlurRadius:(float)shadowBlurRadius shadowOffset:(NSSize)shadowOffset;

@end
