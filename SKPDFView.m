//
//  SKPDFView.m


//  This code is licensed under a BSD license. Please see the file LICENSE for details.
//
//  Created by Michael McCracken on 12/6/06.
//  Copyright 2006 Michael O. McCracken. All rights reserved.
//

#import "SKPDFView.h"
#import "SKNavigationWindow.h"
#import "SKPDFHoverWindow.h"
#import "SKMainWindowController.h"
#import "SKPDFAnnotationNote.h"
#import "PDFPage_SKExtensions.h"
#import "NSString_SKExtensions.h"
#import "NSCursor_SKExtensions.h"

NSString *SKPDFViewToolModeChangedNotification = @"SKPDFViewToolModeChangedNotification";
NSString *SKPDFViewAnnotationModeChangedNotification = @"SKPDFViewAnnotationModeChangedNotification";
NSString *SKPDFViewActiveAnnotationDidChangeNotification = @"SKPDFViewActiveAnnotationDidChangeNotification";
NSString *SKPDFViewDidAddAnnotationNotification = @"SKPDFViewDidAddAnnotationNotification";
NSString *SKPDFViewDidRemoveAnnotationNotification = @"SKPDFViewDidRemoveAnnotationNotification";
NSString *SKPDFViewDidChangeAnnotationNotification = @"SKPDFViewDidChangeAnnotationNotification";
NSString *SKPDFViewAnnotationDoubleClickedNotification = @"SKPDFViewAnnotationDoubleClickedNotification";


@interface PDFView (PDFViewPrivateDeclarations)
- (void)pdfViewControlHit:(id)sender;
- (void)removeAnnotationControl;
@end

#pragma mark -

@interface SKPDFView (Private)

- (NSRect)resizeThumbForRect:(NSRect) rect rotation:(int)rotation;
- (void)transformContextForPage:(PDFPage *)page;

- (void)autohideTimerFired:(NSTimer *)aTimer;
- (void)doAutohide:(BOOL)flag;

- (NSCursor *)cursorForMouseMovedEvent:(NSEvent *)event;
- (PDFDestination *)destinationForEvent:(NSEvent *)theEvent isLink:(BOOL *)isLink;

- (void)selectAnnotationWithEvent:(NSEvent *)theEvent;
- (void)dragAnnotationWithEvent:(NSEvent *)theEvent;
- (void)selectSnapshotWithEvent:(NSEvent *)theEvent;
- (void)magnifyWithEvent:(NSEvent *)theEvent;
- (void)dragWithEvent:(NSEvent *)theEvent;

@end

#pragma mark -

@implementation SKPDFView

- (id)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        toolMode = SKTextToolMode;
        [[self window] setAcceptsMouseMovedEvents:YES];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        toolMode = SKTextToolMode;
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self doAutohide:NO]; // invalidates and releases the timer
    [[SKPDFHoverWindow sharedHoverWindow] orderOut:self];
    [navWindow release];
    [super dealloc];
}

#pragma mark Drawing

- (void)drawPage:(PDFPage *)pdfPage {
	// Let PDFView do most of the hard work.
	[super drawPage: pdfPage];
	
    NSArray *allAnnotations = [pdfPage annotations];
    
    if (allAnnotations) {
        unsigned int i, count = [allAnnotations count];
        BOOL foundActive = NO;
        
        [self transformContextForPage: pdfPage];
        
        for (i = 0; i < count; i++) {
            PDFAnnotation *annotation;
            
            annotation = [allAnnotations objectAtIndex: i];
            if ([annotation isNoteAnnotation]) {
                if (annotation == activeAnnotation) {
                    foundActive = YES;
                } else if ([[annotation type] isEqualToString:@"FreeText"]) {
                    NSRect bounds = [annotation bounds];
                    NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSInsetRect(NSIntegralRect(bounds), 0.5, 0.5)];
                    [path setLineWidth:1.0];
                    [[NSColor grayColor] set];
                    [path stroke];
                }
            }
        }
        
        // Draw active annotation last so it is not "painted" over.
        if (foundActive) {
            NSRect bounds = [activeAnnotation bounds];
            NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSInsetRect(NSIntegralRect(bounds), 0.5, 0.5)];
            [path setLineWidth:1.0];
            [[NSColor blackColor] set];
            [path stroke];
            
            // Draw resize handle.
            if ([activeAnnotation isResizable])
                NSRectFill(NSIntegralRect([self resizeThumbForRect:bounds rotation:[pdfPage rotation]]));
        }
    }
}

- (void)setNeedsDisplayInRect:(NSRect)rect ofPage:(PDFPage *)page {
    NSRect aRect = [self convertRect:rect fromPage:page];
    float scale = [self scaleFactor];
	NSPoint max = NSMakePoint(ceilf(NSMaxX(aRect)) + scale, ceilf(NSMaxY(aRect)) + scale);
	NSPoint origin = NSMakePoint(floorf(NSMinX(aRect)) - scale, floorf(NSMinY(aRect)) - scale);
	
    [self setNeedsDisplayInRect:NSMakeRect(origin.x, origin.y, max.x - origin.x, max.y - origin.y)];
}

- (void)setNeedsDisplayForAnnotation:(PDFAnnotation *)annotation {
    [self setNeedsDisplayInRect:[annotation bounds] ofPage:[annotation page]];
}

#pragma mark Accessors

- (SKToolMode)toolMode {
    return toolMode;
}

- (void)setToolMode:(SKToolMode)newToolMode {
    if (toolMode != newToolMode) {
        if (toolMode == SKTextToolMode && activeAnnotation) {
            if (editAnnotation)
                [self endAnnotationEdit:self];
            [self setActiveAnnotation:nil];
        }
    
        toolMode = newToolMode;
        [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewToolModeChangedNotification object:self];
        // hack to make sure we update the cursor
        [[self window] makeFirstResponder:self];
    }
}

- (SKAnnotationMode)annotationMode {
    return annotationMode;
}

- (void)setAnnotationMode:(SKAnnotationMode)newAnnotationMode {
    if (annotationMode != newAnnotationMode) {
        annotationMode = newAnnotationMode;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewAnnotationModeChangedNotification object:self];
    }
}

- (PDFAnnotation *)activeAnnotation {
	return activeAnnotation;
}

- (void)setActiveAnnotation:(PDFAnnotation *)newAnnotation {
	BOOL changed = newAnnotation != activeAnnotation;
	
	// Will need to redraw old active anotation.
	if (activeAnnotation != nil)
		[self setNeedsDisplayForAnnotation:activeAnnotation];
	
	// Assign.
	if (newAnnotation) {
		activeAnnotation = newAnnotation;
		activePage = [newAnnotation page];
		
		// Force redisplay.
		[self setNeedsDisplayForAnnotation:activeAnnotation];
	} else {
		activeAnnotation = nil;
		activePage = nil;
	}
	
	if (changed)
		[[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewActiveAnnotationDidChangeNotification object:self userInfo:nil];
}

#pragma mark Actions

- (void)delete:(id)sender
{
	if (activeAnnotation != nil)
        [self removeActiveAnnotation:self];
    else
        NSBeep();
}

#pragma mark Event Handling

- (void)keyDown:(NSEvent *)theEvent
{
    NSString *characters = [theEvent charactersIgnoringModifiers];
    unichar eventChar = [characters length] > 0 ? [characters characterAtIndex:0] : 0;
	unsigned int modifiers = [theEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask;
    BOOL isPresentation = hasNavigation && autohidesCursor;
    
	if (isPresentation && (eventChar == NSRightArrowFunctionKey)) {
        [self goToNextPage:self];
    } else if (isPresentation && (eventChar == NSLeftArrowFunctionKey)) {
		[self goToPreviousPage:self];
	} else if ((eventChar == NSDeleteCharacter) || (eventChar == NSDeleteFunctionKey)) {
		[self delete:self];
    } else if (isPresentation == NO && [self toolMode] == SKTextToolMode && ((eventChar == NSEnterCharacter) || (eventChar == NSFormFeedCharacter) || (eventChar == NSNewlineCharacter) || (eventChar == NSCarriageReturnCharacter))){
        if (activeAnnotation && activeAnnotation != editAnnotation)
            [self editActiveAnnotation:self];
    } else if (isPresentation == NO && [self toolMode] == SKTextToolMode && (eventChar == NSTabCharacter) && (modifiers & NSAlternateKeyMask)){
        NSArray *notes = [(SKMainWindowController *)[[self window] windowController] orderedNotes];
        if ([notes count] == 0)
            return;
        int index = 0;
        if (activeAnnotation) {
            [self endAnnotationEdit:self];
            index = [notes indexOfObject:activeAnnotation];
            if (modifiers & NSShiftKeyMask)
                index--;
            else
                index++;
            if (index >= (int)[notes count])
                index = 0;
            else if (index < 0)
                index = [notes count] - 1;
        }
        [self setActiveAnnotation:[notes objectAtIndex:index]];
        [[self documentView] scrollRectToVisible:[self convertRect:[self convertRect:[activeAnnotation bounds] fromPage:[activeAnnotation page]] toView:[self documentView]]];
	} else if (isPresentation == NO && activeAnnotation && ((eventChar == NSRightArrowFunctionKey) || (eventChar == NSLeftArrowFunctionKey) || (eventChar == NSUpArrowFunctionKey) || (eventChar == NSDownArrowFunctionKey))) {
        NSRect bounds = [activeAnnotation bounds];
        NSRect newBounds = bounds;
        PDFPage *page = [activeAnnotation page];
        NSRect pageBounds = [page boundsForBox:[self displayBox]];
        float delta = (modifiers & NSShiftKeyMask) ? 10.0 : 1.0;
        
        if (eventChar == NSRightArrowFunctionKey) {
            if (NSMaxX(bounds) + delta <= NSMaxX(pageBounds))
                newBounds.origin.x += delta;
        } else if (eventChar == NSLeftArrowFunctionKey) {
            if (NSMinX(bounds) - delta >= NSMinX(pageBounds))
                newBounds.origin.x -= delta;
        } else if (eventChar == NSUpArrowFunctionKey) {
            if (NSMaxY(bounds) + delta <= NSMaxY(pageBounds))
                newBounds.origin.y += delta;
        } else if (eventChar == NSDownArrowFunctionKey) {
            if (NSMinY(bounds) - delta >= NSMinY(pageBounds))
                newBounds.origin.y -= delta;
        }
        if (NSEqualRects(bounds, newBounds) == NO) {
            [activeAnnotation setBounds:newBounds];
            NSString *selString = [[[[activeAnnotation page] selectionForRect:newBounds] string] stringByCollapsingWhitespaceAndNewlinesAndRemovingSurroundingWhitespaceAndNewlines];
            [activeAnnotation setContents:selString];
            [self setNeedsDisplayInRect:NSUnionRect(bounds, newBounds) ofPage:page];
            [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewDidChangeAnnotationNotification object:self 
                userInfo:[NSDictionary dictionaryWithObjectsAndKeys:activeAnnotation, @"annotation", nil]];
        }
    } else {
		[super keyDown:theEvent];
    }
}

- (void)mouseDown:(NSEvent *)theEvent{
    [[SKPDFHoverWindow sharedHoverWindow] orderOut:self];
    
    switch (toolMode) {
        case SKMoveToolMode:
            [[NSCursor closedHandCursor] push];
            break;
        case SKTextToolMode:
            if ([theEvent modifierFlags] & NSCommandKeyMask)
                [self selectSnapshotWithEvent:theEvent];
            else if ([[self document] isLocked])
                [super mouseDown:theEvent];
            else 
                [self selectAnnotationWithEvent:theEvent];
            break;
        case SKMagnifyToolMode:
            [self magnifyWithEvent:theEvent];
            break;
    }
}

- (void)mouseUp:(NSEvent *)theEvent{
    switch (toolMode) {
        case SKMoveToolMode:
            [NSCursor pop];
            [[NSCursor openHandCursor] set];
            break;
        case SKTextToolMode:
            if (mouseDownInAnnotation) {
                mouseDownInAnnotation = NO;
                if ([[activeAnnotation type] isEqualToString:@"Circle"] || [[activeAnnotation type] isEqualToString:@"Square"]) {
                    NSString *selString = [[[[activeAnnotation page] selectionForRect:[activeAnnotation bounds]] string] stringByCollapsingWhitespaceAndNewlinesAndRemovingSurroundingWhitespaceAndNewlines];
                    [activeAnnotation setContents:selString];
                    [self setNeedsDisplayForAnnotation:activeAnnotation];
                    [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewDidChangeAnnotationNotification object:self 
                        userInfo:[NSDictionary dictionaryWithObjectsAndKeys:activeAnnotation, @"annotation", nil]];
                }
            } else
                [super mouseUp:theEvent];
        case SKMagnifyToolMode:
            [super mouseUp:theEvent];
            break;
    }
}

- (void)mouseDragged:(NSEvent *)theEvent {
    switch (toolMode) {
        case SKMoveToolMode:
            [self dragWithEvent:theEvent];	
            // ??? PDFView's delayed layout seems to reset the cursor to an arrow
            [self performSelector:@selector(mouseMoved:) withObject:theEvent afterDelay:0];
            break;
        case SKTextToolMode:
            if (mouseDownInAnnotation)
                [self dragAnnotationWithEvent:theEvent];
            else
                [super mouseDragged:theEvent];
            break;
        case SKMagnifyToolMode:
            [super mouseDragged:theEvent];
            break;
    }
}

- (void)mouseMoved:(NSEvent *)theEvent {
    
    // we receive this message whenever we are first responder, so check the location
    if (toolMode == SKTextToolMode) {
        NSPoint p = [[self documentView] convertPoint:[theEvent locationInWindow] fromView:nil];
        if (NSPointInRect(p, [[self documentView] visibleRect]) && [theEvent modifierFlags] & NSCommandKeyMask) 
            [[NSCursor cameraCursor] set];
        else
            [super mouseMoved:theEvent];
    } else {
        [[self cursorForMouseMovedEvent:theEvent] set];
    }
    
    BOOL isLink = NO;
    PDFDestination *dest = [self destinationForEvent:theEvent isLink:&isLink];

    if (isLink)
        [[SKPDFHoverWindow sharedHoverWindow] showWithDestination:dest atPoint:[[self window] convertBaseToScreen:[theEvent locationInWindow]] fromView:self];
    else
        [[SKPDFHoverWindow sharedHoverWindow] hide];
    
    // in presentation mode only show the navigation window only by moving the mouse to the bottom edge
    BOOL shouldShowNavWindow = hasNavigation && (autohidesCursor == NO || [theEvent locationInWindow].y < 5.0);
    if (autohidesCursor || shouldShowNavWindow) {
        if (shouldShowNavWindow && [navWindow isVisible] == NO) {
            [[self window] addChildWindow:navWindow ordered:NSWindowAbove];
            [navWindow orderFront:self];
        }
        [self doAutohide:YES];
    }
}

- (void)flagsChanged:(NSEvent *)theEvent {
    [super flagsChanged:theEvent];
    if (toolMode == SKTextToolMode) {
        if (selecting == NO) {
            NSCursor *cursor = ([theEvent modifierFlags] & NSCommandKeyMask) ? [NSCursor cameraCursor] : [NSCursor arrowCursor];
            [cursor set];
        }
    } else if (toolMode == SKMagnifyToolMode) {
        NSCursor *cursor = ([theEvent modifierFlags] & NSShiftKeyMask) ? [NSCursor zoomOutCursor] : [NSCursor zoomInCursor];
        [cursor set];
    }
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent {
    NSMenu *menu = [super menuForEvent:theEvent];
    NSMenu *submenu;
    NSMenuItem *item;
    
    if (hasNavigation && autohidesCursor)
        return menu;
    
    [menu addItem:[NSMenuItem separatorItem]];
    
    submenu = [[NSMenu allocWithZone:[menu zone]] init];
    
    item = [submenu addItemWithTitle:NSLocalizedString(@"Text", @"Menu item title") action:@selector(changeToolMode:) keyEquivalent:@""];
    [item setTag:SKTextToolMode];
    [item setTarget:[[self window] windowController]];

    item = [submenu addItemWithTitle:NSLocalizedString(@"Scroll", @"Menu item title") action:@selector(changeToolMode:) keyEquivalent:@""];
    [item setTag:SKMoveToolMode];
    [item setTarget:[[self window] windowController]];

    item = [submenu addItemWithTitle:NSLocalizedString(@"Magnify", @"Menu item title") action:@selector(changeToolMode:) keyEquivalent:@""];
    [item setTag:SKMagnifyToolMode];
    [item setTarget:[[self window] windowController]];
    
    item = [menu addItemWithTitle:NSLocalizedString(@"Tools", @"Menu item title") action:NULL keyEquivalent:@""];
    [item setSubmenu:submenu];
    [submenu release];

    submenu = [[NSMenu allocWithZone:[menu zone]] init];
    
    item = [submenu addItemWithTitle:NSLocalizedString(@"Text", @"Menu item title") action:@selector(changeAnnotationMode:) keyEquivalent:@""];
    [item setTag:SKFreeTextAnnotationMode];
    [item setTarget:[[self window] windowController]];
    
    item = [submenu addItemWithTitle:NSLocalizedString(@"Note", @"Menu item title") action:@selector(changeAnnotationMode:) keyEquivalent:@""];
    [item setTag:SKNoteAnnotationMode];
    [item setTarget:[[self window] windowController]];
    
    item = [submenu addItemWithTitle:NSLocalizedString(@"Oval", @"Menu item title") action:@selector(changeAnnotationMode:) keyEquivalent:@""];
    [item setTag:SKCircleAnnotationMode];
    [item setTarget:[[self window] windowController]];
    
    item = [menu addItemWithTitle:NSLocalizedString(@"Annotations", @"Menu item title") action:NULL keyEquivalent:@""];
    [item setSubmenu:submenu];
    [submenu release];
    
    if ([self toolMode] == SKTextToolMode) {
        
        NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        PDFPage *page = [self pageForPoint:point nearest:YES];
        PDFAnnotation *annotation = nil;
        
        if (page) {
            annotation = [page annotationAtPoint:[self convertPoint:point toPage:page]];
            if ([annotation isNoteAnnotation] == NO)
                annotation == nil;
        }
        
        [menu addItem:[NSMenuItem separatorItem]];
        
        item = [menu addItemWithTitle:NSLocalizedString(@"New Note", @"Menu item title") action:@selector(addAnnotation:) keyEquivalent:@""];
        [item setRepresentedObject:[NSValue valueWithPoint:point]];
        [item setTarget:self];
        
        if (annotation) {
            item = [menu addItemWithTitle:NSLocalizedString(@"Remove Note", @"Menu item title") action:@selector(removeThisAnnotation:) keyEquivalent:@""];
            [item setRepresentedObject:annotation];
            [item setTarget:self];
            
            if (annotation != activeAnnotation || editAnnotation == nil) {
                item = [menu addItemWithTitle:NSLocalizedString(@"Edit Note", @"Menu item title") action:@selector(editThisAnnotation:) keyEquivalent:@""];
                [item setRepresentedObject:annotation];
                [item setTarget:self];
            }
        } else if (activeAnnotation) {
            item = [menu addItemWithTitle:NSLocalizedString(@"Remove Current Note", @"Menu item title") action:@selector(removeActiveAnnotation:) keyEquivalent:@""];
            [item setTarget:self];
            
            if (editAnnotation == nil) {
                item = [menu addItemWithTitle:NSLocalizedString(@"Edit Current Note", @"Menu item title") action:@selector(editActiveAnnotation:) keyEquivalent:@""];
                [item setTarget:self];
            }
        }
        
    }
    
    return menu;
}

#pragma mark Annotation management

- (void)addAnnotation:(id)sender{
	PDFAnnotation *newAnnotation = nil;
	PDFPage *page;
	NSRect bounds;
    PDFSelection *selection = [self currentSelection];
    NSString *text = [[selection string] stringByCollapsingWhitespaceAndNewlinesAndRemovingSurroundingWhitespaceAndNewlines];
    
	// Determine bounds to use for new text annotation.
	if ([sender respondsToSelector:@selector(representedObject)] && [[sender representedObject] respondsToSelector:@selector(pointValue)]) {
        NSPoint point = [[sender representedObject] pointValue];
		NSSize defaultSize = ([self annotationMode] == SKTextAnnotationMode || [self annotationMode] == SKNoteAnnotationMode) ? NSMakeSize(16.0, 16.0) : NSMakeSize(128.0, 64.0);
        
        page = [self pageForPoint:point nearest:YES];
        point = [self convertPoint:point toPage:page];
        bounds = NSMakeRect(point.x - 0.5 * defaultSize.width, point.y - 0.5 * defaultSize.height, defaultSize.width, defaultSize.height);
	} else if (selection != nil) {
		// Get bounds (page space) for selection (first page in case selection spans multiple pages).
		page = [[selection pages] objectAtIndex: 0];
		bounds = [selection boundsForPage: page];
	} else {
		// Get center of the PDFView.
		NSRect viewFrame = [self frame];
		NSPoint center = NSMakePoint(NSMidX(viewFrame), NSMidY(viewFrame));
		NSSize defaultSize = ([self annotationMode] == SKTextAnnotationMode || [self annotationMode] == SKNoteAnnotationMode) ? NSMakeSize(16.0, 16.0) : NSMakeSize(128.0, 64.0);
		
		// Convert to "page space".
		page = [self pageForPoint: center nearest: YES];
		center = [self convertPoint: center toPage: page];
        bounds = NSMakeRect(center.x - 0.5 * defaultSize.width, center.y - 0.5 * defaultSize.height, defaultSize.width, defaultSize.height);
	}
	
	// Create annotation and add to page.
    switch ([self annotationMode]) {
        case SKFreeTextAnnotationMode:
            newAnnotation = [[SKPDFAnnotationFreeText alloc] initWithBounds:bounds];
            break;
        case SKTextAnnotationMode:
            newAnnotation = [[SKPDFAnnotationText alloc] initWithBounds:bounds];
            break;
        case SKNoteAnnotationMode:
            newAnnotation = [[SKPDFAnnotationNote alloc] initWithBounds:bounds];
            break;
        case SKCircleAnnotationMode:
            newAnnotation = [[SKPDFAnnotationCircle alloc] initWithBounds:NSInsetRect(bounds, -5.0, -5.0)];
            if (text == nil)
                text = [[[page selectionForRect:bounds] string] stringByCollapsingWhitespaceAndNewlinesAndRemovingSurroundingWhitespaceAndNewlines];
            break;
        case SKSquareAnnotationMode:
            newAnnotation = [[PDFAnnotationSquare alloc] initWithBounds:bounds];
            if (text == nil)
                text = [[[page selectionForRect:bounds] string] stringByCollapsingWhitespaceAndNewlinesAndRemovingSurroundingWhitespaceAndNewlines];
            break;
	}
    [newAnnotation setContents:text ? text : NSLocalizedString(@"New note", @"Default text for new note")];
    
    [page addAnnotation:newAnnotation];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewDidAddAnnotationNotification object:self 
        userInfo:[NSDictionary dictionaryWithObjectsAndKeys:newAnnotation, @"annotation", page, @"page", nil]];

    [self setActiveAnnotation:newAnnotation];
}

- (void)removeActiveAnnotation:(id)sender{
    if (activeAnnotation)
        [self removeAnnotation:activeAnnotation];
}

- (void)removeThisAnnotation:(id)sender{
    PDFAnnotation *annotation = [sender representedObject];
    
    if (annotation)
        [self removeAnnotation:annotation];
}

- (void)removeAnnotation:(PDFAnnotation *)annotation{
    PDFAnnotation *wasAnnotation = [annotation retain];
    PDFPage *page = [wasAnnotation page];
    
    if (editAnnotation == annotation)
        [self endAnnotationEdit:self];
	if (activeAnnotation == annotation)
		[self setActiveAnnotation:nil];
    [self setNeedsDisplayForAnnotation:wasAnnotation];
    [page removeAnnotation:wasAnnotation];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewDidRemoveAnnotationNotification object:self 
        userInfo:[NSDictionary dictionaryWithObjectsAndKeys:wasAnnotation, @"annotation", page, @"page", nil]];
    [wasAnnotation release];
}

- (void)editThisAnnotation:(id)sender {
    PDFAnnotation *annotation = [sender representedObject];
    
    if (annotation == nil || editAnnotation == annotation)
        return;
    
    if (editAnnotation)
        [self endAnnotationEdit:self];
    if (activeAnnotation != annotation)
        [self setActiveAnnotation:annotation];
    [self editActiveAnnotation:sender];
}

- (void)editActiveAnnotation:(id)sender {
    if (nil == activeAnnotation)
        return;
    
    [self endAnnotationEdit:self];
    
    if ([[activeAnnotation type] isEqualToString:@"Note"]) {
        
		[[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewAnnotationDoubleClickedNotification object:self 
            userInfo:[NSDictionary dictionaryWithObjectsAndKeys:activeAnnotation, @"annotation", nil]];
        
    } else if ([[activeAnnotation type] isEqualToString:@"FreeText"] || [[activeAnnotation type] isEqualToString:@"Text"]) {
        
        NSRect editBounds = [activeAnnotation bounds];
        if ([[activeAnnotation type] isEqualToString:@"Text"]) {
            NSRect pageBounds = [[activeAnnotation page] boundsForBox:[self displayBox]];
            editBounds = NSInsetRect(editBounds, -120.0, -120.0);
            if (NSMaxX(editBounds) > NSMaxX(pageBounds))
                editBounds.origin.x = NSMaxX(pageBounds) - NSWidth(editBounds);
            if (NSMinX(editBounds) < NSMinX(pageBounds))
                editBounds.origin.x = NSMinX(pageBounds);
            if (NSMaxY(editBounds) > NSMaxY(pageBounds))
                editBounds.origin.y = NSMaxY(pageBounds) - NSHeight(editBounds);
            if (NSMinY(editBounds) < NSMinY(pageBounds))
                editBounds.origin.y = NSMinY(pageBounds);
        }
        editAnnotation = [[[PDFAnnotationTextWidget alloc] initWithBounds:editBounds] autorelease];
        [editAnnotation setStringValue:[activeAnnotation contents]];
        if ([activeAnnotation respondsToSelector:@selector(font)])
            [editAnnotation setFont:[(PDFAnnotationFreeText *)activeAnnotation font]];
        [editAnnotation setColor:[activeAnnotation color]];
        [[activeAnnotation page] addAnnotation:editAnnotation];
        
        // Start editing
        NSPoint location = [self convertPoint:[self convertPoint:NSMakePoint(NSMidX(editBounds), NSMidY(editBounds)) fromPage:[activeAnnotation page]] toView:nil];
        NSEvent *theEvent = [NSEvent mouseEventWithType:NSLeftMouseDown location:location modifierFlags:0 timestamp:0 windowNumber:[[self window] windowNumber] context:nil eventNumber:0 clickCount:1 pressure:1.0];
        [super mouseDown:theEvent];
        
    }
    
}

- (void)endAnnotationEdit:(id)sender {
    if (editAnnotation) {
        if ([self respondsToSelector:@selector(removeAnnotationControl)])
            [self removeAnnotationControl]; // this removes the textfield from the pdfview, need to do this before we remove the text widget
        if ([[editAnnotation stringValue] isEqualToString:[activeAnnotation contents]] == NO) {
            [activeAnnotation setContents:[editAnnotation stringValue]];
            [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewDidChangeAnnotationNotification object:self 
                userInfo:[NSDictionary dictionaryWithObjectsAndKeys:activeAnnotation, @"annotation", nil]];
        }
        [[editAnnotation page] removeAnnotation:editAnnotation];
        editAnnotation = nil;
    }
}

// this is the action for the textfield for the text widget. Override to remove it after an edit. 
- (void)pdfViewControlHit:(id)sender{
    if ([PDFView instancesRespondToSelector:@selector(pdfViewControlHit:)] && [sender isKindOfClass:[NSTextField class]]) {
        [super pdfViewControlHit:sender];
        [self endAnnotationEdit:self];
    }
}

#pragma mark FullScreen navigation and autohide

- (void)handleWindowWillCloseNotification:(NSNotification *)notification {
    [navWindow orderOut:self];
}

- (void)setHasNavigation:(BOOL)hasNav autohidesCursor:(BOOL)hideCursor {
    hasNavigation = hasNav;
    autohidesCursor = hideCursor;
    
    if (hasNavigation) {
        if (navWindow == nil) {
            navWindow = [[SKNavigationWindow alloc] initWithPDFView:self];
            [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(handleWindowWillCloseNotification:) 
                                                         name: NSWindowWillCloseNotification object: [self window]];
        } else if ([[self window] screen] != [navWindow screen]) {
            [navWindow moveToScreen:[[self window] screen]];
        }
        [navWindow setLevel:[[self window] level]];
    } else if ([navWindow isVisible]) {
        [navWindow orderOut:self];
    }
    [self doAutohide:autohidesCursor || hasNavigation];
}

@end

#pragma mark -

@implementation SKPDFView (Private)

- (NSRect)resizeThumbForRect:(NSRect) rect rotation:(int)rotation
{
	NSRect thumb = rect;
    float size = 8.0;
    
    thumb.size = NSMakeSize(size, size);
	
	// Use rotation to determine thumb origin.
	switch (rotation) {
		case 0:
            thumb.origin.x += NSWidth(rect) - NSWidth(thumb);
            break;
		case 90:
            thumb.origin.x += NSWidth(rect) - NSWidth(thumb);
            thumb.origin.y += NSHeight(rect) - NSHeight(thumb);
            break;
		case 180:
            thumb.origin.y += NSHeight(rect) - NSHeight(thumb);
            break;
	}
	
	return thumb;
}

- (void)transformContextForPage:(PDFPage *)page {
	NSAffineTransform *transform;
	NSRect boxRect;
	
	boxRect = [page boundsForBox:[self displayBox]];
	
	transform = [NSAffineTransform transform];
	[transform translateXBy:-boxRect.origin.x yBy:-boxRect.origin.y];
	[transform concat];
}

#pragma mark Autohide timer

- (void)autohideTimerFired:(NSTimer *)aTimer {
    if (NSPointInRect([NSEvent mouseLocation], [navWindow frame]))
        return;
    if (autohidesCursor)
        [NSCursor setHiddenUntilMouseMoves:YES];
    if (hasNavigation)
        [navWindow hide];
}

- (void)doAutohide:(BOOL)flag {
    if (autohideTimer) {
        [autohideTimer invalidate];
        [autohideTimer release];
        autohideTimer = nil;
    }
    if (flag)
        autohideTimer  = [[NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(autohideTimerFired:) userInfo:nil repeats:NO] retain];
}

#pragma mark Event handling

- (NSCursor *)cursorForMouseMovedEvent:(NSEvent *)event {
    NSCursor *cursor = nil;
    NSPoint p = [[self documentView] convertPoint:[event locationInWindow] fromView:nil];
    if (NSPointInRect(p, [[self documentView] visibleRect])) {
        switch (toolMode) {
            case SKMoveToolMode:
                cursor = [NSCursor openHandCursor];
                break;
            case SKMagnifyToolMode:
                cursor = ([event modifierFlags] & NSShiftKeyMask) ? [NSCursor zoomOutCursor] : [NSCursor zoomInCursor];
                break;
            default:
                cursor = [NSCursor arrowCursor];
        }
    } else {
        // we want this cursor for toolbar and other views, generally
        cursor = [NSCursor arrowCursor];
    }
    return cursor;
}

- (PDFDestination *)destinationForEvent:(NSEvent *)theEvent isLink:(BOOL *)isLink {
    NSPoint windowMouseLoc = [theEvent locationInWindow];
    
    NSPoint viewMouseLoc = [self convertPoint:windowMouseLoc fromView:nil];
    PDFPage *page = [self pageForPoint:viewMouseLoc nearest:YES];
    NSPoint pageSpaceMouseLoc = [self convertPoint:viewMouseLoc toPage:page];  
    PDFDestination *dest = [[[PDFDestination alloc] initWithPage:page atPoint:pageSpaceMouseLoc] autorelease];
    BOOL link = NO;
    
    if (([self areaOfInterestForMouse: theEvent] &  kPDFLinkArea) != 0) {
        link = YES;
        PDFAnnotation *ann = [page annotationAtPoint:pageSpaceMouseLoc];
        if (ann != NULL && [[ann destination] page]){
            dest = [ann destination];
        }
    }
    
    if (isLink) *isLink = link;
    return dest;
}

- (void)selectAnnotationWithEvent:(NSEvent *)theEvent {
    PDFAnnotation *newActiveAnnotation = NULL;
    PDFAnnotation *wasActiveAnnotation;
    NSArray *annotations;
    int numAnnotations, i;
    NSPoint pagePoint;
    BOOL changed;
    
    // Mouse in display view coordinates.
    mouseDownLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    
    // Page we're on.
    activePage = [self pageForPoint:mouseDownLoc nearest:YES];
    
    // Get mouse in "page space".
    pagePoint = [self convertPoint:mouseDownLoc toPage:activePage];
    
    // Hit test for annotation.
    annotations = [activePage annotations];
    numAnnotations = [annotations count];
    
    for (i = 0; i < numAnnotations; i++) {
        NSRect annotationBounds;
        
        // Hit test annotation.
        annotationBounds = [[annotations objectAtIndex:i] bounds];
        if (NSPointInRect(pagePoint, annotationBounds)) {
            PDFAnnotation *annotationHit = [annotations objectAtIndex:i];
            if ([annotationHit isNoteAnnotation]) {
                // We count this one.
                newActiveAnnotation = annotationHit;
                
                // Remember click point relative to annotation origin.
                clickDelta.x = pagePoint.x - annotationBounds.origin.x;
                clickDelta.y = pagePoint.y - annotationBounds.origin.y;
                break;
            }
        }
    }
    
    // Flag indicating if activeAnnotation will change. 
    changed = (activeAnnotation != newActiveAnnotation);
    
    // Deselect old annotation when appropriate.
    if (activeAnnotation && changed)
		[self setNeedsDisplayForAnnotation:activeAnnotation];
    
    if (changed) {
        if (editAnnotation)
            [self endAnnotationEdit:self];
        
        // Assign.
        wasActiveAnnotation = activeAnnotation;
        activeAnnotation = (PDFAnnotationFreeText *)newActiveAnnotation;
        
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:2];
        if (wasActiveAnnotation)
            [userInfo setObject:wasActiveAnnotation forKey:@"wasActiveAnnotation"];
        if (activeAnnotation)
            [userInfo setObject:activeAnnotation forKey:@"activeAnnotation"];
        [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewActiveAnnotationDidChangeNotification object:self userInfo:userInfo];
    }
    
    if (activeAnnotation == nil) {
        [super mouseDown:theEvent];
    } else if ([theEvent clickCount] == 2 && ([[activeAnnotation type] isEqualToString:@"FreeText"] || [[activeAnnotation type] isEqualToString:@"Text"])) {
        // probably we should use the note window for Text annotations
        NSRect editBounds = [activeAnnotation bounds];
        if ([[activeAnnotation type] isEqualToString:@"Text"]) {
            NSRect pageBounds = [[activeAnnotation page] boundsForBox:[self displayBox]];
            editBounds = NSInsetRect(editBounds, -120.0, -120.0);
            if (NSMaxX(editBounds) > NSMaxX(pageBounds))
                editBounds.origin.x = NSMaxX(pageBounds) - NSWidth(editBounds);
            if (NSMinX(editBounds) < NSMinX(pageBounds))
                editBounds.origin.x = NSMinX(pageBounds);
            if (NSMaxY(editBounds) > NSMaxY(pageBounds))
                editBounds.origin.y = NSMaxY(pageBounds) - NSHeight(editBounds);
            if (NSMinY(editBounds) < NSMinY(pageBounds))
                editBounds.origin.y = NSMinY(pageBounds);
        }
        editAnnotation = [[[PDFAnnotationTextWidget alloc] initWithBounds:editBounds] autorelease];
        [editAnnotation setStringValue:[activeAnnotation contents]];
        if ([activeAnnotation respondsToSelector:@selector(font)])
            [editAnnotation setFont:[(PDFAnnotationFreeText *)activeAnnotation font]];
        [editAnnotation setColor:[activeAnnotation color]];
        [[activeAnnotation page] addAnnotation:editAnnotation];
        
        // Start editing
        [super mouseDown:theEvent];
        
    } else if ([theEvent clickCount] == 2 && [[activeAnnotation type] isEqualToString:@"Note"]) {
        
		[[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewAnnotationDoubleClickedNotification object:self 
            userInfo:[NSDictionary dictionaryWithObjectsAndKeys:activeAnnotation, @"annotation", nil]];
        
    } else { 
        // Old (current) annotation location.
        wasBounds = [activeAnnotation bounds];
        
        // Force redisplay.
		[self setNeedsDisplayForAnnotation:activeAnnotation];
        mouseDownInAnnotation = YES;
        
        // Hit-test for resize box.
        resizing = [[activeAnnotation type] isEqualToString:@"Text"] == NO && [[activeAnnotation type] isEqualToString:@"Note"] == NO && NSPointInRect(pagePoint, [self resizeThumbForRect:wasBounds rotation:[activePage rotation]]);
    }
}

- (void)dragAnnotationWithEvent:(NSEvent *)theEvent {
    NSRect newBounds;
    NSRect currentBounds = [activeAnnotation bounds];
    NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    NSPoint endPt = [self convertPoint:mouseLoc toPage:activePage];
    
    if (resizing) {
        NSPoint startPoint = [self convertPoint:mouseDownLoc toPage:activePage];
        NSPoint relPoint = NSMakePoint(endPt.x - startPoint.x, endPt.y - startPoint.y);
        newBounds = wasBounds;
        
        // Resize the annotation.
        switch ([activePage rotation]) {
            case 0:
                newBounds.origin.y += relPoint.y;
                newBounds.size.width += relPoint.x;
                newBounds.size.height -= relPoint.y;
                if (NSWidth(newBounds) < 8.0) {
                    newBounds.size.width = 8.0;
                }
                if (NSHeight(newBounds) < 8.0) {
                    newBounds.origin.y += NSHeight(newBounds) - 8.0;
                    newBounds.size.height = 8.0;
                }
                break;
            case 90:
                newBounds.size.width += relPoint.x;
                newBounds.size.height += relPoint.y;
                if (NSWidth(newBounds) < 8.0) {
                    newBounds.size.width = 8.0;
                }
                if (NSHeight(newBounds) < 8.0) {
                    newBounds.size.height = 8.0;
                }
                break;
            case 180:
                newBounds.origin.x += relPoint.x;
                newBounds.size.width -= relPoint.x;
                newBounds.size.height += relPoint.y;
                if (NSWidth(newBounds) < 8.0) {
                    newBounds.origin.x += NSWidth(newBounds) - 8.0;
                    newBounds.size.width = 8.0;
                }
                if (NSHeight(newBounds) < 8.0) {
                    newBounds.size.height = 8.0;
                }
                break;
            case 270:
                newBounds.origin.x += relPoint.x;
                newBounds.origin.y += relPoint.y;
                newBounds.size.width -= relPoint.x;
                newBounds.size.height -= relPoint.y;
                if (NSWidth(newBounds) < 8.0) {
                    newBounds.origin.x += NSWidth(newBounds) - 8.0;
                    newBounds.size.width = 8.0;
                }
                if (NSHeight(newBounds) < 8.0) {
                    newBounds.origin.y += NSHeight(newBounds) - 8.0;
                    newBounds.size.height = 8.0;
                }
                break;
        }
        
        // Keep integer.
        newBounds = NSIntegralRect(newBounds);
    } else {
        // Move annotation.
        // Hit test, is mouse still within page bounds?
        if (NSPointInRect([self convertPoint:mouseLoc toPage:activePage], [activePage boundsForBox:[self displayBox]])) {
            // Calculate new bounds for annotation.
            newBounds = currentBounds;
            newBounds.origin.x = roundf(endPt.x - clickDelta.x);
            newBounds.origin.y = roundf(endPt.y - clickDelta.y);
        } else {
            // Snap back to initial location.
            newBounds = wasBounds;
        }
    }
    
    // Change annotation's location.
    [activeAnnotation setBounds:newBounds];
    
    // Force redraw.
    [self setNeedsDisplayInRect:NSUnionRect(currentBounds, newBounds) ofPage:activePage];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewDidChangeAnnotationNotification object:self 
        userInfo:[NSDictionary dictionaryWithObjectsAndKeys:activeAnnotation, @"annotation", nil]];
}

- (void)dragWithEvent:(NSEvent *)theEvent {
	NSPoint initialLocation = [theEvent locationInWindow];
	NSRect visibleRect = [[self documentView] visibleRect];
	BOOL keepGoing = YES;
	
	while (keepGoing) {
		theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
		switch ([theEvent type]) {
			case NSLeftMouseDragged:
            {
				NSPoint	newLocation;
				NSRect	newVisibleRect;
				float	xDelta, yDelta;
				
				newLocation = [theEvent locationInWindow];
				xDelta = initialLocation.x - newLocation.x;
				yDelta = initialLocation.y - newLocation.y;
				if ([self isFlipped])
					yDelta = -yDelta;
				
				newVisibleRect = NSOffsetRect (visibleRect, xDelta, yDelta);
				[[self documentView] scrollRectToVisible: newVisibleRect];
			}
				break;
				
			case NSLeftMouseUp:
				keepGoing = NO;
				break;
				
			default:
				/* Ignore any other kind of event. */
				break;
		} // end of switch (event type)
	} // end of mouse-tracking loop
}

- (void)selectSnapshotWithEvent:(NSEvent *)theEvent {
    NSPoint mouseLoc = [theEvent locationInWindow];
	NSPoint startPoint = [[self documentView] convertPoint:mouseLoc fromView:nil];
	NSPoint	currentPoint;
    NSRect selectionRect = {startPoint, NSZeroSize};
    NSRect bounds;
    float minX, maxX, minY, maxY;
	
    [[self window] discardCachedImage];
    
    selecting = YES;
	
	while (selecting) {
		theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSFlagsChangedMask];
        
        [[self window] restoreCachedImage];
        [[self window] flushWindow];
		
        switch ([theEvent type]) {
			case NSLeftMouseDragged:
				[[self documentView] autoscroll:theEvent];
                mouseLoc = [theEvent locationInWindow];
                
			case NSFlagsChanged:
                currentPoint = [[self documentView] convertPoint:mouseLoc fromView:nil];
				
                minX = fmin(startPoint.x, currentPoint.x);
                maxX = fmax(startPoint.x, currentPoint.x);
                minY = fmin(startPoint.y, currentPoint.y);
                maxY = fmax(startPoint.y, currentPoint.y);
                // center around startPoint when holding down the Shift key
                if ([theEvent modifierFlags] & NSShiftKeyMask) {
                    if (currentPoint.x > startPoint.x)
                        minX -= maxX - minX;
                    else
                        maxX += maxX - minX;
                    if (currentPoint.y > startPoint.y)
                        minY -= maxY - minY;
                    else
                        maxY += maxY - minY;
                }
                // intersect with the bounds, project on the bounds if necessary and allow zero width or height
                bounds = [[self documentView] bounds];
                minX = fmin(fmax(minX, NSMinX(bounds)), NSMaxX(bounds));
                maxX = fmax(fmin(maxX, NSMaxX(bounds)), NSMinX(bounds));
                minY = fmin(fmax(minY, NSMinY(bounds)), NSMaxY(bounds));
                maxY = fmax(fmin(maxY, NSMaxY(bounds)), NSMinY(bounds));
                selectionRect = NSMakeRect(minX, minY, maxX - minX, maxY - minY);
                
                [[self window] cacheImageInRect:NSInsetRect([[self documentView] convertRect:selectionRect toView:nil], -2.0, -2.0)];
                
                [self lockFocus];
                [NSGraphicsContext saveGraphicsState];
                [[NSColor blackColor] set];
                [NSBezierPath strokeRect:NSInsetRect(NSIntegralRect([self convertRect:selectionRect fromView:[self documentView]]), 0.5, 0.5)];
                [NSGraphicsContext restoreGraphicsState];
                [self unlockFocus];
                [[self window] flushWindow];
                
				break;
				
			case NSLeftMouseUp:
				selecting = NO;
				break;
				
			default:
				/* Ignore any other kind of event. */
				break;
		} // end of switch (event type)
	} // end of mouse-tracking loop
    
    [[self window] discardCachedImage];
	[self flagsChanged:theEvent];
    
    NSPoint point = [self convertPoint:NSMakePoint(NSMidX(selectionRect), NSMidY(selectionRect)) fromView:[self documentView]];
    PDFPage *page = [self pageForPoint:point nearest:YES];
    NSRect rect = [self convertRect:selectionRect fromView:[self documentView]];
    
    if (NSWidth(rect) < 50.0 || NSHeight(rect) < 50.0) {
        rect.origin.x = [self convertPoint:[page boundsForBox:[self displayBox]].origin fromPage:page].x;
        rect.origin.y = point.y - 100.0;
        rect.size.width = [self rowSizeForPage:page].width;
        rect.size.height = 200.0;
    }
    
    SKMainWindowController *controller = [[self window] windowController];
    
    [controller showSnapshotAtPageNumber:[[self document] indexForPage:page] forRect:[self convertRect:rect toPage:page]];        
}

#define MAG_RECT_1 NSMakeRect(-150.0, -100.0, 300.0, 200.0)
#define MAG_RECT_2 NSMakeRect(-300.0, -200.0, 600.0, 400.0)

- (void)magnifyWithEvent:(NSEvent *)theEvent {
	NSPoint mouseLoc = [theEvent locationInWindow];
    NSScrollView *scrollView = [[self documentView] enclosingScrollView];
    NSView *documentView = [scrollView documentView];
    NSView *clipView = [scrollView contentView];
	NSRect originalBounds = [documentView bounds];
    NSRect visibleRect = [clipView convertRect:[clipView visibleRect] toView: nil];
    NSRect magBounds, magRect, outlineRect;
	float magScale = 1.0;
    BOOL mouseInside = NO;
	int currentLevel = 0;
    int originalLevel = [theEvent clickCount]; // this should be at least 1
	BOOL postNotification = [documentView postsBoundsChangedNotifications];
    NSBezierPath *path;
    
	[documentView setPostsBoundsChangedNotifications: NO];
	
	[[self window] discardCachedImage]; // make sure not to use the cached image
	
	while ([theEvent type] != NSLeftMouseUp) {
        
        // set up the currentLevel and magScale
        if ([theEvent type] == NSLeftMouseDown || [theEvent type] == NSFlagsChanged) {	
            unsigned modifierFlags = [theEvent modifierFlags];
            currentLevel = originalLevel + ((modifierFlags & NSAlternateKeyMask) ? 1 : 0);
            if (currentLevel > 2) {
                [[self window] restoreCachedImage];
                [[self window] cacheImageInRect:visibleRect];
            }
            magScale = (modifierFlags & NSCommandKeyMask) ? 4.0 : (modifierFlags & NSControlKeyMask) ? 1.5 : 2.5;
            if ((modifierFlags & NSShiftKeyMask) == 0)
                magScale = 1.0 / magScale;
            [self flagsChanged:theEvent]; // update the cursor
        }
        
        // get Mouse location and check if it is with the view's rect
        if ([theEvent type] == NSLeftMouseDragged)
            mouseLoc = [theEvent locationInWindow];
        
        if ([self mouse:mouseLoc inRect:visibleRect]) {
            if (mouseInside == NO) {
                mouseInside = YES;
                [NSCursor hide];
            }
            // define rect for magnification in window coordinate
            if (currentLevel > 2) { 
                magRect = visibleRect;
            } else {
                magRect = currentLevel == 2 ? MAG_RECT_2 : MAG_RECT_1;
                magRect.origin.x += mouseLoc.x;
                magRect.origin.y += mouseLoc.y;
                // restore the cached image in order to clear the rect
                [[self window] restoreCachedImage];
                [[self window] cacheImageInRect:NSIntersectionRect(NSInsetRect(magRect, -2.0, -2.0), visibleRect)];
            }
            
            // resize bounds around mouseLoc
            magBounds.origin = [documentView convertPoint:mouseLoc fromView:nil];
            magBounds = NSMakeRect(magBounds.origin.x + magScale * (originalBounds.origin.x - magBounds.origin.x), 
                                   magBounds.origin.y + magScale * (originalBounds.origin.y - magBounds.origin.y), 
                                   magScale * NSWidth(originalBounds), magScale * NSHeight(originalBounds));
            
            [documentView setBounds:magBounds];
            [self displayRect:[self convertRect:NSInsetRect(magRect, 1.0, 1.0) fromView:nil]]; // this flushes the buffer
            [documentView setBounds:originalBounds];
            
            [clipView lockFocus];
            [[NSGraphicsContext currentContext] saveGraphicsState];
            outlineRect = NSInsetRect([clipView convertRect:magRect fromView:nil], 0.5, 0.5);
            path = [NSBezierPath bezierPathWithRect:outlineRect];
            [path setLineWidth:1.0];
            [[NSColor blackColor] set];
            [path stroke];
            [[NSGraphicsContext currentContext] restoreGraphicsState];
            [clipView unlockFocus];
			[[self window] flushWindow];
            
        } else { // mouse is not in the rect
            // show cursor 
            if (mouseInside == YES) {
                mouseInside = NO;
                [NSCursor unhide];
                // restore the cached image in order to clear the rect
                [[self window] restoreCachedImage];
                [[self window] flushWindowIfNeeded];
            }
            if ([theEvent type] == NSLeftMouseDragged)
                [documentView autoscroll:theEvent];
            if (currentLevel > 2)
                [[self window] cacheImageInRect:visibleRect];
            else
                [[self window] discardCachedImage];
        }
        theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSFlagsChangedMask];
	}
	
	[[self window] restoreCachedImage];
	[[self window] flushWindow];
	[NSCursor unhide];
	[documentView setPostsBoundsChangedNotifications:postNotification];
	[self flagsChanged:theEvent]; // update cursor
}

@end
