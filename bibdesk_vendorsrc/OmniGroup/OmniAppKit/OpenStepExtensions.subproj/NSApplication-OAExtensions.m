// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniAppKit/NSApplication-OAExtensions.h>

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/OmniFoundation.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSApplication-OAExtensions.m,v 1.12 2004/02/10 04:07:33 kc Exp $")

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
