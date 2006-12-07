// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import <OmniAppKit/NSApplication-OAExtensions.h>

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/OmniFoundation.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSApplication-OAExtensions.m,v 1.10 2003/01/15 22:51:35 kc Exp $")

@implementation NSApplication (OAExtensions)

- (BOOL)useColor;
{
    return NSNumberOfColorComponents (
	    NSColorSpaceFromDepth([NSWindow defaultDepthLimit])) > 1;
}

- (NSEvent *)peekEvent;
{
    NSString *mode;
    
    if (!(mode = [[NSRunLoop currentRunLoop] currentMode]))
        // NSApp crashes on nil modes in DP4
        mode = NSDefaultRunLoopMode;

    // We get system-defined events quite frequently, so ignore them.
    return [self nextEventMatchingMask:(NSAnyEventMask & ~NSSystemDefinedMask) untilDate:[NSDate distantPast] inMode:mode dequeue:NO];
}

@end
