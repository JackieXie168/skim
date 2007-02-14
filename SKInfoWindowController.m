//
//  SKInfoWindowController.m
//  Skim
//
//  Created by Christiaan Hofman on 17/12/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "SKInfoWindowController.h"
#import "SKDocument.h"
#import <Quartz/Quartz.h>


@implementation SKInfoWindowController

+ (id)sharedInstance {
    static SKInfoWindowController *sharedInstance = nil;
    if (sharedInstance == nil) {
        sharedInstance = [[self alloc] init];
    }
    return sharedInstance;
}

- (id)init {
    if (self = [super init]) {
        info = [[NSMutableDictionary alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(handleWindowDidBecomeKeyNotification:) 
                                                     name: NSWindowDidBecomeMainNotification object: nil];
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(handleWindowDidResignKeyNotification:) 
                                                     name: NSWindowDidResignMainNotification object: nil];
    }
    return self;
}

- (void)dealloc {
    [info release];
    [super dealloc];
}

- (NSString *)windowNibName {
    return @"InfoWindow";
}

static inline 
NSString *fileSizeOfFileAtPath(NSString *path) {
    if (path == nil)
        return @"";
    
    CFURLRef fileURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)path, kCFURLPOSIXPathStyle, false);
    FSRef fileRef;
    FSCatalogInfo catalogInfo;
    unsigned long long size, logicalSize;
    BOOL gotSize = NO;
    NSMutableString *string = [NSMutableString string];
    
    if (fileURL != NULL) {
        Boolean gotRef = CFURLGetFSRef(fileURL, &fileRef);
        CFRelease(fileURL);
        if (gotRef && noErr == FSGetCatalogInfo(&fileRef, kFSCatInfoDataSizes | kFSCatInfoRsrcSizes, &catalogInfo, NULL, NULL, NULL)) {
            size = catalogInfo.dataPhysicalSize + catalogInfo.rsrcPhysicalSize;
            logicalSize = catalogInfo.dataLogicalSize + catalogInfo.rsrcLogicalSize;
            gotSize = YES;
        }
    }
    
    if (gotSize == NO) {
        // the docs say this gives the file size in bytes, but it seems in block units or something
        NSDictionary *fileAttrs = [[NSFileManager defaultManager] fileAttributesAtPath:path traverseLink:NO];
        logicalSize = size = [[fileAttrs objectForKey:NSFileSize] unsignedLongLongValue] / 2000;
    }
    
    unsigned long bigSize = size >> 32;
    if (bigSize == 0) {
        if (size == 0) {
            [string appendString:@"zero bytes"];
        } else if (size < 1024) {
            [string appendFormat:@"%qu bytes", size];
        } else {
            UInt32 adjSize = size >> 10;
            if (adjSize < 1024) {
                [string appendFormat:@"%.1f KB", size / 1024.0f];
            } else {
                adjSize >>= 10; size >>= 10;
                if (adjSize < 1024) {
                    [string appendFormat:@"%.1f MB", size / 1024.0f];
                } else {
                    adjSize >>= 10; size >>= 10;
                    [string appendFormat:@"%.1f GB", size / 1024.0f];
                }
            }
        }
    } else if (bigSize < 256) {
        [string appendFormat:@"%u GB", bigSize, logicalSize];
    } else {
        bigSize >>= 2;
        [string appendFormat:@"%u TB", bigSize, logicalSize];
    }
    
    NSNumberFormatter *formatter = [[[NSNumberFormatter alloc] init] autorelease];
    
    [formatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [string appendFormat:@" (%@ bytes)", [formatter stringFromNumber:[NSNumber numberWithUnsignedLongLong:logicalSize]]];
    
    return string;
}

- (void)fillInfoForDocument:(SKDocument *)doc {
    PDFDocument *pdfDoc = [doc pdfDocument];
    [self setInfo:[pdfDoc documentAttributes]];
    if (doc) {
        [info setValue:[[doc fileName] lastPathComponent] forKey:@"FileName"];
        [info setValue:[NSString stringWithFormat: @"%d.%d", [pdfDoc majorVersion], [pdfDoc minorVersion]] forKey:@"Version"];
        [info setValue:[NSNumber numberWithInt:[pdfDoc pageCount]] forKey:@"PageCount"];
        [info setValue:fileSizeOfFileAtPath([doc fileName]) forKey:@"FileSize"];
        [info setValue:[[info valueForKey:@"KeyWords"] componentsJoinedByString:@" "] forKey:@"KeywordsString"];
    }
}

- (NSDictionary *)info {
    return info;
}

- (void)setInfo:(NSDictionary *)newInfo {
    [info setDictionary:newInfo];
}

- (void)handleWindowDidBecomeKeyNotification:(NSNotification *)notification {
    SKDocument *doc = (SKDocument *)[[[notification object] windowController] document];
    [self fillInfoForDocument:doc];
}

- (void)handleWindowDidResignKeyNotification:(NSNotification *)notification {
    [self fillInfoForDocument:nil];
}

@end
