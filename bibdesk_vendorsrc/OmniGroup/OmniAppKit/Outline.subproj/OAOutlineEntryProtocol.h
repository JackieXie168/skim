// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Outline.subproj/OAOutlineEntryProtocol.h,v 1.8 2003/01/15 22:51:40 kc Exp $

// This protocol defines the messages an entry in the outline view has to be able to handle. In reality, you'll rarely (if ever) use anything other than OAOutlineEntry itself.

#import <Foundation/NSObject.h>

@class NSEvent, NSPasteboard;
@class OAOutlineEntry;

#import <Foundation/NSGeometry.h> // For NSRect

@protocol OAOutlineEntry <NSObject>

- (float)entryHeight;

// entryRect is provided as a convenience - it's the rect of the entire OAOutlineEntry
- (void)drawRect:(NSRect)dirty entryRect:(NSRect)rect;

- (void)trackMouse:(NSEvent *)event inRect:(NSRect)rect ofEntry:(OAOutlineEntry *)anEntry;

@end
