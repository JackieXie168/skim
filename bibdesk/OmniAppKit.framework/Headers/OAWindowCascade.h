// Copyright 2000-2002 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header$

#import <OmniFoundation/OFObject.h>

@class NSArray;
@class NSScreen;

#import <Foundation/NSGeometry.h> // For NSPoint, NSRect

@interface OAWindowCascade : OFObject
{
    NSRect lastStartingFrame;
    NSPoint lastWindowOrigin;
}

- (NSRect)nextWindowFrameFromStartingFrame:(NSRect)startingFrame avoidingWindows:(NSArray *)windowsToAvoid;
- (void)reset;

@end
