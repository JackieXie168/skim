// Copyright 2001-2005 Omni Development, Inc.  All rights reserved.
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

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/SourceRelease_2005-10-03/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSDocumentController-OAExtensions.m 66030 2005-07-25 19:52:44Z kc $")

@implementation NSDocumentController (OAExtensions)

static id (*originalOpenDocumentIMP)(id, SEL, NSString *, BOOL);

+ (void)didLoad;
{
    originalOpenDocumentIMP = (typeof(originalOpenDocumentIMP))OBReplaceMethodImplementationWithSelector(self, @selector(openDocumentWithContentsOfFile:display:), @selector(OAOpenDocumentWithContentsOfFile:display:));
}

- (BOOL)fileIsStationaryPad:(NSString *)filename;
{
    const char *utf8 = [filename UTF8String];
    if (utf8 == NULL)
        return NO; // Protect FSPathMakeRef() from crashing
    FSRef myFSRef;
    if (FSPathMakeRef((UInt8 *)utf8, &myFSRef, NULL))
        return NO;
    FSCatalogInfo catalogInfo;
    if (FSGetCatalogInfo(&myFSRef, kFSCatInfoFinderInfo, &catalogInfo, NULL, NULL, NULL) != noErr)
        return NO;
    return (((FileInfo *)(&catalogInfo.finderInfo))->finderFlags & kIsStationery) != 0;
}

- (id)OAOpenDocumentWithContentsOfFile:(NSString *)fileName display:(BOOL)flag
{
    NSDocument *document;
    
    document = originalOpenDocumentIMP(self, _cmd, fileName, flag);
    if ([self fileIsStationaryPad:fileName])
        [document setFileName:nil];
    return document;
}


@end
