// Copyright 2003-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "NSWorkspace-OAExtensions.h"

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <OmniBase/OmniBase.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSWorkspace-OAExtensions.m,v 1.4 2004/02/10 04:07:35 kc Exp $");

@implementation NSWorkspace (OAExtensions)

- (NSString *)fullPathForApplicationWithIdentifier:(NSString *)bundleIdentifier;
{
    CFURLRef appURL;
    OSStatus status;

    status = LSFindApplicationForInfo(kLSUnknownCreator, (CFStringRef)bundleIdentifier, NULL, NULL, &appURL);
    if (status != noErr) {
        return nil;
    }
    return [(NSURL *)appURL path];
}

@end

