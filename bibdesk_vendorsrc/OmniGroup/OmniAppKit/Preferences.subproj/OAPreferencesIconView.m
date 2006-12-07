// Copyright 2000-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OAPreferencesIconView.h"

#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>
#import <OmniFoundation/OmniFoundation.h>
#import <OmniBase/OmniBase.h>

#import "NSImage-OAExtensions.h"
#import "NSView-OAExtensions.h"
#import "OAPreferenceClient.h"
#import "OAPreferenceClientRecord.h"
#import "OAPreferenceController.h"

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Preferences.subproj/OAPreferencesIconView.m,v 1.15 2004/02/10 04:07:36 kc Exp $")

@interface OAPreferencesIconView (Private)
@end

@implementation OAPreferencesIconView

const NSSize buttonSize = {85.0, 56.0};
const NSSize iconSize = {32.0, 32.0};
const unsigned int titleBaseline = 3;
const unsigned int iconBaseline = 18;

// Init and dealloc

- (id)initWithFrame:(NSRect)rect;
{
    if (![super initWithFrame:rect])
        return nil;

    pressedIconIndex = NSNotFound;
    selectedClientRecord = nil;
    return self;
}

// API

- (void)setPreferenceController:(OAPreferenceController *)newPreferenceController;
{
    [preferenceController autorelease];
    preferenceController = [newPreferenceController retain];
    [self setNeedsDisplay:YES];
}

- (void)setPreferenceClientRecords:(NSArray *)newPreferenceClientRecords;
{
    [preferenceClientRecords autorelease];
    preferenceClientRecords = [newPreferenceClientRecords retain];
    [self _sizeToFit];
    [self setNeedsDisplay:YES];
}
- (NSArray *)preferenceClientRecords;
{
    return preferenceClientRecords;
}

- (void)setSelectedClientRecord:(OAPreferenceClientRecord *)newSelectedClientRecord;
{
    selectedClientRecord = newSelectedClientRecord;
    [self setNeedsDisplay:YES];
}


// NSResponder

- (void)mouseDown:(NSEvent *)event;
{
    NSPoint eventLocation;
    NSRect slopRect;
    const float dragSlop = 4.0;
    unsigned int index;
    NSRect buttonRect;
    BOOL mouseInBounds = NO;
    
    eventLocation = [self convertPoint:[event locationInWindow] fromView:nil];
    slopRect = NSInsetRect(NSMakeRect(eventLocation.x, eventLocation.y, 1.0, 1.0), -dragSlop, -dragSlop);

    index = floor(eventLocation.x / buttonSize.width) + floor(eventLocation.y / buttonSize.height) * [self _iconsWide];
    buttonRect = [self _boundsForIndex:index];
    if (NSWidth(buttonRect) == 0)
        return;
        
    pressedIconIndex = index;
    [self setNeedsDisplay:YES];

    while (1) {
        NSEvent *nextEvent;
        NSPoint nextEventLocation;
        unsigned int newPressedIconIndex;

        nextEvent = [NSApp nextEventMatchingMask:NSLeftMouseDraggedMask|NSLeftMouseUpMask untilDate:[NSDate distantFuture] inMode:NSEventTrackingRunLoopMode dequeue:YES];

        nextEventLocation = [self convertPoint:[nextEvent locationInWindow] fromView:nil];
        mouseInBounds = NSMouseInRect(nextEventLocation, buttonRect, [self isFlipped]);
        newPressedIconIndex = mouseInBounds ? index : NSNotFound;
        if (newPressedIconIndex != pressedIconIndex) {
            pressedIconIndex = newPressedIconIndex;
            [self setNeedsDisplay:YES];
        }

        if ([nextEvent type] == NSLeftMouseUp)
            break;
        else if (!NSMouseInRect(nextEventLocation, slopRect, NO)) {
            if ([self _dragIconIndex:index event:nextEvent]) {
                mouseInBounds = NO;
                break;
            }
        }
    }
    
    pressedIconIndex = NSNotFound;
    [self setNeedsDisplay:YES];
    
    if (mouseInBounds)
        [preferenceController iconView:self buttonHitAtIndex:index];
}


// NSView subclass

- (void)drawRect:(NSRect)rect;
{
    unsigned int clientRecordIndex, clientRecordCount;
    
    clientRecordCount = [self _numberOfIcons];
    for (clientRecordIndex = 0; clientRecordIndex < clientRecordCount; clientRecordIndex++)
        [self _drawIconAtIndex:clientRecordIndex drawRect:rect];
}

- (BOOL)isFlipped;
{
    return YES;
}

- (BOOL)isOpaque;
{
    return NO;
}

- (BOOL)mouseDownCanMoveWindow;
{
    // Mouse drags should drag our icons, not the window (even though we're not opaque).
    return NO;
}

// NSDraggingSource

- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)flag;
{
    return NSDragOperationMove;
}

- (void)draggedImage:(NSImage *)image endedAt:(NSPoint)screenPoint operation:(NSDragOperation)operation;
{
}

- (BOOL)ignoreModifierKeysWhileDragging;
{
    return YES;
}


@end


@implementation OAPreferencesIconView (Subclasses)

- (unsigned int)_iconsWide;
{
    return NSWidth([self bounds]) / buttonSize.width;
}

- (unsigned int)_numberOfIcons;
{
    return [[self preferenceClientRecords] count];
}

- (BOOL)_isIconSelectedAtIndex:(unsigned int)index;
{
    return [[self preferenceClientRecords] objectAtIndex:index] == selectedClientRecord;
}

- (BOOL)_column:(unsigned int *)column andRow:(unsigned int *)row forIndex:(unsigned int)index;
{
    if (index >= [self _numberOfIcons])
        return NO;

    *column = index / [self _iconsWide];
    *row = index % [self _iconsWide];
    
    return YES;
}

- (NSRect)_boundsForIndex:(unsigned int)index;
{
    unsigned int row, column;

    if (![self _column:&column andRow:&row forIndex:index])
        return NSZeroRect;
        
    return NSMakeRect(row * buttonSize.width, column * buttonSize.height, buttonSize.width, buttonSize.height);
}

- (BOOL)_iconImage:(NSImage **)image andName:(NSString **)name forIndex:(unsigned int)index;
{
    NSString *unused;
    return [self _iconImage:image andName:name andIdentifier:&unused forIndex:index];
}

- (BOOL)_iconImage:(NSImage **)image andName:(NSString **)name andIdentifier:(NSString **)identifier forIndex:(unsigned int)index;
{
    OAPreferenceClientRecord *clientRecord;
    
    if (index >= [self _numberOfIcons])
        return NO;
    
    clientRecord = [[self preferenceClientRecords] objectAtIndex:index];
    *image = [clientRecord iconImage];
    *name = [clientRecord shortTitle];
    *identifier = [clientRecord identifier];

    OBPOSTCONDITION(*image != nil);
    OBPOSTCONDITION(*name != nil);
    OBPOSTCONDITION(*identifier != nil);
    
    return YES;
}


- (void)_drawIconAtIndex:(unsigned int)index drawRect:(NSRect)drawRect;
{
    NSImage *image;
    NSString *name;
    unsigned int row, column;
    NSPoint drawPoint;
    NSSize nameSize;
    NSRect buttonRect, destinationRect;
    NSDictionary *attributesDictionary;
    
    buttonRect = [self _boundsForIndex:index];
    if (!NSIntersectsRect(buttonRect, drawRect))
        return;

    if (![self _iconImage:&image andName:&name forIndex:index])
        return;
    
    if (![self _column:&column andRow:&row forIndex:index])
        return;

    // Draw dark gray rectangle around currently selected icon (for MultipleIconView)
    if ([self _isIconSelectedAtIndex:index]) {
        [[NSColor colorWithCalibratedWhite:0.8 alpha:0.75] set];
        NSRectFillUsingOperation(buttonRect, NSCompositeSourceOver);
    }

    // Draw icon, dark if it is currently being pressed
    destinationRect = NSIntegralRect(NSMakeRect(NSMidX(buttonRect) - iconSize.width / 2.0, NSMaxY(buttonRect) - iconBaseline - iconSize.height, iconSize.width, iconSize.height));
    destinationRect.size = iconSize;
    if (index != pressedIconIndex)
        [image drawFlippedInRect:destinationRect operation:NSCompositeSourceOver fraction:1.0];
    else {
        NSImage *darkImage;
        NSSize darkImageSize;
        
        darkImage = [image copy];
        darkImageSize = [darkImage size];
        [darkImage lockFocus];
        [[NSColor blackColor] set];
        NSRectFillUsingOperation(NSMakeRect(0, 0, darkImageSize.width, darkImageSize.height), NSCompositeSourceIn);
        [darkImage unlockFocus];
        
        [darkImage drawFlippedInRect:destinationRect operation:NSCompositeSourceOver fraction:1.0];
        [image drawFlippedInRect:destinationRect operation:NSCompositeSourceOver fraction:0.6666];
        [darkImage release];
    }
    
    // Draw text
    attributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont toolTipsFontOfSize:11.0], NSFontAttributeName, nil];
    
    nameSize = [name sizeWithAttributes:attributesDictionary];
    drawPoint = NSMakePoint(rint(NSMidX(buttonRect) - nameSize.width / 2.0), rint(NSMaxY(buttonRect) - titleBaseline - nameSize.height));
    [name drawAtPoint:drawPoint withAttributes:attributesDictionary];
}

- (void)_drawBackgroundForRect:(NSRect)rect;
{
    [[NSColor controlLightHighlightColor] set];
    NSRectFill(rect);
    [[NSColor windowFrameColor] set];
    NSRectFill(NSMakeRect(NSMinX(_bounds), NSMinY(_bounds), NSWidth(_bounds), 1.0));
    NSRectFill(NSMakeRect(NSMinX(_bounds), NSMaxY(_bounds)-1, NSWidth(_bounds), 1.0));
}

- (void)_sizeToFit;
{
    if (![self preferenceClientRecords])
        return;
        
    [self setFrameSize:NSMakeSize(NSWidth(_bounds), NSMaxY([self _boundsForIndex:[self _numberOfIcons]-1]))];
}

- (BOOL)_dragIconIndex:(unsigned int)index event:(NSEvent *)event;
{
    NSImage *iconImage;
    NSString *name;
    NSString *identifier;
    
    if (![self _iconImage:&iconImage andName:&name andIdentifier:&identifier forIndex:index])
        return YES; // Yes, I handled your stinky bad call.
    
    return [self _dragIconImage:iconImage andName:name andIdentifier:identifier event:event];
}

- (BOOL)_dragIconImage:(NSImage *)iconImage andName:(NSString *)name event:(NSEvent *)event;
{
    return [self _dragIconImage:iconImage andName:name andIdentifier:name event:event];
}

- (BOOL)_dragIconImage:(NSImage *)iconImage andName:(NSString *)name andIdentifier:(NSString *)identifier event:(NSEvent *)event;
{
    NSImage *dragImage;
    NSPasteboard *pasteboard;
    NSPoint dragPoint, startPoint;

    dragImage = [[NSImage alloc] initWithSize:buttonSize];
    [dragImage lockFocus]; {
        NSSize nameSize;
        NSDictionary *attributesDictionary;
        
        [iconImage drawInRect:NSMakeRect(buttonSize.width / 2.0 - iconSize.width / 2.0, iconBaseline, iconSize.width, iconSize.height) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
        
        attributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont toolTipsFontOfSize:11.0], NSFontAttributeName, nil];
        nameSize = [name sizeWithAttributes:attributesDictionary];
        [name drawAtPoint:NSMakePoint(buttonSize.width / 2.0 - nameSize.width / 2.0, titleBaseline) withAttributes:attributesDictionary];
    } [dragImage unlockFocus];
       
    pasteboard = [NSPasteboard pasteboardWithName:NSDragPboard];
    [pasteboard declareTypes:[NSArray arrayWithObject:@"NSToolbarIndividualItemDragType"] owner:nil];
    [pasteboard setString:identifier forType:@"NSToolbarItemIdentifierPboardType"];
    [pasteboard setString:identifier forType:@"NSToolbarItemIdentiferPboardType"]; // Apple misspelled this type in 10.1
    
    dragPoint = [self convertPoint:[event locationInWindow] fromView:nil];
    startPoint = NSMakePoint(dragPoint.x - buttonSize.width / 2.0, dragPoint.y + buttonSize.height / 2.0);
    [self dragImage:dragImage at:startPoint offset:NSZeroSize event:event pasteboard:pasteboard source:self slideBack:NO];
    
    return YES;
}


@end

@implementation OAPreferencesIconView (Private)
@end
