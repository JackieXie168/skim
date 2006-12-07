// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Outline.subproj/OAOutlineFormatterProtocol.h,v 1.9 2003/01/15 22:51:40 kc Exp $

// These protocols define the messages an entry in the outline view has to be able to handle.  In reality, you'll rarely (if ever) use anything but a subclass of OAOutlineFormatter (which already conforms to this protocol).

#import <Foundation/NSObject.h>

@class NSString;
@class NSEvent;
@class OAOutlineEntry;

#import <Foundation/NSGeometry.h> // For NSRect
#import <OmniAppKit/OAFindControllerTargetProtocol.h> // For OAFindPattern

// A basic formatter

@protocol OAOutlineFormatter <NSObject>

- (float)entryHeight:(OAOutlineEntry *)anEntry;

- (void)drawEntry:(OAOutlineEntry *)anEntry entryRect:(NSRect)rect selected:(BOOL)selected parent:(BOOL)parent hidden:(BOOL)hidden dragging:(BOOL)dragging;
    // The full rect of the entry is passed in as a convenience

- (void)trackMouse:(NSEvent *)event inRect:(NSRect)rect ofEntry:(OAOutlineEntry *)anEntry;

@end


// A formatter which supports find operations

@protocol OAOutlineFindableFormatter <OAOutlineFormatter>

- (BOOL)findPattern:(id <OAFindPattern>)pattern forEntry:(OAOutlineEntry *)anEntry;

@end


// A formatter which has support for editing

@protocol OAOutlineEditableFormatter <OAOutlineFormatter>

- (void)editEntry:(OAOutlineEntry *)anEntry entryRect:(NSRect)rect;
    // The full rect of the entry is provided as a convenience.

- (BOOL)isEditable;

@end
