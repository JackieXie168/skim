//
//  SKPDFView.m
//  Skim
//
//  Created by Michael McCracken on 12/6/06.
/*
 This software is Copyright (c) 2006,2007
 Michael O. McCracken. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Michael O. McCracken nor the names of any
    contributors may be used to endorse or promote products derived
    from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "SKPDFView.h"
#import "SKNavigationWindow.h"
#import "SKPDFHoverWindow.h"
#import "SKMainWindowController.h"
#import "SKPDFAnnotationNote.h"
#import "PDFPage_SKExtensions.h"
#import "NSString_SKExtensions.h"
#import "NSCursor_SKExtensions.h"
#import "SKApplication.h"
#import "SKStringConstants.h"
#import "NSUserDefaultsController_SKExtensions.h"
#import "SKReadingBar.h"
#import "SKDocument.h"
#import "SKPDFSynchronizer.h"
#import "PDFSelection_SKExtensions.h"

NSString *SKPDFViewToolModeChangedNotification = @"SKPDFViewToolModeChangedNotification";
NSString *SKPDFViewAnnotationModeChangedNotification = @"SKPDFViewAnnotationModeChangedNotification";
NSString *SKPDFViewActiveAnnotationDidChangeNotification = @"SKPDFViewActiveAnnotationDidChangeNotification";
NSString *SKPDFViewDidAddAnnotationNotification = @"SKPDFViewDidAddAnnotationNotification";
NSString *SKPDFViewDidRemoveAnnotationNotification = @"SKPDFViewDidRemoveAnnotationNotification";
NSString *SKPDFViewAnnotationDoubleClickedNotification = @"SKPDFViewAnnotationDoubleClickedNotification";

NSString *SKSkimNotePboardType = @"SKSkimNotePboardType";

static CGMutablePathRef SKCGCreatePathWithRoundRectInRect(CGRect rect, float radius);

@interface PDFDocument (SKExtensions)
- (PDFSelection *)selectionByExtendingSelection:(PDFSelection *)selection toPage:(PDFPage *)page atPoint:(NSPoint)point;
@end

@interface PDFView (PDFViewPrivateDeclarations)
- (void)pdfViewControlHit:(id)sender;
- (void)removeAnnotationControl;
@end

#pragma mark -

@interface SKPDFView (Private)

- (NSRange)visiblePageIndexRange;

- (void)resetHoverRects;
- (void)removeHoverRects;

- (NSRect)resizeThumbForRect:(NSRect) rect rotation:(int)rotation;
- (NSRect)resizeThumbForRect:(NSRect) rect point:(NSPoint)point;
- (void)transformCGContext:(CGContextRef)context forPage:(PDFPage *)page;

- (void)autohideTimerFired:(NSTimer *)aTimer;
- (void)doAutohide:(BOOL)flag;

- (PDFDestination *)destinationForEvent:(NSEvent *)theEvent isLink:(BOOL *)isLink;

- (void)moveActiveAnnotationForKey:(unichar)eventChar byAmount:(float)delta;
- (void)resizeActiveAnnotationForKey:(unichar)eventChar byAmount:(float)delta;
- (void)moveReadingBarForKey:(unichar)eventChar;

- (BOOL)selectAnnotationWithEvent:(NSEvent *)theEvent;
- (void)dragAnnotationWithEvent:(NSEvent *)theEvent;
- (void)selectSnapshotWithEvent:(NSEvent *)theEvent;
- (void)magnifyWithEvent:(NSEvent *)theEvent;
- (void)dragWithEvent:(NSEvent *)theEvent;
- (void)dragReadingBarWithEvent:(NSEvent *)theEvent;
- (void)pdfsyncWithEvent:(NSEvent *)theEvent;

@end

#pragma mark -

// Adobe Reader recognizes a path from the hyperref command \url{./test.pdf} as a file: URL, but PDFKit turns it into an http: URL (which of course doesn't work); I notice this because my collaborators use Adobe Reader 	 
@interface PDFAnnotationLink (SKRelativePathFix) 	 
- (void)fixRelativeURLIfNeeded; 	 
@end 	 

@implementation PDFAnnotationLink (SKRelativePathFix) 	 

// class posing indicates that setURL: is never called, and neither is setContents: (-contents returns nil), so this is the only way I can find to fix the thing, since we don't have an equivalent to textView:clickedOnLink:atIndex: 	 
- (void)fixRelativeURLIfNeeded { 	 
    // Adam G. provided a console log with *** -[PDFAnnotationLink URL]: selector not recognized, which really seems weird
    NSURL *theURL = [self respondsToSelector:@selector(URL)] ? [self URL] : nil; 	 
    // http://./path/to/file will never make sense, right? 	 
    if (theURL && [[theURL host] isEqualToString:@"."]) { 	 
        NSString *basePath = [[[[[self page] document] documentURL] path] stringByDeletingLastPathComponent]; 	 
        if (basePath) { 	 
            NSString *realPath = [basePath stringByAppendingPathComponent:[theURL path]]; 	 
            realPath = [realPath stringByStandardizingPath]; 	 
            if (realPath) 	 
                theURL = [NSURL fileURLWithPath:realPath]; 	 
            if (theURL) 	 
                [self setURL:theURL]; 	 
        } 	 
    } 	 
} 	 

@end 	 

#pragma mark -

@implementation SKPDFView

- (void)commonInitialization {
    toolMode = [[NSUserDefaults standardUserDefaults] integerForKey:SKLastToolModeKey];
    
    autohidesCursor = NO;
    hasNavigation = NO;
    autohideTimer = nil;
    navWindow = nil;
    
    readingBar = nil;
    
    activeAnnotation = nil;
    editAnnotation = NO;
    wasBounds = NSZeroRect;
    mouseDownLoc = NSZeroPoint;
    clickDelta = NSZeroPoint;
    resizingAnnotation = NO;
    draggingAnnotation = NO;
    mouseDownInAnnotation = NO;
    
    trackingRect = 0;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAnnotationWillChangeNotification:) 
                                                 name:SKAnnotationWillChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAnnotationDidChangeNotification:) 
                                                 name:SKAnnotationDidChangeNotification object:nil];
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeys:
        [NSArray arrayWithObjects:SKReadingBarColorKey, SKReadingBarTransparencyKey, SKReadingBarInvertKey, nil]];
}

- (id)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        [self commonInitialization];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        [self commonInitialization];
    }
    return self;
}

- (void)dealloc {
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeys:
        [NSArray arrayWithObjects:SKReadingBarColorKey, SKReadingBarTransparencyKey, SKReadingBarInvertKey, nil]];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self doAutohide:NO]; // invalidates and releases the timer
    [[SKPDFHoverWindow sharedHoverWindow] orderOut:self];
    [self removeHoverRects];
    [hoverRects release];
    [navWindow release];
    [readingBar release];
    [super dealloc];
}


- (void)resetCursorRects {
	[super resetCursorRects];
    [self resetHoverRects];
}

#pragma mark Drawing

- (void)drawPage:(PDFPage *)pdfPage {
	// Let PDFView do most of the hard work.
	[super drawPage: pdfPage];
	
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSaveGState(context);
    
    [self transformCGContext:context forPage:pdfPage];
    SKCGContextSetDefaultRGBColorSpace(context);
    
    NSArray *allAnnotations = [pdfPage annotations];
    
    if (allAnnotations) {
        unsigned int i, count = [allAnnotations count];
        BOOL foundActive = NO;
        
        for (i = 0; i < count; i++) {
            PDFAnnotation *annotation = [allAnnotations objectAtIndex: i];
            if ([annotation isNoteAnnotation] || [[annotation type] isEqualToString:@"Link"]) {
                if (annotation == activeAnnotation) {
                    foundActive = YES;
                } else if ([[annotation type] isEqualToString:@"FreeText"]) {
                    NSRect bounds = [annotation bounds];
                    NSRect rect = NSInsetRect(NSIntegralRect(bounds), 0.5, 0.5);
                    float color[4] = { 0.5, 0.5, 0.5, 1.0 };
                    CGContextSetStrokeColor(context, color);
                    CGContextStrokeRectWithWidth(context, *(CGRect *)&rect, 1.0);
                }
                if ([[annotation type] isEqualToString:@"Link"]) 	 
                    [(PDFAnnotationLink *)annotation fixRelativeURLIfNeeded];
            }
        }
        
        // Draw active annotation last so it is not "painted" over.
        if (foundActive) {
            BOOL isLink = [[activeAnnotation type] isEqualToString:@"Link"];
            float lineWidth = isLink ? 2.0 : 1.0;
            NSRect bounds = [activeAnnotation bounds];
            float color[4] = { 0.0, 0.0, 0.0, 1.0 };
            NSRect rect = NSInsetRect(NSIntegralRect(bounds), 0.5 * lineWidth, 0.5 * lineWidth);
            if (isLink) {
                CGMutablePathRef path = SKCGCreatePathWithRoundRectInRect(*(CGRect *)&rect, 2.0);
                color[3] = 0.1;
                CGContextSetFillColor(context, color);
                CGContextBeginPath(context);
                CGContextAddPath(context, path);
                CGContextFillPath(context);
                color[3] = 0.5;
                CGContextSetStrokeColor(context, color);
                CGContextSetLineWidth(context, lineWidth);
                CGContextAddPath(context, path);
                CGContextStrokePath(context);
                CGPathRelease(path);
            } else if ([[activeAnnotation type] isEqualToString:@"Line"]) {
                color[3] = 0.7;
                rect = NSIntegralRect([self resizeThumbForRect:bounds point:[(SKPDFAnnotationLine *)activeAnnotation startPoint]]);
                CGContextSetFillColor(context, color);
                CGContextFillRect(context, *(CGRect *)&rect);
                rect = NSIntegralRect([self resizeThumbForRect:bounds point:[(SKPDFAnnotationLine *)activeAnnotation endPoint]]);
                CGContextSetFillColor(context, color);
                CGContextFillRect(context, *(CGRect *)&rect);
            } else {
                CGContextSetStrokeColor(context, color);
                CGContextStrokeRectWithWidth(context, *(CGRect *)&rect, lineWidth);
                
                if ([activeAnnotation isResizable]) {
                    rect = NSIntegralRect([self resizeThumbForRect:bounds rotation:[pdfPage rotation]]);
                    CGContextSetFillColor(context, color);
                    CGContextFillRect(context, *(CGRect *)&rect);
                }
            }
        }
                
    }
    
    if (readingBar) {
        
        NSRect rect = [readingBar currentBoundsForBox:[self displayBox]];
        BOOL invert = [[NSUserDefaults standardUserDefaults] boolForKey:SKReadingBarInvertKey];
        NSColor *nsColor = [NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] dataForKey:SKReadingBarColorKey]];
        float color[4] = { [nsColor redComponent], [nsColor greenComponent], [nsColor blueComponent], [nsColor alphaComponent] };
        
        CGContextSetFillColor(context, color);
        
        if (invert) {
            NSRect bounds = [pdfPage boundsForBox:[self displayBox]];
            if (NSEqualRects(rect, NSZeroRect) || [[readingBar page] isEqual:pdfPage] == NO) {
                CGContextFillRect(context, *(CGRect *)&bounds);
            } else {
                NSRect outRect, ignored;
                NSDivideRect(bounds, &outRect, &ignored, NSMaxY(bounds) - NSMaxY(rect), NSMaxYEdge);
                CGContextFillRect(context, *(CGRect *)&outRect);
                NSDivideRect(bounds, &outRect, &ignored, NSMinY(rect) - NSMinY(bounds), NSMinYEdge);
                CGContextFillRect(context, *(CGRect *)&outRect);
            }
        } else if ([[readingBar page] isEqual:pdfPage]) {
            CGContextSetBlendMode(context, kCGBlendModeMultiply);        
            CGContextFillRect(context, *(CGRect *)&rect);
        }
    }
    
    CGContextRestoreGState(context);
}

- (void)setNeedsDisplayInRect:(NSRect)rect ofPage:(PDFPage *)page {
    NSRect aRect = [self convertRect:rect fromPage:page];
    float scale = [self scaleFactor];
	NSPoint max = NSMakePoint(ceilf(NSMaxX(aRect)) + scale, ceilf(NSMaxY(aRect)) + scale);
	NSPoint origin = NSMakePoint(floorf(NSMinX(aRect)) - scale, floorf(NSMinY(aRect)) - scale);
	
    [self setNeedsDisplayInRect:NSMakeRect(origin.x, origin.y, max.x - origin.x, max.y - origin.y)];
}

- (void)setNeedsDisplayForAnnotation:(PDFAnnotation *)annotation {
    NSRect bounds = [annotation bounds];
    if ([[annotation type] isEqualToString:@"Underline"]) {
        bounds.origin.y -= 0.03 * NSHeight(bounds);
        bounds.size.height *= 1.03;
    } else if ([[annotation type] isEqualToString:@"Line"] && [annotation isEqual:activeAnnotation]) {
        bounds = NSInsetRect(bounds, -4.0, -4.0);
    }
    [self setNeedsDisplayInRect:bounds ofPage:[annotation page]];
}

#pragma mark Accessors

- (void)setDocument:(PDFDocument *)document {
    [readingBar release];
    readingBar = nil;
    [self removeHoverRects];
    [super setDocument:document];
    [self resetHoverRects];
}

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
        [[NSUserDefaults standardUserDefaults] setInteger:toolMode forKey:SKLastToolModeKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewToolModeChangedNotification object:self];
        // hack to make sure we update the cursor
        [[self window] makeFirstResponder:self];
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
		
		// Force redisplay.
		[self setNeedsDisplayForAnnotation:activeAnnotation];
	} else {
		activeAnnotation = nil;
	}
	
	if (changed)
		[[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewActiveAnnotationDidChangeNotification object:self userInfo:nil];
}

#pragma mark Reading bar

- (BOOL)hasReadingBar {
    return readingBar != nil;
}

- (void)toggleReadingBar {
    if (readingBar) {
        [readingBar release];
        readingBar = nil;
        [self setNeedsDisplay:YES];
    } else {
        readingBar = [[SKReadingBar alloc] init];
        [readingBar setPage:[self currentPage]];
        [readingBar goToNextLine];
        [self setNeedsDisplay:YES];
    }
}

#pragma mark Tracking mousemoved fix

- (void)setFrame:(NSRect)frame {
    [super setFrame:frame];
    if ([self window] && trackingRect)
        [self removeTrackingRect:trackingRect];
    trackingRect = [self addTrackingRect:[self bounds] owner:self userData:NULL assumeInside:NO];
}

- (void)setFrameSize:(NSSize)size {
    [super setFrameSize:size];
    if ([self window] && trackingRect)
        [self removeTrackingRect:trackingRect];
    trackingRect = [self addTrackingRect:[self bounds] owner:self userData:NULL assumeInside:NO];
}
 
- (void)setBounds:(NSRect)bounds {
    [super setBounds:bounds];
    if ([self window] && trackingRect)
        [self removeTrackingRect:trackingRect];
    trackingRect = [self addTrackingRect:[self bounds] owner:self userData:NULL assumeInside:NO];
}
 
- (void)setBoundsSize:(NSSize)size {
    [super setBoundsSize:size];
    if ([self window] && trackingRect)
        [self removeTrackingRect:trackingRect];
    trackingRect = [self addTrackingRect:[self bounds] owner:self userData:NULL assumeInside:NO];
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow {
    if ([self window] && trackingRect)
        [self removeTrackingRect:trackingRect];
}

- (void)viewDidMoveToWindow {
    trackingRect = [self addTrackingRect:[self bounds] owner:self userData:NULL assumeInside:NO];
}

- (void)mouseEntered:(NSEvent *)theEvent {
    NSTrackingRectTag trackingNumber = [theEvent trackingNumber];
    [super mouseEntered:theEvent];
    if (trackingNumber == trackingRect) {
        [[self window] setAcceptsMouseMovedEvents:YES];
    } else if (NSNotFound != [hoverRects indexOfObject:(id)trackingNumber]) {
        [[SKPDFHoverWindow sharedHoverWindow] showForAnnotation:(id)[theEvent userData] atPoint:NSZeroPoint];
        hoverRect = trackingNumber;
    }
}
 
- (void)mouseExited:(NSEvent *)theEvent {
    NSTrackingRectTag trackingNumber = [theEvent trackingNumber];
    [super mouseExited:theEvent];
    if (trackingNumber == trackingRect) {
        [[self window] setAcceptsMouseMovedEvents:NO];
    } else if (NSNotFound != [hoverRects indexOfObject:(id)trackingNumber]) {
        if (hoverRect == trackingNumber) {
            [[SKPDFHoverWindow sharedHoverWindow] hide];
            hoverRect = 0;
        }
    }
}

#pragma mark Actions

- (void)delete:(id)sender
{
	if ([activeAnnotation isNoteAnnotation])
        [self removeActiveAnnotation:self];
    else
        NSBeep();
}

- (void)copy:(id)sender
{
    [super copy:sender];
    
    if ([activeAnnotation isNoteAnnotation] && [activeAnnotation isMovable]) {
        NSPasteboard *pboard = [NSPasteboard generalPasteboard];
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:[activeAnnotation dictionaryValue]];
        [pboard declareTypes:[NSArray arrayWithObjects:SKSkimNotePboardType, nil] owner:nil];
        [pboard setData:data forType:SKSkimNotePboardType];
    }
}

- (void)pasteNoteAlternate:(BOOL)isAlternate {
    NSPasteboard *pboard = [NSPasteboard generalPasteboard];
    NSString *pboardType = [pboard availableTypeFromArray:[NSArray arrayWithObjects:SKSkimNotePboardType, NSStringPboardType, nil]];
    if (pboardType == nil) {
        NSBeep();
        return;
    }
    
    PDFAnnotation *newAnnotation;
    NSRect viewFrame = [self frame];
    PDFPage *page;
    
    if ([pboardType isEqualToString:SKSkimNotePboardType]) {
    
        NSData *data = [pboard dataForType:SKSkimNotePboardType];
        NSDictionary *note = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        NSRect bounds, pageBounds;
        
        newAnnotation = [[[PDFAnnotation alloc] initWithDictionary:note] autorelease];
        bounds = [newAnnotation bounds];
        page = [self currentPage];
        pageBounds = [page boundsForBox:[self displayBox]];
        
        if (NSMaxX(bounds) > NSMaxX(pageBounds))
            bounds.origin.x = NSMaxX(pageBounds) - NSWidth(bounds);
        if (NSMinX(bounds) < NSMinX(pageBounds))
            bounds.origin.x = NSMinX(pageBounds);
        if (NSMaxY(bounds) > NSMaxY(pageBounds))
            bounds.origin.y = NSMaxY(pageBounds) - NSHeight(bounds);
        if (NSMinY(bounds) < NSMinY(pageBounds))
            bounds.origin.y = NSMinY(pageBounds);
        
        [newAnnotation setBounds:bounds];
        
    } else {
        
        NSAssert([pboardType isEqualToString:NSStringPboardType], @"inconsistent pasteboard type");
        
        NSPoint center = NSMakePoint(NSMidX(viewFrame), NSMidY(viewFrame));
        NSSize defaultSize;
        NSRect bounds;
        
        page = [self pageForPoint: center nearest: YES];
        defaultSize = isAlternate ? NSMakeSize(16.0, 16.0) : ([page rotation] % 180 == 90) ? NSMakeSize(64.0, 128.0) : NSMakeSize(128.0, 64.0);
        bounds = NSMakeRect(center.x - 0.5 * defaultSize.width, center.y - 0.5 * defaultSize.height, defaultSize.width, defaultSize.height);
       
        if (isAlternate)
            newAnnotation = [[SKPDFAnnotationNote alloc] initWithBounds:bounds];
        else
            newAnnotation = [[SKPDFAnnotationFreeText alloc] initWithBounds:bounds];
        [newAnnotation setContents:[pboard stringForType:NSStringPboardType]];
    }
    
    [page addAnnotation:newAnnotation];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewDidAddAnnotationNotification object:self 
        userInfo:[NSDictionary dictionaryWithObjectsAndKeys:newAnnotation, @"annotation", page, @"page", nil]];

    [self setActiveAnnotation:newAnnotation];
}

- (void)paste:(id)sender {
    [self pasteNoteAlternate:NO];
}

- (void)alternatePaste:(id)sender {
    [self pasteNoteAlternate:YES];
}

- (void)cut:(id)sender
{
	if ([activeAnnotation isNoteAnnotation]) {
        [self copy:sender];
        [self delete:sender];
    } else
        NSBeep();
}

- (void)changeToolMode:(id)sender {
    [self setToolMode:[sender tag]];
}

#pragma mark Event Handling

- (void)keyDown:(NSEvent *)theEvent
{
    NSString *characters = [theEvent charactersIgnoringModifiers];
    unichar eventChar = [characters length] > 0 ? [characters characterAtIndex:0] : 0;
	unsigned int modifiers = [theEvent modifierFlags] & (NSCommandKeyMask | NSAlternateKeyMask | NSShiftKeyMask | NSControlKeyMask);
    BOOL isPresentation = hasNavigation && autohidesCursor;
    
	if (isPresentation && (eventChar == NSRightArrowFunctionKey) && (modifiers == 0)) {
        [self goToNextPage:self];
    } else if (isPresentation && (eventChar == NSLeftArrowFunctionKey) && (modifiers == 0)) {
		[self goToPreviousPage:self];
	} else if ((eventChar == NSDeleteCharacter || eventChar == NSDeleteFunctionKey) && (modifiers == 0)) {
		[self delete:self];
    } else if (isPresentation == NO && [self toolMode] == SKTextToolMode && (eventChar == NSEnterCharacter || eventChar == NSFormFeedCharacter || eventChar == NSNewlineCharacter || eventChar == NSCarriageReturnCharacter) && (modifiers == 0)) {
        if (activeAnnotation && activeAnnotation != editAnnotation)
            [self editActiveAnnotation:self];
    } else if (isPresentation == NO && [self toolMode] == SKTextToolMode && (eventChar == NSTabCharacter) && (modifiers == NSAlternateKeyMask)) {
        [self selectNextActiveAnnotation:self];
    // backtab is a bit inconsistent, it seems Shift+Tab gives a Shift-BackTab key event, I would have expected either Shift-Tab (as for the raw event) or BackTab (as for most shift-modified keys)
    } else if (isPresentation == NO && [self toolMode] == SKTextToolMode && (((eventChar == NSBackTabCharacter) && (modifiers == NSAlternateKeyMask | NSShiftKeyMask)) || ((eventChar == NSBackTabCharacter) && (modifiers == NSAlternateKeyMask)) || ((eventChar == NSTabCharacter) && (modifiers == NSAlternateKeyMask)))) {
        [self selectPreviousActiveAnnotation:self];
	} else if (isPresentation == NO && [activeAnnotation isNoteAnnotation] && [activeAnnotation isMovable] && (eventChar == NSRightArrowFunctionKey || eventChar == NSLeftArrowFunctionKey || eventChar == NSUpArrowFunctionKey || eventChar == NSDownArrowFunctionKey) && (modifiers == 0 || modifiers == NSShiftKeyMask)) {
        [self moveActiveAnnotationForKey:eventChar byAmount:(modifiers & NSShiftKeyMask) ? 10.0 : 1.0];
	} else if (isPresentation == NO && [activeAnnotation isNoteAnnotation] && [activeAnnotation isResizable] && (eventChar == NSRightArrowFunctionKey || eventChar == NSLeftArrowFunctionKey || eventChar == NSUpArrowFunctionKey || eventChar == NSDownArrowFunctionKey) && (modifiers == NSControlKeyMask || modifiers == NSControlKeyMask | NSShiftKeyMask)) {
        [self resizeActiveAnnotationForKey:eventChar byAmount:(modifiers & NSShiftKeyMask) ? 10.0 : 1.0];
    } else if (readingBar && (eventChar == NSRightArrowFunctionKey || eventChar == NSLeftArrowFunctionKey || eventChar == NSUpArrowFunctionKey || eventChar == NSDownArrowFunctionKey) && (modifiers == NSAlternateKeyMask)) {
        [self moveReadingBarForKey:eventChar];
    } else {
		[super keyDown:theEvent];
    }
}

- (void)mouseDown:(NSEvent *)theEvent{
    if ([[activeAnnotation type] isEqualToString:@"Link"])
        [self setActiveAnnotation:nil];
    
    mouseDownLoc = [theEvent locationInWindow];
	unsigned int modifiers = [theEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask;

    if (modifiers & NSCommandKeyMask) {
        if (modifiers & NSShiftKeyMask)
            [self pdfsyncWithEvent:theEvent];
        else
            [self selectSnapshotWithEvent:theEvent];
    } else {
        switch (toolMode) {
            case SKTextToolMode:
            {
                NSPoint p = mouseDownLoc;
                p = [self convertPoint:p fromView:nil];
                PDFPage *page = [self pageForPoint:p nearest:NO];
                p = [self convertPoint:p toPage:page];
                if (readingBar && [[readingBar page] isEqual:page] && NSPointInRect(p, [readingBar currentBoundsForBox:[self displayBox]])) {
                    [self dragReadingBarWithEvent:theEvent];
                } else if ([[self document] isLocked] || [self selectAnnotationWithEvent:theEvent] == NO) {
                    PDFAreaOfInterest area = [self areaOfInterestForMouse:theEvent];
                    if (area == kPDFNoArea || (area == kPDFPageArea && [[page selectionForRect:NSMakeRect(p.x - 30.0, p.y - 40.0, 60.0, 80.0)] string] == nil)) {
                        [self dragWithEvent:theEvent];
                    } else {
                        if (nil == activeAnnotation && mouseDownInAnnotation) {
                            if (modifiers & NSAlternateKeyMask) {
                                rectSelection = YES;
                                extendSelection = NO;
                                [self setCurrentSelection:NO];
                            } else if (modifiers & NSShiftKeyMask) {
                                rectSelection = NO;
                                extendSelection = YES;
                                wasSelection = [[self currentSelection] retain];
                                if (page == nil) {
                                    p = [self convertPoint:mouseDownLoc fromView:nil];
                                    page = [self pageForPoint:p nearest:YES];
                                    p = [self convertPoint:p toPage:page];
                                }
                                [self setCurrentSelection:[[self document] selectionByExtendingSelection:wasSelection toPage:page atPoint:p]];
                            } else {
                                rectSelection = NO;
                                extendSelection = NO;
                                [self setCurrentSelection:NO];
                            }
                        }
                        [super mouseDown:theEvent];
                    }
                }
                break;
            }
            case SKMoveToolMode:
                [self dragWithEvent:theEvent];	
                break;
            case SKMagnifyToolMode:
                if ([self areaOfInterestForMouse:theEvent] == kPDFNoArea)
                    [self dragWithEvent:theEvent];
                else
                    [self magnifyWithEvent:theEvent];
                break;
        }
    }
}

- (void)mouseUp:(NSEvent *)theEvent{
    switch (toolMode) {
        case SKTextToolMode:
            mouseDownInAnnotation = NO;
            [wasSelection release];
            wasSelection = nil;
            if (draggingAnnotation) {
                draggingAnnotation = NO;
                if ([[activeAnnotation type] isEqualToString:@"Square"] || [[activeAnnotation type] isEqualToString:@"Square"]) {
                    NSString *selString = [[[[activeAnnotation page] selectionForRect:[activeAnnotation bounds]] string] stringByCollapsingWhitespaceAndNewlinesAndRemovingSurroundingWhitespaceAndNewlines];
                    [activeAnnotation setContents:selString];
                }
            } else
                [super mouseUp:theEvent];
            break;
        case SKMoveToolMode:
            // shouldn't reach this
            break;
        case SKMagnifyToolMode:
            [super mouseUp:theEvent];
            break;
    }
}

static inline NSRect rectWithCorners(NSPoint p1, NSPoint p2)
{
    NSRect rect;
    rect.size.width = ABS(p2.x - p1.x);
    rect.size.height = ABS(p2.y - p1.y);
    rect.origin.x = MIN(p2.x, p1.x);
    rect.origin.y = MIN(p2.y, p1.y);
    return rect;
}

- (void)mouseDragged:(NSEvent *)theEvent {
    switch (toolMode) {
        case SKTextToolMode:
            if (draggingAnnotation) {
                [self dragAnnotationWithEvent:theEvent];
            } else if (nil == activeAnnotation) {
                if (mouseDownInAnnotation) {
                    // reimplement text selection behavior so we can select text inside markup annotation bounds rectangles (and have a highlight and strikeout on the same line, for instance), but don't select inside an existing markup annotation

                    // if we autoscroll, the mouseDownLoc is no longer correct as a starting point
                    NSPoint mouseDownLocInDoc = [[self documentView] convertPoint:mouseDownLoc fromView:nil];
                    if ([[self documentView] autoscroll:theEvent])
                        mouseDownLoc = [[self documentView] convertPoint:mouseDownLocInDoc toView:nil];

                    NSPoint p1 = [self convertPoint:mouseDownLoc fromView:nil];
                    PDFPage *page1 = [self pageForPoint:p1 nearest:YES];
                    p1 = [self convertPoint:p1 toPage:page1];

                    NSPoint p2 = [self convertPoint:[theEvent locationInWindow] fromView:nil];
                    PDFPage *page2 = [self pageForPoint:p2 nearest:YES];
                    p2 = [self convertPoint:p2 toPage:page2];
                    
                    PDFSelection *sel = nil;
                    if (rectSelection) {
                        // how to handle multipage selection?  Preview.app's behavior is screwy as well, so we'll do the same thing
                        sel = [page1 selectionForRect:rectWithCorners(p1, p2)];
                    } else if (extendSelection) {
                        sel = [[self document] selectionByExtendingSelection:wasSelection toPage:page2 atPoint:p2];
                    } else {
                        sel = [[self document] selectionFromPage:page1 atPoint:p1 toPage:page2 atPoint:p2];
                    }

                    [self setCurrentSelection:sel];
                } else {
                    [super mouseDragged:theEvent];
                }
            }
            break;
        case SKMoveToolMode:
            // shouldn't reach this
            break;
        case SKMagnifyToolMode:
            [super mouseDragged:theEvent];
            break;
    }
}

- (void)mouseMoved:(NSEvent *)theEvent {

    // we receive this message whenever we are first responder, so check the location
    NSView *clipView = [[[self documentView] enclosingScrollView] contentView];
    NSPoint p = [clipView convertPoint:[theEvent locationInWindow] fromView:nil];
    NSCursor *cursor = nil;
    
    if (NSPointInRect(p, [clipView visibleRect]) == NO || ([navWindow isVisible] && NSPointInRect([NSEvent mouseLocation], [navWindow frame]))) {
        cursor = [NSCursor arrowCursor];
    } else if ([theEvent modifierFlags] & NSCommandKeyMask) {
        if ([theEvent modifierFlags] & NSShiftKeyMask)
            cursor = [NSCursor arrowCursor];
        else
            cursor = [NSCursor cameraCursor];
    } else {
        switch (toolMode) {
            case SKTextToolMode:
            {
                p = [self convertPoint:[theEvent locationInWindow] fromView:nil];
                PDFPage *page = [self pageForPoint:p nearest:NO];
                p = [self convertPoint:p toPage:page];
                PDFAreaOfInterest area = [self areaOfInterestForMouse:theEvent];
                if ((readingBar && [[readingBar page] isEqual:page] && NSPointInRect(p, [readingBar currentBoundsForBox:[self displayBox]])) ||
                    (area == kPDFNoArea || (area == kPDFPageArea && [[page selectionForRect:NSMakeRect(p.x - 30.0, p.y - 40.0, 60.0, 80.0)] string] == nil)))
                    cursor = [NSCursor openHandCursor];
                else
                    [super mouseMoved:theEvent];
                break;
            }
            case SKMoveToolMode:
                cursor = [NSCursor openHandCursor];
                break;
            case SKMagnifyToolMode:
                if ([self areaOfInterestForMouse:theEvent] == kPDFNoArea)
                    cursor = [NSCursor openHandCursor];
                else
                    cursor = ([theEvent modifierFlags] & NSShiftKeyMask) ? [NSCursor zoomOutCursor] : [NSCursor zoomInCursor];
                break;
        }
    }
    [cursor set];
    
    p = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    PDFPage *page = [self pageForPoint:p nearest:NO];
    PDFAnnotation *annotation = nil;
    
    if (page) 
        annotation = [page annotationAtPoint:[self convertPoint:p toPage:page]];  
    
    if ([[activeAnnotation type] isEqualToString:@"Link"]) {
        [[SKPDFHoverWindow sharedHoverWindow] hide];
        [self setActiveAnnotation:nil];
    }
    
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
    
    NSCursor *cursor = nil;
    
    if ([theEvent modifierFlags] & NSCommandKeyMask) {
        if ([theEvent modifierFlags] & NSShiftKeyMask)
            cursor = [NSCursor arrowCursor];
        else
            cursor = [NSCursor cameraCursor];
    } else {
        switch (toolMode) {
            case SKTextToolMode:
                cursor = [NSCursor arrowCursor];
                break;
            case SKMoveToolMode:
                cursor = [NSCursor openHandCursor];
                break;
            case SKMagnifyToolMode:
                cursor = ([theEvent modifierFlags] & NSShiftKeyMask) ? [NSCursor zoomOutCursor] : [NSCursor zoomInCursor];
                break;
        }
    }
    
    [cursor set];
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
    [item setTarget:self];

    item = [submenu addItemWithTitle:NSLocalizedString(@"Scroll", @"Menu item title") action:@selector(changeToolMode:) keyEquivalent:@""];
    [item setTag:SKMoveToolMode];
    [item setTarget:self];

    item = [submenu addItemWithTitle:NSLocalizedString(@"Magnify", @"Menu item title") action:@selector(changeToolMode:) keyEquivalent:@""];
    [item setTag:SKMagnifyToolMode];
    [item setTarget:self];
    
    item = [menu addItemWithTitle:NSLocalizedString(@"Tools", @"Menu item title") action:NULL keyEquivalent:@""];
    [item setSubmenu:submenu];
    [submenu release];
    
    NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    
    [menu addItem:[NSMenuItem separatorItem]];
    
    item = [menu addItemWithTitle:NSLocalizedString(@"Take Snapshot", @"Menu item title") action:@selector(takeSnapshot:) keyEquivalent:@""];
    [item setRepresentedObject:[NSValue valueWithPoint:point]];
    [item setTarget:self];
    
    if ([self toolMode] == SKTextToolMode) {
        
        [menu addItem:[NSMenuItem separatorItem]];
        
        submenu = [[NSMenu allocWithZone:[menu zone]] init];
        
        item = [submenu addItemWithTitle:NSLocalizedString(@"Text Note", @"Menu item title") action:@selector(addAnnotationFromMenu:) keyEquivalent:@""];
        [item setRepresentedObject:[NSValue valueWithPoint:point]];
        [item setTag:SKFreeTextNote];
        [item setTarget:self];
        
        item = [submenu addItemWithTitle:NSLocalizedString(@"Anchored Note", @"Menu item title") action:@selector(addAnnotationFromMenu:) keyEquivalent:@""];
        [item setRepresentedObject:[NSValue valueWithPoint:point]];
        [item setTag:SKAnchoredNote];
        [item setTarget:self];
        
        item = [submenu addItemWithTitle:NSLocalizedString(@"Circle", @"Menu item title") action:@selector(addAnnotationFromMenu:) keyEquivalent:@""];
        [item setRepresentedObject:[NSValue valueWithPoint:point]];
        [item setTag:SKCircleNote];
        [item setTarget:self];
        
        item = [submenu addItemWithTitle:NSLocalizedString(@"Box", @"Menu item title") action:@selector(addAnnotationFromMenu:) keyEquivalent:@""];
        [item setRepresentedObject:[NSValue valueWithPoint:point]];
        [item setTag:SKSquareNote];
        [item setTarget:self];
        
        if ([self currentSelection]) {
            item = [submenu addItemWithTitle:NSLocalizedString(@"Highlight", @"Menu item title") action:@selector(addAnnotationFromMenu:) keyEquivalent:@""];
            [item setRepresentedObject:[NSValue valueWithPoint:point]];
            [item setTag:SKHighlightNote];
            [item setTarget:self];
            
            item = [submenu addItemWithTitle:NSLocalizedString(@"Underline", @"Menu item title") action:@selector(addAnnotationFromMenu:) keyEquivalent:@""];
            [item setRepresentedObject:[NSValue valueWithPoint:point]];
            [item setTag:SKUnderlineNote];
            [item setTarget:self];
            
            item = [submenu addItemWithTitle:NSLocalizedString(@"Strike Out", @"Menu item title") action:@selector(addAnnotationFromMenu:) keyEquivalent:@""];
            [item setRepresentedObject:[NSValue valueWithPoint:point]];
            [item setTag:SKStrikeOutNote];
            [item setTarget:self];
        }
        
        item = [submenu addItemWithTitle:NSLocalizedString(@"Arrow", @"Menu item title") action:@selector(addAnnotationFromMenu:) keyEquivalent:@""];
        [item setRepresentedObject:[NSValue valueWithPoint:point]];
        [item setTag:SKArrowNote];
        [item setTarget:self];
        
        item = [menu addItemWithTitle:NSLocalizedString(@"New Note", @"Menu item title") action:NULL keyEquivalent:@""];
        [item setSubmenu:submenu];
        [submenu release];
        
        [menu addItem:[NSMenuItem separatorItem]];
        
        if ([self currentSelection] || ([activeAnnotation isNoteAnnotation] && [activeAnnotation isMovable])) {
            item = [menu addItemWithTitle:NSLocalizedString(@"Copy", @"Menu item title") action:@selector(copy:) keyEquivalent:@""];
            if ([activeAnnotation isNoteAnnotation] && [activeAnnotation isMovable])
                item = [menu addItemWithTitle:NSLocalizedString(@"Cut", @"Menu item title") action:@selector(copy:) keyEquivalent:@""];
        }
        
        if ([[NSPasteboard generalPasteboard] availableTypeFromArray:[NSArray arrayWithObjects:SKSkimNotePboardType, NSStringPboardType, nil]]) {
            SEL selector = ([theEvent modifierFlags] & NSAlternateKeyMask) ? @selector(alternatePaste:) : @selector(paste:);
            item = [menu addItemWithTitle:NSLocalizedString(@"Paste", @"Menu item title") action:selector keyEquivalent:@""];
        }
        
        PDFPage *page = [self pageForPoint:point nearest:YES];
        PDFAnnotation *annotation = nil;
        
        if (page) {
            annotation = [page annotationAtPoint:[self convertPoint:point toPage:page]];
            if ([annotation isNoteAnnotation] == NO)
                annotation = nil;
        }
        
        if (annotation) {
            item = [menu addItemWithTitle:NSLocalizedString(@"Remove Note", @"Menu item title") action:@selector(removeThisAnnotation:) keyEquivalent:@""];
            [item setRepresentedObject:annotation];
            [item setTarget:self];
            
            if ((annotation != activeAnnotation || editAnnotation == nil) && [annotation isEditable]) {
                item = [menu addItemWithTitle:NSLocalizedString(@"Edit Note", @"Menu item title") action:@selector(editThisAnnotation:) keyEquivalent:@""];
                [item setRepresentedObject:annotation];
                [item setTarget:self];
            }
        } else if ([activeAnnotation isNoteAnnotation]) {
            item = [menu addItemWithTitle:NSLocalizedString(@"Remove Current Note", @"Menu item title") action:@selector(removeActiveAnnotation:) keyEquivalent:@""];
            [item setTarget:self];
            
            if (editAnnotation == nil && [activeAnnotation isEditable]) {
                item = [menu addItemWithTitle:NSLocalizedString(@"Edit Current Note", @"Menu item title") action:@selector(editActiveAnnotation:) keyEquivalent:@""];
                [item setTarget:self];
            }
        }
        
    }
    
    return menu;
}

- (void)magnifyWheel:(NSEvent *)theEvent {
    float dy = [theEvent deltaY];
    dy = dy > 0 ? MIN(0.2, dy) : MAX(-0.2, dy);
    [self setScaleFactor:[self scaleFactor] + 0.5 * dy];
}

#pragma mark Annotation management

- (void)addAnnotationFromMenu:(id)sender {
    PDFSelection *selection = [self currentSelection];
    NSString *text = [[selection string] stringByCollapsingWhitespaceAndNewlinesAndRemovingSurroundingWhitespaceAndNewlines];
    SKNoteType annotationType = [sender tag];
    NSPoint point = [[sender representedObject] pointValue];
	PDFPage *page = [self pageForPoint:point nearest:YES];
    NSRect bounds;

    if (selection && page) {
        bounds = [selection boundsForPage:page];
    } else {
        NSSize defaultSize = (annotationType == SKAnchoredNote) ? NSMakeSize(16.0, 16.0) : ([page rotation] % 180 == 90) ? NSMakeSize(64.0, 128.0) : NSMakeSize(128.0, 64.0);
        
        point = [self convertPoint:point toPage:page];
        bounds = NSMakeRect(point.x - 0.5 * defaultSize.width, point.y - 0.5 * defaultSize.height, defaultSize.width, defaultSize.height);
    }
    
    // Make sure it fits in the page
    NSRect pageBounds = [page boundsForBox:[self displayBox]];
    if (NSMaxX(bounds) > NSMaxX(pageBounds))
        bounds.origin.x = NSMaxX(pageBounds) - NSWidth(bounds);
    if (NSMinX(bounds) < NSMinX(pageBounds))
        bounds.origin.x = NSMinX(pageBounds);
    if (NSMaxY(bounds) > NSMaxY(pageBounds))
        bounds.origin.y = NSMaxY(pageBounds) - NSHeight(bounds);
    if (NSMinY(bounds) < NSMinY(pageBounds))
        bounds.origin.y = NSMinY(pageBounds);
    
    [self addAnnotationWithType:annotationType contents:text page:page bounds:bounds];
}

- (void)addAnnotationFromSelectionWithType:(SKNoteType)annotationType {
	PDFPage *page;
	NSRect bounds;
    PDFSelection *selection = [self currentSelection];
    NSString *text = nil;
	
    if (selection != nil) {
        PDFSelection *selection = [self currentSelection];
        
        text = [[selection string] stringByCollapsingWhitespaceAndNewlinesAndRemovingSurroundingWhitespaceAndNewlines];
        
		// Get bounds (page space) for selection (first page in case selection spans multiple pages).
		page = [[selection pages] objectAtIndex: 0];
		bounds = [selection boundsForPage: page];
	} else if (annotationType == SKHighlightNote || annotationType == SKUnderlineNote || annotationType == SKStrikeOutNote) {
        NSBeep();
        return;
    } else {
        NSSize defaultSize = (annotationType == SKAnchoredNote) ? NSMakeSize(16.0, 16.0) : NSMakeSize(128.0, 64.0);
		// First try the current mouse position
        NSPoint center = [self convertPoint:[[self window] mouseLocationOutsideOfEventStream] fromView:nil];
        
        // if the mouse was in the toolbar and there is a page below the toolbar, we get a point outside of the visible rect
        page = NSPointInRect(center, [[self documentView] convertRect:[[self documentView] visibleRect] toView:self]) ? [self pageForPoint:center nearest:NO] : nil;
        
        if (page == nil) {
            // Get center of the PDFView.
            NSRect viewFrame = [self frame];
            center = NSMakePoint(NSMidX(viewFrame), NSMidY(viewFrame));
            page = [self pageForPoint: center nearest: YES];
        }
		
		// Convert to "page space".
		center = [self convertPoint: center toPage: page];
        if ([page rotation] % 180 == 90)
            defaultSize = NSMakeSize(defaultSize.height, defaultSize.width);
        bounds = NSMakeRect(center.x - 0.5 * defaultSize.width, center.y - 0.5 * defaultSize.height, defaultSize.width, defaultSize.height);
        
        // Make sure it fits in the page
        NSRect pageBounds = [page boundsForBox:[self displayBox]];
        if (NSMaxX(bounds) > NSMaxX(pageBounds))
            bounds.origin.x = NSMaxX(pageBounds) - NSWidth(bounds);
        if (NSMinX(bounds) < NSMinX(pageBounds))
            bounds.origin.x = NSMinX(pageBounds);
        if (NSMaxY(bounds) > NSMaxY(pageBounds))
            bounds.origin.y = NSMaxY(pageBounds) - NSHeight(bounds);
        if (NSMinY(bounds) < NSMinY(pageBounds))
            bounds.origin.y = NSMinY(pageBounds);
	}
    [self addAnnotationWithType:annotationType contents:text page:page bounds:bounds];
}

- (void)addAnnotationWithType:(SKNoteType)annotationType contents:(NSString *)text page:(PDFPage *)page bounds:(NSRect)bounds {
	PDFAnnotation *newAnnotation = nil;
	// Create annotation and add to page.
    switch (annotationType) {
        case SKFreeTextNote:
            newAnnotation = [[SKPDFAnnotationFreeText alloc] initWithBounds:bounds];
            if (text == nil)
                text = NSLocalizedString(@"Double-click to edit.", @"Default text for new text note");
            break;
        case SKAnchoredNote:
            newAnnotation = [[SKPDFAnnotationNote alloc] initWithBounds:bounds];
            if (text == nil)
                text = NSLocalizedString(@"New note", @"Default text for new anchored note");
            break;
        case SKCircleNote:
            newAnnotation = [[SKPDFAnnotationCircle alloc] initWithBounds:NSInsetRect(bounds, -5.0, -5.0)];
            break;
        case SKSquareNote:
            newAnnotation = [[SKPDFAnnotationSquare alloc] initWithBounds:NSInsetRect(bounds, -5.0, -5.0)];
            break;
        case SKHighlightNote:
            newAnnotation = [[SKPDFAnnotationMarkup alloc] initWithSelection:[self currentSelection] markupType:kPDFMarkupTypeHighlight];
            break;
        case SKUnderlineNote:
            newAnnotation = [[SKPDFAnnotationMarkup alloc] initWithSelection:[self currentSelection] markupType:kPDFMarkupTypeUnderline];
            break;
        case SKStrikeOutNote:
            newAnnotation = [[SKPDFAnnotationMarkup alloc] initWithSelection:[self currentSelection] markupType:kPDFMarkupTypeStrikeOut];
            break;
        case SKArrowNote:
            newAnnotation = [[SKPDFAnnotationLine alloc] initWithBounds:bounds];
            break;
	}
    if (text == nil)
        text = [[[page selectionForRect:bounds] string] stringByCollapsingWhitespaceAndNewlinesAndRemovingSurroundingWhitespaceAndNewlines];
    
    if ([[activeAnnotation type] isEqualToString:@"Line"] == NO)
        [newAnnotation setContents:text];
    
    [page addAnnotation:newAnnotation];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewDidAddAnnotationNotification object:self 
        userInfo:[NSDictionary dictionaryWithObjectsAndKeys:newAnnotation, @"annotation", page, @"page", nil]];

    [self setActiveAnnotation:newAnnotation];
    [newAnnotation release];
    if (annotationType == SKAnchoredNote)
		[[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewAnnotationDoubleClickedNotification object:self 
            userInfo:[NSDictionary dictionaryWithObjectsAndKeys:activeAnnotation, @"annotation", nil]];
}

- (void)removeActiveAnnotation:(id)sender{
    if ([activeAnnotation isNoteAnnotation])
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
    
    if (editAnnotation && activeAnnotation == annotation)
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
    
    NSString *type = [activeAnnotation type];
    
    if ([type isEqualToString:@"Link"]) {
        
        [[SKPDFHoverWindow sharedHoverWindow] orderOut:self];
        [self goToDestination:[activeAnnotation destination]];
        
    } else if ([type isEqualToString:@"Note"]) {
        
        [[SKPDFHoverWindow sharedHoverWindow] orderOut:self];
        
		[[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewAnnotationDoubleClickedNotification object:self 
            userInfo:[NSDictionary dictionaryWithObjectsAndKeys:activeAnnotation, @"annotation", nil]];
        
    } else if ([type isEqualToString:@"FreeText"]) {
        
        NSRect editBounds = [activeAnnotation bounds];
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
        }
        [[editAnnotation page] removeAnnotation:editAnnotation];
        editAnnotation = nil;
    }
}

// this is the action for the textfield for the text widget. Override to remove it after an edit. 
- (void)pdfViewControlHit:(id)sender{
    if ([PDFView instancesRespondToSelector:@selector(pdfViewControlHit:)]) {
        [super pdfViewControlHit:sender];
        if ([sender isKindOfClass:[NSTextField class]] && editAnnotation) {
            [self endAnnotationEdit:self];
            [[self window] makeFirstResponder:self];
        }
    }
}

- (void)selectNextActiveAnnotation:(id)sender {
    PDFDocument *pdfDoc = [self document];
    int numberOfPages = [pdfDoc pageCount];
    int i = -1;
    int pageIndex, startPageIndex = -1;
    PDFAnnotation *annotation = nil;
    
    if (activeAnnotation) {
        if (editAnnotation)
            [self endAnnotationEdit:self];
        pageIndex = [pdfDoc indexForPage:[activeAnnotation page]];
        i = [[[activeAnnotation page] annotations] indexOfObject:activeAnnotation];
    } else {
        pageIndex = [pdfDoc indexForPage:[self currentPage]];
    }
    while (annotation == nil) {
        NSArray *annotations = [[pdfDoc pageAtIndex:pageIndex] annotations];
        while (++i < (int)[annotations count] && annotation == nil) {
            annotation = [annotations objectAtIndex:i];
            if ([annotation isNoteAnnotation] == NO && [[annotation type] isEqualToString:@"Link"] == NO)
                annotation = nil;
        }
        if (startPageIndex == -1)
            startPageIndex = pageIndex;
        else if (pageIndex == startPageIndex)
            break;
        if (++pageIndex == numberOfPages)
            pageIndex = 0;
        i = -1;
    }
    if (annotation) {
        [self scrollAnnotationToVisible:annotation];
        [self setActiveAnnotation:annotation];
        if ([[annotation type] isEqualToString:@"Link"] || [annotation text]) {
            NSRect bounds = [annotation bounds]; 
            NSPoint point = [self convertPoint:[self convertPoint:NSMakePoint(NSMidX(bounds), NSMidY(bounds)) fromPage:[annotation page]] toView:nil]; 
            [[SKPDFHoverWindow sharedHoverWindow] showForAnnotation:annotation atPoint:[[self window] convertBaseToScreen:point]];
        } else {
            [[SKPDFHoverWindow sharedHoverWindow] orderOut:self];
        }
    }
}

- (void)selectPreviousActiveAnnotation:(id)sender {
    PDFDocument *pdfDoc = [self document];
    int numberOfPages = [pdfDoc pageCount];
    int i = numberOfPages;
    int pageIndex, startPageIndex = -1;
    PDFAnnotation *annotation = nil;
    
    if (activeAnnotation) {
        if (editAnnotation)
            [self endAnnotationEdit:self];
        pageIndex = [pdfDoc indexForPage:[activeAnnotation page]];
        i = [[[activeAnnotation page] annotations] indexOfObject:activeAnnotation];
    } else {
        pageIndex = [pdfDoc indexForPage:[self currentPage]];
    }
    while (annotation == nil) {
        NSArray *annotations = [[pdfDoc pageAtIndex:pageIndex] annotations];
        while (--i >= 0 && annotation == nil) {
            annotation = [annotations objectAtIndex:i];
            if ([annotation isNoteAnnotation] == NO && [[annotation type] isEqualToString:@"Link"] == NO)
                annotation = nil;
        }
        if (startPageIndex == -1)
            startPageIndex = pageIndex;
        else if (pageIndex == startPageIndex)
            break;
        if (++pageIndex == numberOfPages)
            pageIndex = numberOfPages - 1;
        i = [[[pdfDoc pageAtIndex:pageIndex] annotations] count];
    }
    if (annotation) {
        [self scrollAnnotationToVisible:annotation];
        [self setActiveAnnotation:annotation];
        if ([[annotation type] isEqualToString:@"Link"] || [annotation text]) {
            NSRect bounds = [annotation bounds]; 
            NSPoint point = [self convertPoint:[self convertPoint:NSMakePoint(NSMidX(bounds), NSMidY(bounds)) fromPage:[annotation page]] toView:nil]; 
            [[SKPDFHoverWindow sharedHoverWindow] showForAnnotation:annotation atPoint:[[self window] convertBaseToScreen:point]];
        } else {
            [[SKPDFHoverWindow sharedHoverWindow] orderOut:self];
        }
    }
}

- (void)scrollRect:(NSRect)rect inPageToVisible:(PDFPage *)page {
    rect = [self convertRect:[self convertRect:rect fromPage:page] toView:[self documentView]];
    [self goToPage:page];
    [[self documentView] scrollRectToVisible:rect];
}

- (void)scrollAnnotationToVisible:(PDFAnnotation *)annotation {
    [self scrollRect:[annotation bounds] inPageToVisible:[annotation page]];
}

- (void)displayLineAtPoint:(NSPoint)point inPageAtIndex:(unsigned int)pageIndex {
    if (pageIndex < [[self document] pageCount]) {
        PDFPage *page = [[self document] pageAtIndex:pageIndex];
        PDFSelection *sel = [page selectionForLineAtPoint:point];
        NSRect rect = sel ? [sel boundsForPage:page] : NSMakeRect(point.x - 5.0, point.y - 5.0, 10.0, 10.0);
        
        if (sel)
            [self setCurrentSelection:sel];
        [self scrollRect:rect inPageToVisible:page];
    }
}

#pragma mark Snapshots

- (void)takeSnapshot:(id)sender {
    NSPoint point;
    PDFPage *page;
    NSRect rect;
    
	if ([sender respondsToSelector:@selector(representedObject)] && [[sender representedObject] respondsToSelector:@selector(pointValue)]) {
        point = [[sender representedObject] pointValue];
        page = [self pageForPoint:point nearest:YES];
    } else {
		// First try the current mouse position
        point = [self convertPoint:[[self window] mouseLocationOutsideOfEventStream] fromView:nil];
        page = [self pageForPoint:point nearest:NO];
        if (page == nil) {
            // Get the center
            NSRect viewFrame = [self frame];
            point = NSMakePoint(NSMidX(viewFrame), NSMidY(viewFrame));
            page = [self pageForPoint:point nearest:YES];
        }
    }
    
    point = [self convertPoint:point toPage:page];
    
    rect = [self convertRect:[page boundsForBox:kPDFDisplayBoxCropBox] fromPage:page];
    rect.origin.y = point.y - 100.0;
    rect.size.height = 200.0;
    
    SKMainWindowController *controller = [[self window] windowController];
    
    [controller showSnapshotAtPageNumber:[[self document] indexForPage:page] forRect:[self convertRect:rect toPage:page] factor:1];
}

#pragma mark Notification handling

- (void)handleAnnotationWillChangeNotification:(NSNotification *)notification {
    PDFAnnotation *annotation = [notification object];
    if ([[[annotation page] document] isEqual:[self document]] && [[[notification userInfo] objectForKey:@"key"] isEqualToString:@"bounds"])
        [self setNeedsDisplayForAnnotation:annotation];
}

- (void)handleAnnotationDidChangeNotification:(NSNotification *)notification {
    PDFAnnotation *annotation = [notification object];
    if ([[[annotation page] document] isEqual:[self document]])
        [self setNeedsDisplayForAnnotation:annotation];
}

#pragma mark FullScreen navigation and autohide

- (void)handleWindowWillCloseNotification:(NSNotification *)notification {
    [navWindow orderOut:self];
}

- (void)setHasNavigation:(BOOL)hasNav autohidesCursor:(BOOL)hideCursor {
    hasNavigation = hasNav;
    autohidesCursor = hideCursor;
    
    if (hasNavigation) {
        // always recreate the navWindow, since moving between screens of different resolution can mess up the location (in spite of moveToScreen:)
        if (navWindow != nil)
            [navWindow release];
        else
            [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(handleWindowWillCloseNotification:) 
                                                         name: NSWindowWillCloseNotification object: [self window]];
        navWindow = [[SKNavigationWindow alloc] initWithPDFView:self];
        [navWindow moveToScreen:[[self window] screen]];
        [navWindow setLevel:[[self window] level]];
    } else if ([navWindow isVisible]) {
        [navWindow orderOut:self];
    }
    [self doAutohide:autohidesCursor || hasNavigation];
}

#pragma mark Menu validation

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    SEL action = [menuItem action];
    if (action == @selector(changeToolMode:)) {
        [menuItem setState:[self toolMode] == (unsigned)[menuItem tag] ? NSOnState : NSOffState];
        return YES;
    } else {
        return [super validateMenuItem:menuItem];
    }
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == [NSUserDefaultsController sharedUserDefaultsController] && [keyPath hasPrefix:@"values."]) {
        NSString *key = [keyPath substringFromIndex:7];
        if ([key isEqualToString:SKReadingBarColorKey] || [key isEqualToString:SKReadingBarTransparencyKey] || [key isEqualToString:SKReadingBarInvertKey]) {
            if (readingBar)
                [self setNeedsDisplay:YES];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end

#pragma mark -

@implementation SKPDFView (Private)

- (NSRect)resizeThumbForRect:(NSRect)rect rotation:(int)rotation {
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
		case 270:
            break;
	}
	
	return thumb;
}

- (NSRect)resizeThumbForRect:(NSRect)rect point:(NSPoint)point {
	NSRect thumb = rect;
    float size = 7.0;
    
    thumb.size = NSMakeSize(size, size);
	
    thumb.origin.x = NSMinX(rect) + point.x - 0.5 * size;
    thumb.origin.y = NSMinY(rect) + point.y - 0.5 * size;
	
    thumb.origin.x =  point.x > 0.5 * NSWidth(rect) ? floorf(NSMinX(thumb)) : ceilf(NSMinX(thumb));
    thumb.origin.y =  point.y > 0.5 * NSHeight(rect) ? floorf(NSMinY(thumb)) : ceilf(NSMinY(thumb));
    
	return thumb;
}

- (void)transformCGContext:(CGContextRef)context forPage:(PDFPage *)page {
    NSRect boxRect = [page boundsForBox:[self displayBox]];
    
    switch ([page rotation]) {
        case 0:
            CGContextTranslateCTM(context, -NSMinX(boxRect), -NSMinY(boxRect));
            break;
        case 90:
            CGContextRotateCTM(context, - M_PI / 2);
            CGContextTranslateCTM(context, -NSMaxX(boxRect), -NSMinY(boxRect));
            break;
        case 180:
            CGContextRotateCTM(context, M_PI);
            CGContextTranslateCTM(context, -NSMaxX(boxRect), -NSMaxY(boxRect));
            break;
        case 270:
            CGContextRotateCTM(context, M_PI / 2);
            CGContextTranslateCTM(context, -NSMinX(boxRect), -NSMaxY(boxRect));
            break;
    }
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

- (NSRange)visiblePageIndexRange {
    NSRect visibleRect = [[[self documentView] superview] convertRect:[[[self documentView] superview] visibleRect] toView:self];
    PDFPage *page;
    unsigned first, last;
    
    page = [self pageForPoint:NSMakePoint(NSMinX(visibleRect), NSMaxY(visibleRect)) nearest:YES];
    first = [[self document] indexForPage:page];
    page = [self pageForPoint:NSMakePoint(NSMaxX(visibleRect), NSMinY(visibleRect)) nearest:YES];
    last = [[self document] indexForPage:page];
    
    return NSMakeRange(first, last - first + 1);
}

#pragma mark Hover-rects

// Fix a bug in Tiger's PDFKit, tooltips lead to a crash when you reload a PDFDocument in a PDFView
// see http://www.cocoabuilder.com/archive/message/cocoa/2007/3/12/180190
- (void)scheduleAddingToolips {}

- (void)removeHoverRects {
    CFIndex idx = [hoverRects count];
    while (idx--) {
        [self removeTrackingRect:(NSTrackingRectTag)[hoverRects objectAtIndex:idx]];
        [hoverRects removeObjectAtIndex:idx];
    }
}

- (void)resetHoverRects {
    if (hoverRects == nil)
        hoverRects = (NSMutableArray *)CFArrayCreateMutable(NULL, 0, NULL);
    else
        [self removeHoverRects];
    
    NSRange range = [self visiblePageIndexRange];
    int i, iMax = NSMaxRange(range);
    NSRect visibleRect = [[[self documentView] superview] convertRect:[[[self documentView] superview] visibleRect] toView:self];
    
    for (i = 0; i < iMax; i++) {
        PDFPage *page = [[self document] pageAtIndex:i];
        NSArray *annotations = [page annotations];
        unsigned j, jMax = [annotations count];
        for (j = 0; j < jMax; j++) {
            PDFAnnotation *annotation = [annotations objectAtIndex:j];
            if ([[annotation type] isEqualToString:@"Note"] || [[annotation type] isEqualToString:@"Link"]) {
                NSRect rect = NSIntersectionRect([self convertRect:[annotation bounds] fromPage:page], visibleRect);
                if (NSIsEmptyRect(rect) == NO) {
                    NSTrackingRectTag tag = [self addTrackingRect:rect owner:self userData:annotation assumeInside:NO];
                    [hoverRects addObject:(id)tag];
                }
            }
        }
    }
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

#pragma mark Event handling

- (PDFDestination *)destinationForEvent:(NSEvent *)theEvent isLink:(BOOL *)isLink {
    NSPoint windowMouseLoc = [theEvent locationInWindow];
    
    NSPoint viewMouseLoc = [self convertPoint:windowMouseLoc fromView:nil];
    PDFPage *page = [self pageForPoint:viewMouseLoc nearest:YES];
    NSPoint pageSpaceMouseLoc = [self convertPoint:viewMouseLoc toPage:page];  
    PDFDestination *dest = [[[PDFDestination alloc] initWithPage:page atPoint:pageSpaceMouseLoc] autorelease];
    BOOL link = NO;
    
    if (([self areaOfInterestForMouse: theEvent] &  kPDFLinkArea) != 0) {
        PDFAnnotation *ann = [page annotationAtPoint:pageSpaceMouseLoc];
        if (ann != NULL && [[ann destination] page]){
            dest = [ann destination];
            link = YES;
        } 
        // Set link = NO if the annotation links outside the document (e.g. for a URL); currently this is only used for the hover window.  We could do something clever like show a URL icon in the hover window (or a WebView!), but for now we'll just ignore these links.
    }
    
    if (isLink) *isLink = link;
    return dest;
}

- (void)moveActiveAnnotationForKey:(unichar)eventChar byAmount:(float)delta {
    NSRect bounds = [activeAnnotation bounds];
    NSRect newBounds = bounds;
    PDFPage *page = [activeAnnotation page];
    NSRect pageBounds = [page boundsForBox:[self displayBox]];
    
    switch ([page rotation]) {
        case 0:
            if (eventChar == NSRightArrowFunctionKey) {
                if (NSMaxX(bounds) + delta <= NSMaxX(pageBounds))
                    newBounds.origin.x += delta;
                else if (NSMaxX(bounds) < NSMaxX(pageBounds))
                    newBounds.origin.x += NSMaxX(pageBounds) - NSMaxX(bounds);
            } else if (eventChar == NSLeftArrowFunctionKey) {
                if (NSMinX(bounds) - delta >= NSMinX(pageBounds))
                    newBounds.origin.x -= delta;
                else if (NSMinX(bounds) > NSMinX(pageBounds))
                    newBounds.origin.x -= NSMinX(bounds) - NSMinX(pageBounds);
            } else if (eventChar == NSUpArrowFunctionKey) {
                if (NSMaxY(bounds) + delta <= NSMaxY(pageBounds))
                    newBounds.origin.y += delta;
                else if (NSMaxY(bounds) < NSMaxY(pageBounds))
                    newBounds.origin.y += NSMaxY(pageBounds) - NSMaxY(bounds);
            } else if (eventChar == NSDownArrowFunctionKey) {
                if (NSMinY(bounds) - delta >= NSMinY(pageBounds))
                    newBounds.origin.y -= delta;
                else if (NSMinY(bounds) > NSMinY(pageBounds))
                    newBounds.origin.y -= NSMinY(bounds) - NSMinY(pageBounds);
            }
            break;
        case 90:
            if (eventChar == NSRightArrowFunctionKey) {
                if (NSMaxY(bounds) + delta <= NSMaxY(pageBounds))
                    newBounds.origin.y += delta;
            } else if (eventChar == NSLeftArrowFunctionKey) {
                if (NSMinY(bounds) - delta >= NSMinY(pageBounds))
                    newBounds.origin.y -= delta;
            } else if (eventChar == NSUpArrowFunctionKey) {
                if (NSMinX(bounds) - delta >= NSMinX(pageBounds))
                    newBounds.origin.x -= delta;
            } else if (eventChar == NSDownArrowFunctionKey) {
                if (NSMaxX(bounds) + delta <= NSMaxX(pageBounds))
                    newBounds.origin.x += delta;
            }
            break;
        case 180:
            if (eventChar == NSRightArrowFunctionKey) {
                if (NSMinX(bounds) - delta >= NSMinX(pageBounds))
                    newBounds.origin.x -= delta;
            } else if (eventChar == NSLeftArrowFunctionKey) {
                if (NSMaxX(bounds) + delta <= NSMaxX(pageBounds))
                    newBounds.origin.x += delta;
            } else if (eventChar == NSUpArrowFunctionKey) {
                if (NSMinY(bounds) - delta >= NSMinY(pageBounds))
                    newBounds.origin.y -= delta;
            } else if (eventChar == NSDownArrowFunctionKey) {
                if (NSMaxY(bounds) + delta <= NSMaxY(pageBounds))
                    newBounds.origin.y += delta;
            }
            break;
        case 270:
            if (eventChar == NSRightArrowFunctionKey) {
                if (NSMinY(bounds) - delta >= NSMinY(pageBounds))
                    newBounds.origin.y -= delta;
            } else if (eventChar == NSLeftArrowFunctionKey) {
                if (NSMaxY(bounds) + delta <= NSMaxY(pageBounds))
                    newBounds.origin.y += delta;
            } else if (eventChar == NSUpArrowFunctionKey) {
                if (NSMaxX(bounds) + delta <= NSMaxX(pageBounds))
                    newBounds.origin.x += delta;
            } else if (eventChar == NSDownArrowFunctionKey) {
                if (NSMinX(bounds) - delta >= NSMinX(pageBounds))
                    newBounds.origin.x -= delta;
            }
            break;
    }
    
    if (NSEqualRects(bounds, newBounds) == NO) {
        [activeAnnotation setBounds:newBounds];
        if ([[activeAnnotation type] isEqualToString:@"Square"] || [[activeAnnotation type] isEqualToString:@"Square"]) {
            NSString *selString = [[[[activeAnnotation page] selectionForRect:newBounds] string] stringByCollapsingWhitespaceAndNewlinesAndRemovingSurroundingWhitespaceAndNewlines];
            [activeAnnotation setContents:selString];
        }
    }
}

- (void)resizeActiveAnnotationForKey:(unichar)eventChar byAmount:(float)delta {
    NSRect bounds = [activeAnnotation bounds];
    NSRect newBounds = bounds;
    PDFPage *page = [activeAnnotation page];
    NSRect pageBounds = [page boundsForBox:[self displayBox]];
    
    if ([[activeAnnotation type] isEqualToString:@"Line"]) {
        
        SKPDFAnnotationLine *annotation = (SKPDFAnnotationLine *)activeAnnotation;
        NSPoint oldEndPoint = [annotation endPoint];
        NSPoint endPoint;
        NSPoint startPoint = [annotation startPoint];
        startPoint.x += NSMinX(bounds);
        startPoint.y += NSMinY(bounds);
        oldEndPoint.x += NSMinX(bounds);
        oldEndPoint.y += NSMinY(bounds);
        endPoint = oldEndPoint;
        
        // Resize the annotation.
        switch ([page rotation]) {
            case 0:
                if (eventChar == NSRightArrowFunctionKey) {
                    endPoint.x += delta;
                    if (endPoint.x > NSMaxX(pageBounds))
                        endPoint.x = NSMaxX(pageBounds) - 0.5;
                } else if (eventChar == NSLeftArrowFunctionKey) {
                    endPoint.x -= delta;
                    if (endPoint.x < NSMinX(pageBounds))
                        endPoint.x = NSMinX(pageBounds) + 0.5;
                } else if (eventChar == NSUpArrowFunctionKey) {
                    endPoint.y += delta;
                    if (endPoint.y > NSMaxY(pageBounds))
                        endPoint.y = NSMaxY(pageBounds) - 0.5;
                } else if (eventChar == NSDownArrowFunctionKey) {
                    endPoint.y -= delta;
                    if (endPoint.y < NSMinY(pageBounds))
                        endPoint.y = NSMinY(pageBounds) + 0.5;
                }
                break;
            case 90:
                if (eventChar == NSRightArrowFunctionKey) {
                    endPoint.y += delta;
                    if (endPoint.y > NSMaxY(pageBounds))
                        endPoint.y = NSMaxY(pageBounds) - 0.5;
                } else if (eventChar == NSLeftArrowFunctionKey) {
                    endPoint.y -= delta;
                    if (endPoint.y < NSMinY(pageBounds))
                        endPoint.y = NSMinY(pageBounds);
                } else if (eventChar == NSUpArrowFunctionKey) {
                    endPoint.x -= delta;
                    if (endPoint.x < NSMinX(pageBounds))
                        endPoint.x = NSMinX(pageBounds);
                } else if (eventChar == NSDownArrowFunctionKey) {
                    endPoint.x += delta;
                    if (endPoint.x > NSMaxX(pageBounds))
                        endPoint.x = NSMaxX(pageBounds) - 0.5;
                }
                break;
            case 180:
                if (eventChar == NSRightArrowFunctionKey) {
                    endPoint.x -= delta;
                    if (endPoint.x < NSMinX(pageBounds))
                        endPoint.x = NSMinX(pageBounds) + 0.5;
                } else if (eventChar == NSLeftArrowFunctionKey) {
                    endPoint.x += delta;
                    if (endPoint.x > NSMaxX(pageBounds))
                        endPoint.x = NSMaxX(pageBounds) - 0.5;
                } else if (eventChar == NSUpArrowFunctionKey) {
                    endPoint.y -= delta;
                    if (endPoint.y < NSMinY(pageBounds))
                        endPoint.y = NSMinY(pageBounds) + 0.5;
                } else if (eventChar == NSDownArrowFunctionKey) {
                    endPoint.y += delta;
                    if (endPoint.y > NSMaxY(pageBounds))
                        endPoint.y = NSMaxY(pageBounds) - 0.5;
                }
                break;
            case 270:
                if (eventChar == NSRightArrowFunctionKey) {
                    endPoint.y -= delta;
                    if (endPoint.y < NSMinY(pageBounds))
                        endPoint.y = NSMinY(pageBounds) + 0.5;
                } else if (eventChar == NSLeftArrowFunctionKey) {
                    endPoint.y += delta;
                    if (endPoint.y > NSMaxY(pageBounds))
                        endPoint.y = NSMaxY(pageBounds) - 0.5;
                } else if (eventChar == NSUpArrowFunctionKey) {
                    endPoint.x += delta;
                    if (endPoint.x > NSMaxX(pageBounds))
                        endPoint.x = NSMaxX(pageBounds) - 0.5;
                } else if (eventChar == NSDownArrowFunctionKey) {
                    endPoint.x -= delta;
                    if (endPoint.x < NSMinX(pageBounds))
                        endPoint.x = NSMinX(pageBounds) + 0.5;
                }
                break;
        }
        
        endPoint.x = floorf(endPoint.x) + 0.5;
        endPoint.y = floorf(endPoint.y) + 0.5;
        
        if (NSEqualPoints(endPoint, oldEndPoint) == NO) {
            newBounds.origin.x = floorf(fmin(startPoint.x, endPoint.x));
            newBounds.size.width = ceilf(fmax(endPoint.x, startPoint.x)) - NSMinX(newBounds);
            newBounds.origin.y = floorf(fmin(startPoint.y, endPoint.y));
            newBounds.size.height = ceilf(fmax(endPoint.y, startPoint.y)) - NSMinY(newBounds);
            
            if (NSWidth(newBounds) < 7.0) {
                newBounds.size.width = 7.0;
                newBounds.origin.x = floorf(0.5 * (startPoint.x + endPoint.x) - 3.5);
            }
            if (NSHeight(newBounds) < 7.0) {
                newBounds.size.height = 7.0;
                newBounds.origin.y = floorf(0.5 * (startPoint.y + endPoint.y) - 3.5);
            }
            
            startPoint.x -= NSMinX(newBounds);
            startPoint.y -= NSMinY(newBounds);
            endPoint.x -= NSMinX(newBounds);
            endPoint.y -= NSMinY(newBounds);
            
            [annotation setBounds:newBounds];
            [annotation setStartPoint:startPoint];
            [annotation setEndPoint:endPoint];
        }
        
    } else {
        
        switch ([page rotation]) {
            case 0:
                if (eventChar == NSRightArrowFunctionKey) {
                    if (NSMaxX(bounds) + delta <= NSMaxX(pageBounds)) {
                        newBounds.size.width += delta;
                    } else if (NSMaxX(bounds) < NSMaxX(pageBounds)) {
                        newBounds.size.width += NSMaxX(pageBounds) - NSMaxX(bounds);
                    }
                } else if (eventChar == NSLeftArrowFunctionKey) {
                    newBounds.size.width -= delta;
                    if (NSWidth(newBounds) < 8.0) {
                        newBounds.size.width = 8.0;
                    }
                } else if (eventChar == NSUpArrowFunctionKey) {
                    newBounds.origin.y += delta;
                    newBounds.size.height -= delta;
                    if (NSHeight(newBounds) < 8.0) {
                        newBounds.origin.y += NSHeight(newBounds) - 8.0;
                        newBounds.size.height = 8.0;
                    }
                } else if (eventChar == NSDownArrowFunctionKey) {
                    if (NSMinY(bounds) - delta >= NSMinY(pageBounds)) {
                        newBounds.origin.y -= delta;
                        newBounds.size.height += delta;
                    } else if (NSMinY(bounds) > NSMinY(pageBounds)) {
                        newBounds.origin.y -= NSMinY(bounds) - NSMinY(pageBounds);
                        newBounds.size.height += NSMinY(bounds) - NSMinY(pageBounds);
                    }
                }
                break;
            case 90:
                if (eventChar == NSRightArrowFunctionKey) {
                    if (NSMinY(bounds) + delta <= NSMaxY(pageBounds)) {
                        newBounds.size.height += delta;
                    } else if (NSMinY(bounds) < NSMaxY(pageBounds)) {
                        newBounds.size.height += NSMaxY(pageBounds) - NSMinY(bounds);
                    }
                } else if (eventChar == NSLeftArrowFunctionKey) {
                    newBounds.size.height -= delta;
                    if (NSHeight(newBounds) < 8.0) {
                        newBounds.size.height = 8.0;
                    }
                } else if (eventChar == NSUpArrowFunctionKey) {
                    newBounds.size.width -= delta;
                    if (NSWidth(newBounds) < 8.0) {
                        newBounds.size.width = 8.0;
                    }
                } else if (eventChar == NSDownArrowFunctionKey) {
                    if (NSMaxX(bounds) + delta <= NSMaxX(pageBounds)) {
                        newBounds.size.width += delta;
                    } else if (NSMaxX(bounds) < NSMaxX(pageBounds)) {
                        newBounds.size.width += NSMaxX(pageBounds) - NSMaxX(bounds);
                    }
                }
                break;
            case 180:
                if (eventChar == NSRightArrowFunctionKey) {
                    if (NSMinX(bounds) - delta >= NSMinX(pageBounds)) {
                        newBounds.origin.x -= delta;
                        newBounds.size.width += delta;
                    } else if (NSMinX(bounds) > NSMinX(pageBounds)) {
                        newBounds.origin.x -= NSMinX(bounds) - NSMinX(pageBounds);
                        newBounds.size.width += NSMinX(bounds) - NSMinX(pageBounds);
                    }
                } else if (eventChar == NSLeftArrowFunctionKey) {
                    newBounds.origin.x += delta;
                    newBounds.size.width -= delta;
                    if (NSWidth(newBounds) < 8.0) {
                        newBounds.origin.x += NSWidth(newBounds) - 8.0;
                        newBounds.size.width = 8.0;
                    }
                } else if (eventChar == NSUpArrowFunctionKey) {
                    newBounds.size.height -= delta;
                    if (NSHeight(newBounds) < 8.0) {
                        newBounds.size.height = 8.0;
                    }
                } else if (eventChar == NSDownArrowFunctionKey) {
                    if (NSMaxY(bounds) + delta <= NSMaxY(pageBounds)) {
                        newBounds.size.height += delta;
                    } else if (NSMaxY(bounds) < NSMaxY(pageBounds)) {
                        newBounds.size.height += NSMaxY(pageBounds) - NSMaxY(bounds);
                    }
                }
                break;
            case 270:
                if (eventChar == NSRightArrowFunctionKey) {
                    if (NSMinY(bounds) - delta >= NSMinY(pageBounds)) {
                        newBounds.origin.y -= delta;
                        newBounds.size.height += delta;
                    } else if (NSMinY(bounds) > NSMinY(pageBounds)) {
                        newBounds.origin.y -= NSMinY(bounds) - NSMinY(pageBounds);
                        newBounds.size.height += NSMinY(bounds) - NSMinY(pageBounds);
                    }
                } else if (eventChar == NSLeftArrowFunctionKey) {
                    newBounds.origin.y += delta;
                    newBounds.size.height -= delta;
                    if (NSHeight(newBounds) < 8.0) {
                        newBounds.origin.y += NSHeight(newBounds) - 8.0;
                        newBounds.size.height = 8.0;
                    }
                } else if (eventChar == NSUpArrowFunctionKey) {
                    newBounds.origin.x += delta;
                    newBounds.size.width -= delta;
                    if (NSWidth(newBounds) < 8.0) {
                        newBounds.origin.x += NSWidth(newBounds) - 8.0;
                        newBounds.size.width = 8.0;
                    }
                } else if (eventChar == NSDownArrowFunctionKey) {
                    if (NSMinX(bounds) - delta >= NSMinX(pageBounds)) {
                        newBounds.origin.x -= delta;
                        newBounds.size.width += delta;
                    } else if (NSMinX(bounds) > NSMinX(pageBounds)) {
                        newBounds.origin.x -= NSMinX(bounds) - NSMinX(pageBounds);
                        newBounds.size.width += NSMinX(bounds) - NSMinX(pageBounds);
                    }
                }
                break;
        }
        
        if (NSEqualRects(bounds, newBounds) == NO) {
            [activeAnnotation setBounds:newBounds];
            if ([[activeAnnotation type] isEqualToString:@"Square"] || [[activeAnnotation type] isEqualToString:@"Square"]) {
                NSString *selString = [[[[activeAnnotation page] selectionForRect:newBounds] string] stringByCollapsingWhitespaceAndNewlinesAndRemovingSurroundingWhitespaceAndNewlines];
                [activeAnnotation setContents:selString];
            }
        }
    }
}

- (void)moveReadingBarForKey:(unichar)eventChar {
    BOOL moved = NO;
    if (eventChar == NSDownArrowFunctionKey)
        moved = [readingBar goToNextLine];
    else if (eventChar == NSUpArrowFunctionKey)
        moved = [readingBar goToPreviousLine];
    else if (eventChar == NSRightArrowFunctionKey)
        moved = [readingBar goToNextPage];
    else if (eventChar == NSLeftArrowFunctionKey)
        moved = [readingBar goToPreviousPage];
    if (moved) {
        if ([[self currentPage] isEqual:[readingBar page]] == NO)
            [self goToPage:[readingBar page]];
        [self setNeedsDisplay:YES];
    }
}

- (BOOL)selectAnnotationWithEvent:(NSEvent *)theEvent {
    PDFAnnotation *newActiveAnnotation = NULL;
    PDFAnnotation *wasActiveAnnotation;
    NSArray *annotations;
    int i;
    NSPoint pagePoint;
    BOOL changed;
    PDFPage *activePage;
    
    // Mouse in display view coordinates.
    mouseDownLoc = [theEvent locationInWindow];
    
    NSPoint mouseDownOnPage = [self convertPoint:mouseDownLoc fromView:nil];
    
    // Page we're on.
    activePage = [self pageForPoint:mouseDownOnPage nearest:YES];
    
    // Get mouse in "page space".
    pagePoint = [self convertPoint:mouseDownOnPage toPage:activePage];
    
    // Hit test for annotation.
    annotations = [activePage annotations];
    i = [annotations count];
    
    while (i-- > 0) {
        PDFAnnotation *annotation = [annotations objectAtIndex:i];
        NSRect bounds = [annotation bounds];
        
        // Hit test annotation.
        if ([annotation isNoteAnnotation]) {
            if ([annotation hitTest:pagePoint]) {
                mouseDownInAnnotation = YES;
                newActiveAnnotation = annotation;
                // Remember click point relative to annotation origin.
                clickDelta.x = pagePoint.x - NSMinX(bounds);
                clickDelta.y = pagePoint.y - NSMinY(bounds);
                break;
            } else if (NSPointInRect(pagePoint, bounds)) {
                // register this, so we can do our own selection later
                mouseDownInAnnotation = YES;
            }
        }
    }
    
    if (([theEvent modifierFlags] & NSAlternateKeyMask) && [newActiveAnnotation isMovable]) {
        // select a new copy of the annotation
        PDFAnnotation *newAnnotation = [[PDFAnnotation alloc] initWithDictionary:[newActiveAnnotation dictionaryValue]];
        [activePage addAnnotation:newAnnotation];
        newActiveAnnotation = newAnnotation;
        [newAnnotation release];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewDidAddAnnotationNotification object:self 
            userInfo:[NSDictionary dictionaryWithObjectsAndKeys:newAnnotation, @"annotation", activePage, @"page", nil]];
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
    
    if (newActiveAnnotation == nil) {
        //[super mouseDown:theEvent];
    } else if ([theEvent clickCount] == 2 && [[activeAnnotation type] isEqualToString:@"FreeText"]) {
        // probably we should use the note window for Text annotations
        NSRect editBounds = [activeAnnotation bounds];
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
        
        if ([[activeAnnotation type] isEqualToString:@"Line"]) {
            wasStartPoint = [(SKPDFAnnotationLine *)activeAnnotation startPoint];
            wasEndPoint = [(SKPDFAnnotationLine *)activeAnnotation endPoint];
        }
        
        // Force redisplay.
		[self setNeedsDisplayForAnnotation:activeAnnotation];
        draggingAnnotation = [activeAnnotation isMovable];
        
        // Hit-test for resize box.
        if ([[activeAnnotation type] isEqualToString:@"Line"]) {
            if (NSPointInRect(pagePoint, [self resizeThumbForRect:wasBounds point:[(SKPDFAnnotationLine *)activeAnnotation endPoint]])) {
                resizingAnnotation = YES;
                draggingStartPoint = NO;
            } else if (NSPointInRect(pagePoint, [self resizeThumbForRect:wasBounds point:[(SKPDFAnnotationLine *)activeAnnotation startPoint]])) {
                resizingAnnotation = YES;
                draggingStartPoint = YES;
            } else {
                resizingAnnotation = NO;
            }
       }  else {
            resizingAnnotation = [activeAnnotation isResizable] && NSPointInRect(pagePoint, [self resizeThumbForRect:wasBounds rotation:[activePage rotation]]);
        }
    }
    
    return newActiveAnnotation != nil;
}

- (void)dragAnnotationWithEvent:(NSEvent *)theEvent {
    PDFPage *activePage = [activeAnnotation page];
    NSRect newBounds;
    NSRect currentBounds = [activeAnnotation bounds];
    NSRect pageBounds = [activePage  boundsForBox:[self displayBox]];
    
    if (resizingAnnotation) {
        NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        NSPoint startPoint = [self convertPoint:[self convertPoint:mouseDownLoc fromView:nil] toPage:activePage];
        NSPoint endPt = [self convertPoint:mouseLoc toPage:activePage];
        NSPoint relPoint = NSMakePoint(endPt.x - startPoint.x, endPt.y - startPoint.y);
        newBounds = wasBounds;
        
        if ([[activeAnnotation type] isEqualToString:@"Line"]) {
            
            SKPDFAnnotationLine *annotation = (SKPDFAnnotationLine *)activeAnnotation;
            NSPoint endPoint = wasEndPoint;
            endPoint.x += NSMinX(wasBounds);
            endPoint.y += NSMinY(wasBounds);
            startPoint = wasStartPoint;
            startPoint.x += NSMinX(wasBounds);
            startPoint.y += NSMinY(wasBounds);
            
            // Resize the annotation.
            switch ([activePage rotation]) {
                case 0:
                    if (draggingStartPoint) {
                        startPoint.x += relPoint.x;
                        startPoint.y += relPoint.y;
                    } else {
                        endPoint.x += relPoint.x;
                        endPoint.y += relPoint.y;
                    }
                    break;
                case 90:
                    if (draggingStartPoint) {
                        startPoint.x += relPoint.y;
                        startPoint.y -= relPoint.x;
                    } else {
                        endPoint.x += relPoint.y;
                        endPoint.y -= relPoint.x;
                    }
                    break;
                case 180:
                    if (draggingStartPoint) {
                        startPoint.x -= relPoint.x;
                        startPoint.y -= relPoint.y;
                    } else {
                        endPoint.x -= relPoint.x;
                        endPoint.y -= relPoint.y;
                    }
                    break;
                case 270:
                    if (draggingStartPoint) {
                        startPoint.x -= relPoint.y;
                        startPoint.y += relPoint.x;
                    } else {
                        endPoint.x -= relPoint.y;
                        endPoint.y += relPoint.x;
                    }
                    break;
            }
            
            if (draggingStartPoint) {
                if (startPoint.x > NSMaxX(pageBounds))
                    startPoint.x = NSMaxX(pageBounds) - 0.5;
                else if (startPoint.x < NSMinX(pageBounds))
                    startPoint.x = NSMinX(pageBounds) + 0.5;
                if (startPoint.y > NSMaxY(pageBounds))
                    startPoint.y = NSMaxY(pageBounds) - 0.5;
                else if (startPoint.y < NSMinY(pageBounds))
                    startPoint.y = NSMinY(pageBounds) + 0.5;
                startPoint.x = floorf(startPoint.x) + 0.5;
                startPoint.y = floorf(startPoint.y) + 0.5;
            } else {
                if (endPoint.x > NSMaxX(pageBounds))
                    endPoint.x = NSMaxX(pageBounds) - 0.5;
                else if (endPoint.x < NSMinX(pageBounds))
                    endPoint.x = NSMinX(pageBounds) + 0.5;
                if (endPoint.y > NSMaxY(pageBounds))
                    endPoint.y = NSMaxY(pageBounds) - 0.5;
                else if (endPoint.y < NSMinY(pageBounds))
                    endPoint.y = NSMinY(pageBounds) + 0.5;
                endPoint.x = floorf(endPoint.x) + 0.5;
                endPoint.y = floorf(endPoint.y) + 0.5;
            }
            
            newBounds.origin.x = floorf(fmin(startPoint.x, endPoint.x));
            newBounds.size.width = ceilf(fmax(endPoint.x, startPoint.x)) - NSMinX(newBounds);
            newBounds.origin.y = floorf(fmin(startPoint.y, endPoint.y));
            newBounds.size.height = ceilf(fmax(endPoint.y, startPoint.y)) - NSMinY(newBounds);
            
            if (NSWidth(newBounds) < 7.0) {
                newBounds.size.width = 7.0;
                newBounds.origin.x = floorf(0.5 * (startPoint.x + endPoint.x) - 3.5);
            }
            if (NSHeight(newBounds) < 7.0) {
                newBounds.size.height = 7.0;
                newBounds.origin.y = floorf(0.5 * (startPoint.y + endPoint.y) - 3.5);
            }
            
            startPoint.x -= NSMinX(newBounds);
            startPoint.y -= NSMinY(newBounds);
            endPoint.x -= NSMinX(newBounds);
            endPoint.y -= NSMinY(newBounds);
            
            [annotation setStartPoint:startPoint];
            [annotation setEndPoint:endPoint];
            
        } else {
            
            switch ([activePage rotation]) {
                case 0:
                    newBounds.origin.y += relPoint.y;
                    newBounds.size.width += relPoint.x;
                    newBounds.size.height -= relPoint.y;
                    if (NSMaxX(newBounds) > NSMaxX(pageBounds)) {
                        newBounds.size.width = NSMaxX(pageBounds) - NSMinX(newBounds);
                    }
                    if (NSMinY(newBounds) < NSMinY(pageBounds)) {
                        newBounds.size.height = NSMaxY(newBounds) - NSMinY(pageBounds);
                        newBounds.origin.y = NSMinY(pageBounds);
                    }
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
                    if (NSMaxX(newBounds) > NSMaxX(pageBounds)) {
                        newBounds.size.width = NSMaxX(pageBounds) - NSMinX(newBounds);
                    }
                    if (NSMaxY(newBounds) > NSMaxY(pageBounds)) {
                        newBounds.size.height = NSMaxY(pageBounds) - NSMinY(newBounds);
                    }
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
                    if (NSMinX(newBounds) < NSMinX(pageBounds)) {
                        newBounds.size.width = NSMaxX(newBounds) - NSMinX(pageBounds);
                        newBounds.origin.x = NSMinX(pageBounds);
                    }
                    if (NSMaxY(newBounds) > NSMaxY(pageBounds)) {
                        newBounds.size.height = NSMaxY(pageBounds) - NSMinY(newBounds);
                    }
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
                    if (NSMinX(newBounds) < NSMinX(pageBounds)) {
                        newBounds.size.width = NSMaxX(newBounds) - NSMinX(pageBounds);
                        newBounds.origin.x = NSMinX(pageBounds);
                    }
                    if (NSMinY(newBounds) < NSMinY(pageBounds)) {
                        newBounds.size.height = NSMaxY(newBounds) - NSMinY(pageBounds);
                        newBounds.origin.y = NSMinY(pageBounds);
                    }
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
            
        }
    } else {
        // Move annotation.
        [[self documentView] autoscroll:theEvent];
        
        NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        PDFPage *newActivePage = [self pageForPoint:mouseLoc nearest:YES];
        
        pageBounds = [newActivePage  boundsForBox:[self displayBox]];
        
        if (newActivePage == nil) {
            // this should never happen, but just to be sure
            newBounds = wasBounds;
        } else {
            if (newActivePage != activePage) {
                // move the annotation to the new page
                [activeAnnotation retain];
                [self setNeedsDisplayForAnnotation:activeAnnotation];
                [activePage removeAnnotation:activeAnnotation];
                [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewDidRemoveAnnotationNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:activePage, @"page", activeAnnotation, @"annotation", nil]];                
                [newActivePage addAnnotation:activeAnnotation];
                [activeAnnotation release];
                [[NSNotificationCenter defaultCenter] postNotificationName:SKPDFViewDidAddAnnotationNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:newActivePage, @"page", activeAnnotation, @"annotation", nil]];                
                activePage = newActivePage;
            }
            
            NSPoint endPt = [self convertPoint:mouseLoc toPage:activePage];
            newBounds = currentBounds;
            newBounds.origin.x = roundf(endPt.x - clickDelta.x);
            newBounds.origin.y = roundf(endPt.y - clickDelta.y);
            // constrain bounds inside page bounds
            if (NSMaxX(newBounds) > NSMaxX(pageBounds))
                newBounds.origin.x = NSMaxX(pageBounds) - NSWidth(newBounds);
            if (NSMinX(newBounds) < NSMinX(pageBounds))
                newBounds.origin.x = NSMinX(pageBounds);
            if (NSMaxY(newBounds) > NSMaxY(pageBounds))
                newBounds.origin.y = NSMaxY(pageBounds) - NSHeight(newBounds);
            if (NSMinY(newBounds) < NSMinY(pageBounds))
                newBounds.origin.y = NSMinY(pageBounds);
        }
    }
    
    // Change annotation's location.
    [activeAnnotation setBounds:newBounds];
}

- (void)dragWithEvent:(NSEvent *)theEvent {
	NSPoint initialLocation = [theEvent locationInWindow];
	NSRect visibleRect = [[self documentView] visibleRect];
	BOOL keepGoing = YES;
	
    [[NSCursor closedHandCursor] push];
    
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
    
    [NSCursor pop];
    // ??? PDFView's delayed layout seems to reset the cursor to an arrow
    [self performSelector:@selector(mouseMoved:) withObject:theEvent afterDelay:0];
}

- (void)dragReadingBarWithEvent:(NSEvent *)theEvent {
	BOOL keepGoing = YES;
    PDFPage *page = [readingBar page];
    NSArray *lineBounds = [page lineBounds];
	
    [[NSCursor closedHandCursor] push];
    
	while (keepGoing) {
		theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
		switch ([theEvent type]) {
			case NSLeftMouseDragged:
            {
                [[self documentView] autoscroll:theEvent];
                NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
                PDFPage *currentPage = [self pageForPoint:mouseLoc nearest:YES];
                
                mouseLoc = [self convertPoint:mouseLoc toPage:currentPage];
                
                if ([currentPage isEqual:page] == NO) {
                    page = currentPage;
                    lineBounds = [page lineBounds];
                }
                
                int i, iMax = [lineBounds count];
                
                for (i = 0; i < iMax; i++) {
                    NSRect rect = [[lineBounds objectAtIndex:i] rectValue];
                    if (NSMinY(rect) <= mouseLoc.y && NSMaxY(rect) >= mouseLoc.y) {
                        [readingBar setPage:page];
                        [readingBar setCurrentLine:i];
                        [self setNeedsDisplay:YES];
                        break;
                    }
                }
				break;
            }
			case NSLeftMouseUp:
				keepGoing = NO;
				break;
				
			default:
				/* Ignore any other kind of event. */
				break;
		} // end of switch (event type)
	} // end of mouse-tracking loop
    
    [NSCursor pop];
    // ??? PDFView's delayed layout seems to reset the cursor to an arrow
    [self performSelector:@selector(mouseMoved:) withObject:theEvent afterDelay:0];
}

- (void)selectSnapshotWithEvent:(NSEvent *)theEvent {
    NSPoint mouseLoc = [theEvent locationInWindow];
	NSPoint startPoint = [[self documentView] convertPoint:mouseLoc fromView:nil];
	NSPoint	currentPoint;
    NSRect selectionRect = {startPoint, NSZeroSize};
    NSRect bounds;
    float minX, maxX, minY, maxY;
    BOOL dragged = NO;
    BOOL keepGoing = YES;
	
    [[self window] discardCachedImage];
    
	while (keepGoing) {
		theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSFlagsChangedMask];
        
        [[self window] restoreCachedImage];
        [[self window] flushWindow];
		
        switch ([theEvent type]) {
			case NSLeftMouseDragged:
				[[self documentView] autoscroll:theEvent];
                mouseLoc = [theEvent locationInWindow];
                dragged = YES;
                
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
				keepGoing = NO;
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
    int factor = 1;
    
    if (dragged == NO) {
        
        BOOL isLink = NO;
        PDFDestination *dest = [self destinationForEvent:theEvent isLink:&isLink];
        
        if (isLink) {
            page = [dest page];
            point = [self convertPoint:[dest point] fromPage:page];
            point.y -= 100.0;
        }
        
        rect = [self convertRect:[page boundsForBox:kPDFDisplayBoxCropBox] fromPage:page];
        rect.origin.y = point.y - 100.0;
        rect.size.height = 200.0;
        
    } else {
    
        bounds = [self convertRect:[[self documentView] bounds] fromView:[self documentView]];
        
        if (NSWidth(rect) < 40.0 && NSHeight(rect) < 40.0)
            factor = 3;
        else if (NSWidth(rect) < 60.0 && NSHeight(rect) < 60.0)
            factor = 2;
        
        if (factor * NSWidth(rect) < 60.0) {
            rect = NSInsetRect(rect, 0.5 * (NSWidth(rect) - 60.0 / factor), 0.0);
            if (NSMinX(rect) < NSMinX(bounds))
                rect.origin.x = NSMinX(bounds);
            if (NSMaxX(rect) > NSMaxX(bounds))
                rect.origin.x = NSMaxX(bounds) - NSWidth(rect);
        }
        if (factor * NSHeight(rect) < 60.0) {
            rect = NSInsetRect(rect, 0.5 * (NSHeight(rect) - 60.0 / factor), 0.0);
            if (NSMinY(rect) < NSMinY(bounds))
                rect.origin.y = NSMinY(bounds);
            if (NSMaxX(rect) > NSMaxY(bounds))
                rect.origin.y = NSMaxY(bounds) - NSHeight(rect);
        }
    }
    
    SKMainWindowController *controller = [[self window] windowController];
    
    [controller showSnapshotAtPageNumber:[[self document] indexForPage:page] forRect:[self convertRect:rect toPage:page] factor:factor];
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
            NSGraphicsContext *ctxt = [NSGraphicsContext currentContext];
            [ctxt saveGraphicsState];
            outlineRect = NSInsetRect(NSIntegralRect([clipView convertRect:magRect fromView:nil]), 0.5, 0.5);
            path = [NSBezierPath bezierPathWithRect:outlineRect];
            [path setLineWidth:1.0];
            [[NSColor blackColor] set];
            [path stroke];
            [ctxt flushGraphics];
            [ctxt restoreGraphicsState];
            [clipView unlockFocus];
            
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
	[[self window] flushWindowIfNeeded];
	[NSCursor unhide];
	[documentView setPostsBoundsChangedNotifications:postNotification];
	[self flagsChanged:theEvent]; // update cursor
}

- (void)pdfsyncWithEvent:(NSEvent *)theEvent {
    SKDocument *document = (SKDocument *)[[[self window] windowController] document];
    
    if ([document respondsToSelector:@selector(synchronizer)]) {
        
        SKPDFSynchronizer *synchronizer = [document synchronizer];
        NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        PDFPage *page = [self pageForPoint:mouseLoc nearest:YES];
        NSPoint location = [self convertPoint:mouseLoc toPage:page];
        unsigned int pageIndex = [[self document] indexForPage:page];
        PDFSelection *sel = [page selectionForLineAtPoint:location];
        NSRect rect = sel ? [sel boundsForPage:page] : NSMakeRect(location.x - 20.0, location.y - 5.0, 40.0, 10.0);
        NSString *file = nil;
        int line = -1;
        
        if ([synchronizer getLine:&line file:&file forLocation:location inRect:rect atPageIndex:pageIndex] &&
            [[NSFileManager defaultManager] fileExistsAtPath:file]) {
            
            NSString *editorCmd = [[NSUserDefaults standardUserDefaults] objectForKey:SKTeXEditorCommandKey];
            NSMutableString *cmdString = [[[[NSUserDefaults standardUserDefaults] objectForKey:SKTeXEditorArgumentsKey] mutableCopy] autorelease];
            
            [cmdString replaceOccurrencesOfString:@"%file" withString:file options:NSLiteralSearch range: NSMakeRange(0, [cmdString length] )];
            [cmdString replaceOccurrencesOfString:@"%line" withString:[NSString stringWithFormat:@"%d", line] options:NSLiteralSearch range:NSMakeRange(0, [cmdString length])];
            [cmdString insertString:@" " atIndex:0];
            [cmdString insertString:editorCmd atIndex:0];
            
            [NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", cmdString, nil]];
            
        } else NSBeep();
    }
}

@end

#pragma mark Core Graphics extension

static CGMutablePathRef SKCGCreatePathWithRoundRectInRect(CGRect rect, float radius)
{
    // Make sure radius doesn't exceed a maximum size to avoid artifacts:
    radius = fmin(radius, 0.5f * fmin(rect.size.width, rect.size.height));
    
    CGMutablePathRef path = CGPathCreateMutable();
    
    // Make sure silly values simply lead to un-rounded corners:
    if(radius <= 0) {
        CGPathAddRect(path, NULL, rect);
    } else {
        // Now draw our rectangle:
        CGPathMoveToPoint(path, NULL, rect.origin.x, rect.origin.y + radius);
        // Bottom left (origin):
        CGPathAddArcToPoint(path, NULL, rect.origin.x, rect.origin.y, rect.origin.x + rect.size.width, rect.origin.y, radius);
        // Bottom edge and bottom right:
        CGPathAddArcToPoint(path, NULL, rect.origin.x + rect.size.width, rect.origin.y, rect.origin.x + rect.size.width, rect.origin.y + rect.size.height, radius);
        // Right edge and top right:
        CGPathAddArcToPoint(path, NULL, rect.origin.x + rect.size.width, rect.origin.y + rect.size.height, rect.origin.x, rect.origin.y + rect.size.height, radius);
        // Top edge and top left:
        CGPathAddArcToPoint(path, NULL, rect.origin.x, rect.origin.y + rect.size.height, rect.origin.x, rect.origin.y, radius);
        // Left edge:
        CGPathCloseSubpath(path);
    }
    return path;
}


@implementation PDFDocument (SKExtensions)

- (PDFSelection *)selectionByExtendingSelection:(PDFSelection *)selection toPage:(PDFPage *)page atPoint:(NSPoint)point {
    PDFSelection *sel = selection;
    NSArray *pages = [selection pages];
    
    if ([pages count] && [selection respondsToSelector:@selector(numberOfRangesOnPage:)] && [selection respondsToSelector:@selector(rangeAtIndex:onPage:)]) {
        PDFPage *firstPage = [pages objectAtIndex:0];
        PDFPage *lastPage = [pages lastObject];
        unsigned int pageIndex = [self indexForPage:page];
        unsigned int firstPageIndex = [self indexForPage:firstPage];
        unsigned int lastPageIndex = [self indexForPage:lastPage];
        int firstChar = [selection rangeAtIndex:0 onPage:firstPage].location;
        int lastChar = NSMaxRange([selection rangeAtIndex:[selection numberOfRangesOnPage:lastPage] - 1 onPage:lastPage]) - 1;
        NSRect firstRect = [firstPage characterBoundsAtIndex:firstChar];
        NSRect lastRect = [lastPage characterBoundsAtIndex:lastChar];
        
        if (pageIndex < firstPageIndex || (pageIndex == firstPageIndex && (point.y > NSMaxY(firstRect) || (point.y > NSMinY(firstRect) && point.x < NSMinX(firstRect)))))
            sel = [self selectionFromPage:page atPoint:point toPage:lastPage atPoint:NSMakePoint(NSMaxX(lastRect), NSMidY(lastRect))];
        if (pageIndex > lastPageIndex || (pageIndex == lastPageIndex && (point.y < NSMinY(lastRect) || (point.y < NSMaxY(lastRect) && point.x > NSMaxX(lastRect)))))
            sel = [self selectionFromPage:firstPage atPoint:NSMakePoint(NSMinX(firstRect), NSMidY(firstRect)) toPage:page atPoint:point];
    }
    return sel;
}

@end

