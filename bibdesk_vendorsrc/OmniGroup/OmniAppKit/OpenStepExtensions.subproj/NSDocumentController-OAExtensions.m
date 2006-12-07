// Copyright 2001-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import "NSDocumentController-OAExtensions.h"
#import <OmniFoundation/OmniFoundation.h>
#import <OmniBase/OmniBase.h>
#import <Carbon/Carbon.h>
#import <AppKit/AppKit.h>
#import <CoreFoundation/CoreFoundation.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSDocumentController-OAExtensions.m,v 1.4 2003/01/15 22:51:36 kc Exp $")

@implementation NSDocumentController (OAExtensions)

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
        
    if (FSPathMakeRef([filename UTF8String], &myFSRef, NULL))
        return NO;
    if (FSGetCatalogInfo(&myFSRef, kFSCatInfoNone, NULL, NULL, &myFSSpec, NULL))
        return NO;
    FSpGetFInfo(&myFSSpec, &myFInfo);
    return (myFInfo.fdFlags & 2048) != 0; // kIsStationary = 2048
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
