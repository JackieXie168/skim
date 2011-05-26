//
//  SKInfoWindowController.m
//  Skim
//
//  Created by Christiaan Hofman on 12/17/06.
/*
 This software is Copyright (c) 2006-2011
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
#import "SKMainDocument.h"
#import "NSDocument_SKExtensions.h"
#import "PDFPage_SKExtensions.h"
#import <Quartz/Quartz.h>

#define SKInfoWindowFrameAutosaveName @"SKInfoWindow"

#define SKBoolStringTransformerName @"SKBoolStringTransformer"

#define SKInfoVersionKey @"Version"
#define SKInfoPageCountKey @"PageCount"
#define SKInfoPageSizeKey @"PageSize"
#define SKInfoPageWidthKey @"PageWidth"
#define SKInfoPageHeightKey @"PageHeight"
#define SKInfoKeywordsStringKey @"KeywordsString"
#define SKInfoEncryptedKey @"Encrypted"
#define SKInfoAllowsPrintingKey @"AllowsPrinting"
#define SKInfoAllowsCopyingKey @"AllowsCopying"
#define SKInfoFileNameKey @"FileName"
#define SKInfoFileSizeKey @"FileSize"
#define SKInfoPhysicalSizeKey @"PhysicalSize"
#define SKInfoLogicalSizeKey @"LogicalSize"
#define SKInfoTagsKey @"Tags"
#define SKInfoRatingKey @"Rating"


@interface SKInfoWindowController (SKPrivate)
- (void)handleViewFrameDidChangeNotification:(NSNotification *)notification;
- (void)handleWindowDidBecomeMainNotification:(NSNotification *)notification;
- (void)handleWindowDidResignMainNotification:(NSNotification *)notification;
- (void)handlePDFDocumentInfoDidChangeNotification:(NSNotification *)notification;
- (void)handleDocumentFileURLDidChangeNotification:(NSNotification *)notification;
@end

@implementation SKInfoWindowController

@synthesize summaryTableView, attributesTableView, tabView, info;

+ (void)initialize {
    SKINITIALIZE;
    
    SKBoolStringTransformer *transformer = [[SKBoolStringTransformer alloc] init];
    [NSValueTransformer setValueTransformer:transformer forName:SKBoolStringTransformerName];
    [transformer release];
}

static SKInfoWindowController *sharedInstance = nil;

+ (id)sharedInstance {
    if (sharedInstance == nil)
        sharedInstance = [[self alloc] init];
    return sharedInstance;
}

- (id)init {
    if (sharedInstance) NSLog(@"Attempt to allocate second instance of %@", self);
    self = [super initWithWindowNibName:@"InfoWindow"];
    if (self){
        info = nil;
        summaryKeys = [[NSArray alloc] initWithObjects:
                            SKInfoFileNameKey,
                            SKInfoFileSizeKey,
                            SKInfoPageSizeKey,
                            SKInfoPageCountKey,
                            SKInfoVersionKey,
                            @"",
                            SKInfoEncryptedKey,
                            SKInfoAllowsPrintingKey,
                            SKInfoAllowsCopyingKey, nil];
        attributesKeys = [[NSArray alloc] initWithObjects:
                            PDFDocumentTitleAttribute,
                            PDFDocumentAuthorAttribute,
                            PDFDocumentSubjectAttribute,
                            PDFDocumentCreatorAttribute,
                            PDFDocumentProducerAttribute,
                            PDFDocumentCreationDateAttribute,
                            PDFDocumentModificationDateAttribute,
                            SKInfoKeywordsStringKey, nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    SKDESTROY(info);
    SKDESTROY(summaryKeys);
    SKDESTROY(attributesKeys);
    SKDESTROY(summaryTableView);
    SKDESTROY(attributesTableView);
    SKDESTROY(tabView);
    [super dealloc];
}

- (void)updateForDocument:(NSDocument *)doc {
    [self setInfo:[self infoForDocument:doc]];
    [summaryTableView reloadData];
    [attributesTableView reloadData];
}

- (void)windowDidLoad {
    [self updateForDocument:[self infoForDocument:[[[NSApp mainWindow] windowController] document]]];
    
    NSArray *tables = [NSArray arrayWithObjects:summaryTableView, attributesTableView, nil];
    NSTableView *tv;
    CGFloat width = 0.0;
    for (tv in tables) {
        NSUInteger row, rowMax = [tv numberOfRows];
        for (row = 0; row < rowMax; row++)
            width = fmax(width, [[tv preparedCellAtColumn:0 row:row] cellSize].width);
    }
    for (tv in tables) {
        [[[tv tableColumns] objectAtIndex:0] setWidth:width];
        [tv sizeToFit];
    }
    
    [self setWindowFrameAutosaveName:SKInfoWindowFrameAutosaveName];
    
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(handleViewFrameDidChangeNotification:) 
                                                 name: NSViewFrameDidChangeNotification object: [attributesTableView enclosingScrollView]];
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(handleWindowDidBecomeMainNotification:) 
                                                 name: NSWindowDidBecomeMainNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(handleWindowDidResignMainNotification:) 
                                                 name: NSWindowDidResignMainNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(handlePDFDocumentInfoDidChangeNotification:) 
                                                 name: PDFDocumentDidUnlockNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(handlePDFDocumentInfoDidChangeNotification:) 
                                                 name: SKPDFPageBoundsDidChangeNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(handleDocumentFileURLDidChangeNotification:) 
                                                 name: SKDocumentFileURLDidChangeNotification object: nil];
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
        NSDictionary *fileAttrs = [[NSFileManager defaultManager] attributesOfItemAtPath:[fileURL path] error:NULL];
        logicalSize = size = [[fileAttrs objectForKey:NSFileSize] unsignedLongLongValue];
        isDir = [[fileAttrs fileType] isEqualToString:NSFileTypeDirectory];
    }
    
    if (isDir) {
        NSString *path = [fileURL path];
        unsigned long long componentSize;
        unsigned long long logicalComponentSize;
        for (NSString *file in [[NSFileManager defaultManager] subpathsAtPath:path]) {
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
            [string appendFormat:@"0 %@", NSLocalizedString(@"bytes", @"size unit")];
        } else if (size < 1024) {
            [string appendFormat:@"%qu %@", size, NSLocalizedString(@"bytes", @"size unit")];
        } else {
            UInt32 adjSize = size >> 10;
            if (adjSize < 1024) {
                [string appendFormat:@"%.1f KB", size / 1024.0f, NSLocalizedString(@"KB", @"size unit")];
            } else {
                adjSize >>= 10;
                size >>= 10;
                if (adjSize < 1024) {
                    [string appendFormat:@"%.1f MB", size / 1024.0f, NSLocalizedString(@"MB", @"size unit")];
                } else {
                    //adjSize >>= 10;
                    size >>= 10;
                    [string appendFormat:@"%.1f GB", size / 1024.0f, NSLocalizedString(@"GB", @"size unit")];
                }
            }
        }
    } else {
        UInt32 adjSize = size >> 40; size >>= 30;
        if (adjSize < 1024) {
            [string appendFormat:@"%.1f TB", size / 1024.0f, NSLocalizedString(@"TB", @"size unit")];
        } else {
            adjSize >>= 10;
            size >>= 10;
            if (adjSize < 1024) {
                [string appendFormat:@"%.1f PB", size / 1024.0f, NSLocalizedString(@"PB", @"size unit")];
            } else {
                //adjSize >>= 10;
                size >>= 10;
                [string appendFormat:@"%.1f EB", size / 1024.0f, NSLocalizedString(@"EB", @"size unit")];
            }
        }
    }
    
    NSNumberFormatter *formatter = [[[NSNumberFormatter alloc] init] autorelease];
    
    [formatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [string appendFormat:@" (%@ %@)", [formatter stringFromNumber:[NSNumber numberWithUnsignedLongLong:logicalSize]], NSLocalizedString(@"bytes", @"size unit")];
    
    return string;
}

static inline 
NSString *SKSizeString(NSSize size, NSSize altSize) {
    BOOL useMetric = [[[NSLocale currentLocale] objectForKey:NSLocaleUsesMetricSystem] boolValue];
    NSString *units = useMetric ? NSLocalizedString(@"cm", @"size unit") : NSLocalizedString(@"in", @"size unit");
    CGFloat factor = useMetric ? 0.035277778 : 0.013888889;
    if (NSEqualSizes(size, altSize))
        return [NSString stringWithFormat:@"%.1f x %.1f %@", size.width * factor, size.height * factor, units];
    else
        return [NSString stringWithFormat:@"%.1f x %.1f %@  (%.1f x %.1f %@)", size.width * factor, size.height * factor, units, altSize.width * factor, altSize.height * factor, units];
}

- (NSDictionary *)infoForDocument:(NSDocument *)doc {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    PDFDocument *pdfDoc;
    unsigned long long logicalSize = 0, physicalSize = 0;
    
    if ([doc isPDFDocument] && (pdfDoc = [doc pdfDocument])) {
        [dictionary addEntriesFromDictionary:[pdfDoc documentAttributes]];
        [dictionary setValue:[NSString stringWithFormat: @"%ld.%ld", (long)[pdfDoc majorVersion], (long)[pdfDoc minorVersion]] forKey:SKInfoVersionKey];
        [dictionary setValue:[NSNumber numberWithInteger:[pdfDoc pageCount]] forKey:SKInfoPageCountKey];
        if ([pdfDoc pageCount]) {
            NSSize cropSize = [[pdfDoc pageAtIndex:0] boundsForBox:kPDFDisplayBoxCropBox].size;
            NSSize mediaSize = [[pdfDoc pageAtIndex:0] boundsForBox:kPDFDisplayBoxMediaBox].size;
            [dictionary setValue:SKSizeString(cropSize, mediaSize) forKey:SKInfoPageSizeKey];
            [dictionary setValue:[NSNumber numberWithDouble:cropSize.width] forKey:SKInfoPageWidthKey];
            [dictionary setValue:[NSNumber numberWithDouble:cropSize.height] forKey:SKInfoPageHeightKey];
        }
        [dictionary setValue:[[dictionary valueForKey:PDFDocumentKeywordsAttribute] componentsJoinedByString:@"\n"] forKey:SKInfoKeywordsStringKey];
        [dictionary setValue:[NSNumber numberWithBool:[pdfDoc isEncrypted]] forKey:SKInfoEncryptedKey];
        [dictionary setValue:[NSNumber numberWithBool:[pdfDoc allowsPrinting]] forKey:SKInfoAllowsPrintingKey];
        [dictionary setValue:[NSNumber numberWithBool:[pdfDoc allowsCopying]] forKey:SKInfoAllowsCopyingKey];
    }
    [dictionary setValue:[[[doc fileURL] path] lastPathComponent] forKey:SKInfoFileNameKey];
    [dictionary setValue:SKFileSizeStringForFileURL([doc fileURL], &physicalSize, &logicalSize) forKey:SKInfoFileSizeKey];
    [dictionary setValue:[NSNumber numberWithUnsignedLongLong:physicalSize] forKey:SKInfoPhysicalSizeKey];
    [dictionary setValue:[NSNumber numberWithUnsignedLongLong:logicalSize] forKey:SKInfoLogicalSizeKey];
    if ([doc respondsToSelector:@selector(tags)])
        [dictionary setValue:[(SKMainDocument *)doc tags] ?: [NSArray array] forKey:SKInfoTagsKey];
    if ([doc respondsToSelector:@selector(rating)])
        [dictionary setValue:[NSNumber numberWithDouble:[(SKMainDocument *)doc rating]] forKey:SKInfoRatingKey];
    
    return dictionary;
}

- (void)handleViewFrameDidChangeNotification:(NSNotification *)notification {
    [attributesTableView noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:[attributesKeys count] - 1]];
}

- (void)handleWindowDidBecomeMainNotification:(NSNotification *)notification {
    [self updateForDocument:[[[notification object] windowController] document]];
}

- (void)handleWindowDidResignMainNotification:(NSNotification *)notification {
    [self updateForDocument:nil];
}

- (void)handlePDFDocumentInfoDidChangeNotification:(NSNotification *)notification {
    NSDocument *doc = [[[NSApp mainWindow] windowController] document];
    if ([[doc pdfDocument] isEqual:[notification object]])
        [self updateForDocument:doc];
}

- (void)handleDocumentFileURLDidChangeNotification:(NSNotification *)notification {
    NSDocument *doc = [[[NSApp mainWindow] windowController] document];
    if ([doc isEqual:[notification object]])
        [self updateForDocument:doc];
}

- (NSString *)labelForKey:(NSString *)key {
    if ([key isEqualToString:SKInfoFileNameKey])
        return NSLocalizedString(@"File name:", @"Info label");
    if ([key isEqualToString:SKInfoFileSizeKey])
        return NSLocalizedString(@"File size:", @"Info label");
    if ([key isEqualToString:SKInfoPageSizeKey])
        return NSLocalizedString(@"Page size:", @"Info label");
    if ([key isEqualToString:SKInfoPageCountKey])
        return NSLocalizedString(@"Page count:", @"Info label");
    if ([key isEqualToString:SKInfoVersionKey])
        return NSLocalizedString(@"PDF Version:", @"Info label");
    if ([key isEqualToString:SKInfoEncryptedKey])
        return NSLocalizedString(@"Encrypted:", @"Info label");
    if ([key isEqualToString:SKInfoAllowsPrintingKey])
        return NSLocalizedString(@"Allows printing:", @"Info label");
    if ([key isEqualToString:SKInfoAllowsCopyingKey])
        return NSLocalizedString(@"Allows copying:", @"Info label");
    if ([key isEqualToString:PDFDocumentTitleAttribute])
        return NSLocalizedString(@"Title:", @"Info label");
    if ([key isEqualToString:PDFDocumentAuthorAttribute])
        return NSLocalizedString(@"Author:", @"Info label");
    if ([key isEqualToString:PDFDocumentSubjectAttribute])
        return NSLocalizedString(@"Subject:", @"Info label");
    if ([key isEqualToString:PDFDocumentCreatorAttribute])
        return NSLocalizedString(@"Content Creator:", @"Info label");
    if ([key isEqualToString:PDFDocumentProducerAttribute])
        return NSLocalizedString(@"PDF Producer:", @"Info label");
    if ([key isEqualToString:PDFDocumentCreationDateAttribute])
        return NSLocalizedString(@"Creation date:", @"Info label");
    if ([key isEqualToString:PDFDocumentModificationDateAttribute])
        return NSLocalizedString(@"Modification date:", @"Info label");
    if ([key isEqualToString:SKInfoKeywordsStringKey])
        return NSLocalizedString(@"Keywords:", @"Info label");
    return [key stringByAppendingString:@":"];
}


- (NSInteger)numberOfRowsInTableView:(NSTableView *)tv {
    NSArray *keys = nil;
    if ([tv isEqual:summaryTableView])
        keys = summaryKeys;
    else if ([tv isEqual:attributesTableView])
        keys = attributesKeys;
    return [keys count];
}

- (id)tableView:(NSTableView *)tv objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    static NSDateFormatter *shortDateFormatter = nil;
    if(shortDateFormatter == nil) {
        shortDateFormatter = [[NSDateFormatter alloc] init];
        [shortDateFormatter setDateStyle:NSDateFormatterShortStyle];
        [shortDateFormatter setTimeStyle:NSDateFormatterNoStyle];
    }
    NSArray *keys = nil;
    if ([tv isEqual:summaryTableView])
        keys = summaryKeys;
    else if ([tv isEqual:attributesTableView])
        keys = attributesKeys;
    NSString *key = [keys objectAtIndex:row];
    NSString *tcID = [tableColumn identifier];
    id value = nil;
    if ([key length]) {
        if ([tcID isEqualToString:@"label"]) {
            value = [self labelForKey:key];
        } else if ([tcID isEqualToString:@"value"]) {
            value = [info objectForKey:key];
            if (value == nil)
                value = @"-";
            else if ([value isKindOfClass:[NSDate class]])
                value = [shortDateFormatter stringFromDate:value];
            else if ([value isKindOfClass:[NSNumber class]])
                value = ([key isEqualToString:SKInfoPageCountKey] ? [value stringValue] : ([value boolValue] ? NSLocalizedString(@"Yes", @"") : NSLocalizedString(@"No", @"")));
        }
    }
    return value;
}

- (void)tableView:(NSTableView *)tv willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if ([tv isEqual:attributesTableView] && [[tableColumn identifier] isEqualToString:@"label"])
        [cell setLineBreakMode:row == [tv numberOfRows] - 1 ? NSLineBreakByWordWrapping : NSLineBreakByTruncatingTail];
}

- (CGFloat)tableView:(NSTableView *)tv heightOfRow:(NSInteger)row {
    CGFloat rowHeight = [tv rowHeight];
    if ([tv isEqual:attributesTableView] && row == [tv numberOfRows] - 1)
        rowHeight = fmax(rowHeight, NSHeight([[tv enclosingScrollView] bounds]) - [tv numberOfRows] * (rowHeight + [tv intercellSpacing].height) + rowHeight);
    return rowHeight;
}

- (BOOL)tableView:(NSTableView *)tv shouldSelectRow:(NSInteger)row {
    return NO;
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
