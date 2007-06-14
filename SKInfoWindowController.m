//
//  SKInfoWindowController.m
//  Skim
//
//  Created by Christiaan Hofman on 12/17/06.
/*
 This software is Copyright (c) 2006,2007
 Christiaan Hofman. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Christiaan Hofman nor the names of any
    contributors may be used to endorse or promote products derived
    from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

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
NSString *SKFileSizeStringForFileURL(NSURL *fileURL, unsigned long long *physicalSizePtr, unsigned long long *logicalSizePtr) {
    if (fileURL == nil)
        return @"";
    
    FSRef fileRef;
    FSCatalogInfo catalogInfo;
    unsigned long long size, logicalSize = 0;
    BOOL gotSize = NO;
    NSMutableString *string = [NSMutableString string];
    
    Boolean gotRef = CFURLGetFSRef((CFURLRef)fileURL, &fileRef);
    if (gotRef && noErr == FSGetCatalogInfo(&fileRef, kFSCatInfoDataSizes | kFSCatInfoRsrcSizes, &catalogInfo, NULL, NULL, NULL)) {
        size = catalogInfo.dataPhysicalSize + catalogInfo.rsrcPhysicalSize;
        logicalSize = catalogInfo.dataLogicalSize + catalogInfo.rsrcLogicalSize;
        gotSize = YES;
    }
    
    if (gotSize == NO) {
        // this seems to give the logical size
        NSDictionary *fileAttrs = [[NSFileManager defaultManager] fileAttributesAtPath:[fileURL path] traverseLink:NO];
        logicalSize = size = [[fileAttrs objectForKey:NSFileSize] unsignedLongLongValue];
    }
    
    if (physicalSizePtr)
        *physicalSizePtr = size;
    if (logicalSizePtr)
        *logicalSizePtr = logicalSize;
    
    if (size >> 40 == 0) {
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
    } else {
        UInt32 adjSize = size >> 40; size >>= 30;
        if (adjSize < 1024) {
            [string appendFormat:@"%.1f TB", size / 1024.0f];
        } else {
            adjSize >>= 10; size >>= 10;
            if (adjSize < 1024) {
                [string appendFormat:@"%.1f PB", size / 1024.0f];
            } else {
                adjSize >>= 10; size >>= 10;
                [string appendFormat:@"%.1f EB", size / 1024.0f];
            }
        }
    }
    
    NSNumberFormatter *formatter = [[[NSNumberFormatter alloc] init] autorelease];
    
    [formatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [string appendFormat:@" (%@ bytes)", [formatter stringFromNumber:[NSNumber numberWithUnsignedLongLong:logicalSize]]];
    
    return string;
}

- (NSDictionary *)infoForDocument:(SKDocument *)doc {
    PDFDocument *pdfDoc = [doc pdfDocument];
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setDictionary:[pdfDoc documentAttributes]];
    if (doc) {
        unsigned long long logicalSize, physicalSize;
        [dictionary setValue:[[doc fileName] lastPathComponent] forKey:@"FileName"];
        [dictionary setValue:[NSString stringWithFormat: @"%d.%d", [pdfDoc majorVersion], [pdfDoc minorVersion]] forKey:@"Version"];
        [dictionary setValue:[NSNumber numberWithInt:[pdfDoc pageCount]] forKey:@"PageCount"];
        [dictionary setValue:SKFileSizeStringForFileURL([doc fileURL], &physicalSize, &logicalSize) forKey:@"FileSize"];
        [dictionary setValue:[NSNumber numberWithUnsignedLongLong:physicalSize] forKey:@"PhysicalSize"];
        [dictionary setValue:[NSNumber numberWithUnsignedLongLong:logicalSize] forKey:@"LogicalSize"];
        [dictionary setValue:[[info valueForKey:@"KeyWords"] componentsJoinedByString:@" "] forKey:@"KeywordsString"];
    }
    return dictionary;
}

- (void)fillInfoForDocument:(SKDocument *)doc {
    [self setInfo:[self infoForDocument:doc]];
}

- (NSDictionary *)info {
    return info;
}

- (void)setInfo:(NSDictionary *)newInfo {
    [info setDictionary:newInfo];
}

- (void)handleWindowDidBecomeKeyNotification:(NSNotification *)notification {
    SKDocument *doc = (SKDocument *)[[[notification object] windowController] document];
    [self setInfo:[self infoForDocument:doc]];
}

- (void)handleWindowDidResignKeyNotification:(NSNotification *)notification {
    [self setInfo:nil];
}

@end
