// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OADragController.h,v 1.12 2003/01/15 22:51:30 kc Exp $

#import <OmniFoundation/OFObject.h>

@class NSArray;
@class NSEvent, NSImage, NSPasteboard, NSView;
@class OAPasteboardHelper;

#import <Foundation/NSGeometry.h> // For NSPoint
#import <OmniFoundation/OFWeakRetainConcreteImplementation.h>

@interface OADragController : OFObject <OFWeakRetain>
{
    NSPasteboard *draggingPasteboard;
    OAPasteboardHelper *pasteboardHelper;
    NSView *draggingFromView;
    id delegate;
}

+ (OADragController *)sharedDragController;

- (void)startDragFromView:(NSView *)view image:(NSImage *)image atPoint:(NSPoint)location offset:(NSPoint)offset event:(NSEvent *)event slideBack:(BOOL)slideBack pasteboardHelper:(OAPasteboardHelper *)newPasteboardHelper delegate:(id)newDelegate;

- (NSView *)view;

@end

