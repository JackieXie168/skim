//
//  SKInfoWindowController.m
//  Skim
//
//  Created by Christiaan Hofman on 12/17/06.
/*
 This software is Copyright (c) 2006-2009
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
#import "SKPDFDocument.h"
#import <Quartz/Quartz.h>
#import "SKRuntime.h"

static NSString *SKInfoWindowFrameAutosaveName = @"SKInfoWindow";

static NSString *SKInfoVersionKey = @"Version";
static NSString *SKInfoPageCountKey = @"PageCount";
static NSString *SKInfoPageSizeKey = @"PageSize";
static NSString *SKInfoPageWidthKey = @"PageWidth";
static NSString *SKInfoPageHeightKey = @"PageHeight";
static NSString *SKInfoKeywordsStringKey = @"KeywordsString";
static NSString *SKInfoEncryptedKey = @"Encrypted";
static NSString *SKInfoAllowsPrintingKey = @"AllowsPrinting";
static NSString *SKInfoAllowsCopyingKey = @"AllowsCopying";
static NSString *SKInfoFileNameKey = @"FileName";
static NSString *SKInfoFileSizeKey = @"FileSize";
static NSString *SKInfoPhysicalSizeKey = @"PhysicalSize";
static NSString *SKInfoLogicalSizeKey = @"LogicalSize";

@implementation SKInfoWindowController

static SKInfoWindowController *sharedInstance = nil;

+ (void)initialize {
    OBINITIALIZE;
    
    SKBoolStringTransformer *transformer = [[SKBoolStringTransformer alloc] init];
    [NSValueTransformer setValueTransformer:transformer forName:@"SKBoolStringTransformer"];
    [transformer release];
}

+ (id)sharedInstance {
    if (sharedInstance == nil)
        [[self alloc] init];
    return sharedInstance;
}

+ (id)allocWithZone:(NSZone *)zone {
    return sharedInstance ?: [super allocWithZone:zone];
}

- (id)init {
    if (sharedInstance == nil && (sharedInstance = self = [super initWithWindowNibName:@"InfoWindow"])) {
        info = nil;
    }
    return sharedInstance;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [info release];
    [super dealloc];
}

- (id)retain { return self; }

- (id)autorelease { return self; }

- (void)release {}

- (unsigned)retainCount { return UINT_MAX; }

- (void)windowDidLoad {
    [self setWindowFrameAutosaveName:SKInfoWindowFrameAutosaveName];
    
    [self setInfo:[self infoForDocument:[[[NSApp mainWindow] windowController] document]]];
    
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(handleWindowDidBecomeMainNotification:) 
                                                 name: NSWindowDidBecomeMainNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(handleWindowDidResignMainNotification:) 
                                                 name: NSWindowDidResignMainNotification object: nil];
}

static NSString *SKFileSizeStringForFileURL(NSURL *fileURL, unsigned long long *physicalSizePtr, unsigned long long *logicalSizePtr) {
    if (fileURL == nil)
        return @"";
    
    FSRef fileRef;
    FSCatalogInfo catalogInfo;
    unsigned long long size, logicalSize = 0;
    BOOL gotSize = NO, isDir = NO;
    NSMutableString *string = [NSMutableString string];
    
    Boolean gotRef = CFURLGetFSRef((CFURLRef)fileURL, &fileRef);
    if (gotRef && noErr == FSGetCatalogInfo(&fileRef, kFSCatInfoDataSizes | kFSCatInfoRsrcSizes | kFSCatInfoNodeFlags, &catalogInfo, NULL, NULL, NULL)) {
        size = catalogInfo.dataPhysicalSize + catalogInfo.rsrcPhysicalSize;
        logicalSize = catalogInfo.dataLogicalSize + catalogInfo.rsrcLogicalSize;
        isDir = (catalogInfo.nodeFlags & kFSNodeIsDirectoryMask) != 0;
        gotSize = YES;
    }
    
    if (gotSize == NO) {
        // this seems to give the logical size
        NSDictionary *fileAttrs = [[NSFileManager defaultManager] fileAttributesAtPath:[fileURL path] traverseLink:NO];
        logicalSize = size = [[fileAttrs objectForKey:NSFileSize] unsignedLongLongValue];
        isDir = [[fileAttrs fileType] isEqualToString:NSFileTypeDirectory];
    }
    
    if (isDir) {
        NSString *path = [fileURL path];
        NSEnumerator *fileEnum = [[[NSFileManager defaultManager] subpathsAtPath:path] objectEnumerator];
        NSString *file;
        unsigned long long componentSize;
        unsigned long long logicalComponentSize;
        while (file = [fileEnum nextObject]) {
            SKFileSizeStringForFileURL([NSURL fileURLWithPath:[path stringByAppendingPathComponent:file]], &componentSize, &logicalComponentSize);
            size += componentSize;
            logicalSize += logicalComponentSize;
        }
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

static inline 
NSString *SKSizeString(NSSize size, NSSize altSize) {
    BOOL useMetric = [[[NSLocale currentLocale] objectForKey:NSLocaleUsesMetricSystem] boolValue];
    NSString *units = useMetric ? @"cm" : @"in";
    float factor = useMetric ? 0.035277778 : 0.013888889;
    return [NSString stringWithFormat:@"%.1f x %.1f %@  (%.1f x %.1f %@)", size.width * factor, size.height * factor, units, altSize.width * factor, altSize.height * factor, units];
}

- (NSDictionary *)infoForDocument:(NSDocument *)doc {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    PDFDocument *pdfDoc;
    unsigned long long logicalSize = 0, physicalSize = 0;
    
    if ([doc respondsToSelector:@selector(pdfDocument)] && (pdfDoc = [(SKPDFDocument *)doc pdfDocument])) {
        [dictionary addEntriesFromDictionary:[pdfDoc documentAttributes]];
        [dictionary setValue:[NSString stringWithFormat: @"%d.%d", [pdfDoc majorVersion], [pdfDoc minorVersion]] forKey:SKInfoVersionKey];
        [dictionary setValue:[NSNumber numberWithInt:[pdfDoc pageCount]] forKey:SKInfoPageCountKey];
        if ([pdfDoc pageCount]) {
            NSSize cropSize = [[pdfDoc pageAtIndex:0] boundsForBox:kPDFDisplayBoxCropBox].size;
            NSSize mediaSize = [[pdfDoc pageAtIndex:0] boundsForBox:kPDFDisplayBoxMediaBox].size;
            [dictionary setValue:SKSizeString(cropSize, mediaSize) forKey:SKInfoPageSizeKey];
            [dictionary setValue:[NSNumber numberWithFloat:cropSize.width] forKey:SKInfoPageWidthKey];
            [dictionary setValue:[NSNumber numberWithFloat:cropSize.height] forKey:SKInfoPageHeightKey];
        }
        [dictionary setValue:[[dictionary valueForKey:@"Keywords"] componentsJoinedByString:@"\n"] forKey:SKInfoKeywordsStringKey];
        [dictionary setValue:[NSNumber numberWithBool:[pdfDoc isEncrypted]] forKey:SKInfoEncryptedKey];
        [dictionary setValue:[NSNumber numberWithBool:[pdfDoc allowsPrinting]] forKey:SKInfoAllowsPrintingKey];
        [dictionary setValue:[NSNumber numberWithBool:[pdfDoc allowsCopying]] forKey:SKInfoAllowsCopyingKey];
    }
    [dictionary setValue:[[doc fileName] lastPathComponent] forKey:SKInfoFileNameKey];
    [dictionary setValue:SKFileSizeStringForFileURL([doc fileURL], &physicalSize, &logicalSize) forKey:SKInfoFileSizeKey];
    [dictionary setValue:[NSNumber numberWithUnsignedLongLong:physicalSize] forKey:SKInfoPhysicalSizeKey];
    [dictionary setValue:[NSNumber numberWithUnsignedLongLong:logicalSize] forKey:SKInfoLogicalSizeKey];
    
    return dictionary;
}

- (NSDictionary *)info {
    return info;
}

- (void)setInfo:(NSDictionary *)newInfo {
    if (info != newInfo) {
        [info release];
        info = [newInfo retain];
    }
}

- (void)handleWindowDidBecomeMainNotification:(NSNotification *)notification {
    NSDocument *doc = [[[notification object] windowController] document];
    [self setInfo:[self infoForDocument:doc]];
}

- (void)handleWindowDidResignMainNotification:(NSNotification *)notification {
    [self setInfo:nil];
}

@end


@implementation SKBoolStringTransformer

+ (Class)transformedValueClass {
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation {
    return NO;
}

- (id)transformedValue:(id)value {
	return value == nil ? nil : [value boolValue] ? NSLocalizedString(@"Yes", @"") : NSLocalizedString(@"No", @"");
}

@end
