// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OAShelfViewDragSupportProtocol.h,v 1.6 2003/01/15 22:51:45 kc Exp $

@class NSArray, NSString;
@class NSEvent, NSImage, NSPasteboard, NSView;
@class OAPasteboardHelper;

#import <Foundation/NSGeometry.h> // For NSPoint

@protocol OAShelfViewDragSupport <NSObject>

/* dragging in */
- (NSArray *)acceptedPasteboardTypes;
- (NSArray *)entriesFromPropertyList:propertyList ofType:(NSString *)type;

/* dragging out */
- (NSImage *)dragImageForEntry:(id)anEntry;
- (void)declareTypesForEntries:(NSArray *)entries pasteboardHelper:(OAPasteboardHelper *)pasteboardHelper;

- (void)startDragOnEntry:anEntry fromView:(NSView *)aView image:(NSImage *)anImage atPoint:(NSPoint)location event:(NSEvent *)event pasteboardHelper:(OAPasteboardHelper *)pasteboardHelper;

@end
