// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Outline.subproj/OAOutlineFormatter.h,v 1.9 2003/01/15 22:51:40 kc Exp $

// This is the formatter base class - it provides much of the functionality for a formatter. In most cases, you'll use a subclass of these, but you can create your own completely new formatter as long as it conforms to the OAOutlineFormatter protocol.

#import <OmniFoundation/OFObject.h>

@class NSEvent;

#import <OmniAppKit/OAOutlineFormatterProtocol.h>

@interface OAOutlineFormatter : OFObject <OAOutlineFormatter>
{
    float entrySpacing; // vertical space between entries
}

- (void)setEntrySpacing:(float)spacing;
- (float)entrySpacing;

- (float)buttonWidth;

- (void)mouseDown:(NSEvent *)event inRect:(NSRect)rect ofEntry:(OAOutlineEntry *)anEntry;
- (void)mouseUp:(NSEvent *)event inRect:(NSRect)rect ofEntry:(OAOutlineEntry *)anEntry;

- (void)drawSelectionForEntry:(OAOutlineEntry *)anEntry entryRect:(NSRect)rect;

@end
