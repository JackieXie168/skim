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

- (void)fillInfoForDocument:(SKDocument *)doc {
    PDFDocument *pdfDoc = [doc pdfDocument];
    [self setInfo:[pdfDoc documentAttributes]];
    if (doc) {
        NSString *fileName = [[doc fileName] lastPathComponent];
        [info setValue:[[doc fileName] lastPathComponent] forKey:@"FileName"];
        [info setValue:[NSString stringWithFormat: @"%d.%d", [pdfDoc majorVersion], [pdfDoc minorVersion]] forKey:@"Version"];
        [info setValue:[NSNumber numberWithInt:[pdfDoc pageCount]] forKey:@"PageCount"];
        NSDictionary *fileAttrs = [[NSFileManager defaultManager] fileAttributesAtPath:fileName traverseLink:NO];
        unsigned long long size = [[fileAttrs objectForKey:NSFileSize] unsignedLongLongValue];
        NSString *fileSize = nil;
        if (size < 1024.0)
            fileSize = [NSString stringWithFormat:@"%.0f B", size * 1.0f];
        else if (size < 1024.0 * 1024.0)
            fileSize = [NSString stringWithFormat:@"%.0f KB", size / 1024.0f];
        else
            fileSize = [NSString stringWithFormat:@"%.1f MB", size / ( 1024.0 * 1024.0f)];
        [info setValue:fileSize forKey:@"FileSize"];
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
