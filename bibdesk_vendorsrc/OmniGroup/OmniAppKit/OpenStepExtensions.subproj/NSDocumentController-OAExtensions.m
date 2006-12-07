// Copyright 2001-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "NSDocumentController-OAExtensions.h"
#import <OmniFoundation/OmniFoundation.h>
#import <OmniBase/OmniBase.h>
#import <Carbon/Carbon.h>
#import <AppKit/AppKit.h>
#import <CoreFoundation/CoreFoundation.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSDocumentController-OAExtensions.m,v 1.8 2004/02/10 04:07:34 kc Exp $")

@implementation NSDocumentController (OAExtensions)

/*
static NSString *autosavePath = nil;
static NSMutableDictionary *autosavedFiles = nil;
static int nextAutosaveNumber = 0;
*/

static id (*originalOpenDocumentIMP)(id, SEL, NSString *, BOOL);

+ (void)didLoad;
{
    originalOpenDocumentIMP = (typeof(originalOpenDocumentIMP))OBReplaceMethodImplementationWithSelector(self, @selector(openDocumentWithContentsOfFile:display:), @selector(OAOpenDocumentWithContentsOfFile:display:));
}

- (BOOL)fileIsStationaryPad:(NSString *)filename;
{
    FSRef myFSRef;
    FSSpec myFSSpec;
    FInfo myFInfo;
    const char *utf8;

    utf8 = [filename UTF8String];
    if (utf8 == NULL)
        return NO; // Protect FSPathMakeRef() from crashing
    if (FSPathMakeRef(utf8, &myFSRef, NULL))
        return NO;
    if (FSGetCatalogInfo(&myFSRef, kFSCatInfoNone, NULL, NULL, &myFSSpec, NULL))
        return NO;
    FSpGetFInfo(&myFSSpec, &myFInfo);
    return (myFInfo.fdFlags & 2048) != 0; // kIsStationary = 2048
}

/*
- (void)writeAutosavePlist;
{
    [autosavedFiles setObject:[NSNumber numberWithInt:nextAutosaveNumber] forKey:@"__nextAutosaveNumber"];
    [autosavedFiles writeToFile:[autosavePath stringByAppendingPathComponent:@"saves.plist"] atomically:YES];
    [autosavedFiles removeObjectForKey:@"__nextAutosaveNumber"];
}

- (NSString *)pathToAutosaveForFile:(NSString *)fileName createNew:(BOOL)shouldCreate;
{
    NSString *result;
    
    if (!autosavedFiles) {
        NSDictionary *loaded;
        
        autosavePath = [@"~/Library/AutoSave/" stringByExpandingTildeInPath];
        autosavePath = [[autosavePath stringByAppendingPathComponent:[[NSBundle mainBundle] bundleIdentifier]] retain]; 
        loaded = [NSDictionary dictionaryWithContentsOfFile:[autosavePath stringByAppendingPathComponent:@"saves.plist"]];
        if (loaded == nil) {
            [[NSFileManager defaultManager] createPath:autosavePath attributes:nil];
            nextAutosaveNumber = 1;
            autosavedFiles = [[NSMutableDictionary alloc] init];
        } else {
            nextAutosaveNumber = [[loaded objectForKey:@"__nextAutosaveNumber"] intValue];
            autosavedFiles = [[NSMutableDictionary alloc] initWithDictionary:loaded];
            [autosavedFiles removeObjectForKey:@"__nextAutosaveNumber"];
        }
    }
    result = [autosavedFiles objectForKey:fileName];
    if (result == nil && shouldCreate) {
        NSString *autosaveNumber = [NSString stringWithFormat:@"%d", nextAutosaveNumber++];
        [autosavedFiles setObject:autosaveNumber forKey:fileName];
        [self writeAutosavePlist];
    }
    if (result != nil)
        result = [autosavePath stringByAppendingPathComponent:result];
    return result;
}

- (void)performAutosave;
{
    NSEnumerator *enumerator;
    NSDocument *document;
    NSMutableSet *fileNames = [NSMutableSet set];
    NSString *fileName;
    BOOL didDiscards = NO;
    
    // autosave any edited documents
    enumerator = [[self documents] objectEnumerator];
    while ((document = [enumerator nextObject])) {
        NSString *autosavePath;
        
        fileName = [document fileName];        
        if (fileName == nil || ![document isDocumentEdited])
            continue;
        
        [fileNames addObject:fileName];
        autosavePath = [self pathToAutosaveForFile:fileName createNew:YES];
        [document writeToFile:autosavePath ofType:[document fileType]];
    }
    
    if (autosavedFiles == nil)
        return;
        
    // discard old autosaves        
    enumerator = [[autosavedFiles allKeys] objectEnumerator]; // allKeys makes copy of key array since we're going to change things
    while ((fileName = [enumerator nextObject])) {
        if ([fileNames containsObject:fileName])
            continue;
        
        didDiscards = YES;
        [[NSFileManager defaultManager] removeFileAtPath:[self pathToAutosaveForFile:fileName createNew:NO] handler:nil];
        [autosavedFiles removeObjectForKey:fileName];
    }
    
    if (didDiscards) {
        if (![autosavedFiles count])
            nextAutosaveNumber = 1;
        [self writeAutosavePlist];
    }
}

- (BOOL)hasNewerAutosave;
{
    
}
*/
- (id)OAOpenDocumentWithContentsOfFile:(NSString *)fileName display:(BOOL)flag
{
    NSDocument *document;
    
    document = originalOpenDocumentIMP(self, _cmd, fileName, flag);
    if ([self fileIsStationaryPad:fileName])
        [document setFileName:nil];
    return document;
}


@end
