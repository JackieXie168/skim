// Copyright 2000-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OAWindowCascade.h,v 1.10 2004/02/10 04:07:39 kc Exp $

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
