// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Outline.subproj/OAOutlineDragSupportProtocol.h,v 1.9 2003/01/15 22:51:40 kc Exp $

// This protocol defines the messages defined by a drag support object to define to enable dragging (and copying) of entries in an outline view.

// The outline view parameter in most of these lets the drag support object conceivably handle more than one outline view.

@class NSArray, NSString;
@class NSEvent, NSImage, NSPasteboard, NSView;
@class OAOutlineEntry, OAOutlineView, OAPasteboardHelper;

#import <Foundation/NSGeometry.h> // for NSPoint

@protocol OAOutlineDragSupport

// DRAGGING IN

- (NSArray *)outlineViewAcceptedPasteboardTypes:(OAOutlineView *)aView;
    // Return an array of pasteboard types which the outline view should accept

- (OAOutlineEntry *)outlineView:(OAOutlineView *)aView entryFromPropertyList:(id)propertyList pasteboardType:(NSString *)type parentEntry:(OAOutlineEntry *)parentEntry;
    // Create a new entry from the pasteboard underneath the specified parent entry.

- (OAOutlineEntry *)outlineView:(OAOutlineView *)aView emptyEntryWithParent:(OAOutlineEntry *)parentEntry;
    // Return a new empty entry (with a blank representedObject) underneath the specified parent entry


// DRAGGING OUT

- (NSImage *)outlineView:(OAOutlineView *)aView dragImageForEntry:(OAOutlineEntry *)anEntry;
    // Return the image to be dragged as the given entry is dragged

- (void)outlineView:(OAOutlineView *)aView declareTypesForEntry:(OAOutlineEntry *)anEntry pasteboardHelper:(OAPasteboardHelper *)pasteboardHelper;
    // Tell the pasteboard helper what types we can provide from the given entry

- (void)outlineView:(OAOutlineView *)aView startDragOnEntry:(OAOutlineEntry *)anEntry fromView:(NSView *)view image:(NSImage *)image atPoint:(NSPoint)location event:(NSEvent *)event pasteboardHelper:(OAPasteboardHelper *)pasteboardHelper;
    // Start the drag operation

- (void)pasteboard:(NSPasteboard *)pasteboard provideData:(OAOutlineEntry *)anEntry forType:(NSString *)aType;
    // Provide data of the requested type to the pasteboard (for the specified outline entry)

@end

@protocol OAOutlineOptionalDragSupport

- (NSPoint)outlineView:(OAOutlineView *)aView dragImageCursorPositionForEntry:(OAOutlineEntry *)anEntry;
    // The cursor will be positioned at this point over the image during the drag.  (If not implemented, the cursor will be positioned over the center of the image.)

@end
