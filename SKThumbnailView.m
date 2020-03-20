//
//  SKThumbnailView.m
//  Skim
//
//  Created by Christiaan Hofman on 17/02/2020.
/*
This software is Copyright (c) 2020
Christiaan Hofman. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

- Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.

- Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in
the documentation and/or other materials provided with the
distribution.

- Neither the name of Christiaan Hofman nor the names of any
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

#import "SKThumbnailView.h"
#import "SKThumbnail.h"
#import "SKApplication.h"
#import "NSView_SKExtensions.h"
#import "NSImage_SKExtensions.h"
#import "NSBitmapImageRep_SKExtensions.h"
#import "NSMenu_SKExtensions.h"
#import <Quartz/Quartz.h>
#import "PDFPage_SKExtensions.h"

#define MARGIN 8.0
#define TEXT_MARGIN 4.0
#define TEXT_SPACE 32.0
#define SELECTION_MARGIN 6.0
#define IMAGE_SEL_RADIUS 8.0
#define TEXT_SEL_RADIUS 4.0

#define IMAGE_KEY @"image"

static char SKThumbnailViewThumbnailObservationContext;

@implementation SKThumbnailView

@synthesize selected, thumbnail, backgroundStyle, highlightLevel, marked;

- (void)commonInit {
    imageCell = [[NSImageCell alloc] initImageCell:nil];
    [imageCell setImageScaling:NSImageScaleProportionallyUpOrDown];
    labelCell = [[NSTextFieldCell alloc] initTextCell:@""];
    [labelCell setAlignment:NSCenterTextAlignment];
}

- (id)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    @try { [thumbnail removeObserver:self forKeyPath:IMAGE_KEY]; }
    @catch (id e) {}
    SKDESTROY(imageCell);
    SKDESTROY(labelCell);
    SKDESTROY(thumbnail);
    [super dealloc];
}

#pragma mark Layout

+ (NSSize)sizeForImageSize:(NSSize)size {
    return NSMakeSize(size.width + 2.0 * MARGIN, size.height + 2.0 * MARGIN + TEXT_SPACE);
}

- (NSRect)imageRect {
    return NSOffsetRect(NSInsetRect([self bounds], MARGIN, MARGIN + 0.5 * TEXT_SPACE), 0.0, 0.5 * TEXT_SPACE);
}

- (NSRect)textRect {
    NSSize textSize = [labelCell cellSize];
    NSRect textRect = NSInsetRect([self bounds], TEXT_MARGIN, TEXT_SPACE - textSize.height);
    textRect.size.height = textSize.height;
    return textRect;
}

- (NSRect)markRect {
    NSRect bounds = [self bounds];
    return NSMakeRect(NSMaxX(bounds) - MARGIN, NSMaxY(bounds) - MARGIN - 16.0, 6.0, 10.0);
}

#pragma mark Accessors

- (void)setThumbnail:(SKThumbnail *)newThumbnail {
    if (thumbnail != newThumbnail) {
        [thumbnail removeObserver:self forKeyPath:IMAGE_KEY];
        [thumbnail release];
        thumbnail = [newThumbnail retain];
        [labelCell setObjectValue:[thumbnail label]];
        [imageCell setObjectValue:nil];
        [thumbnail addObserver:self forKeyPath:IMAGE_KEY options:0 context:&SKThumbnailViewThumbnailObservationContext];
        [self setNeedsDisplay:YES];
    }
}

- (void)setSelected:(BOOL)newSelected {
    if (selected != newSelected) {
        selected = newSelected;
        [self setNeedsDisplay:YES];
    }
}

- (void)setBackgroundStyle:(NSBackgroundStyle)newBackgroundStyle {
    if (backgroundStyle != newBackgroundStyle) {
        backgroundStyle = newBackgroundStyle;
        [self setNeedsDisplayInRect:[self textRect]];
        if ([self isSelected])
            [self setNeedsDisplayInRect:[self imageRect]];
    }
}

- (void)setHighlightLevel:(NSInteger)newHighlightLevel {
    if (newHighlightLevel != highlightLevel) {
        highlightLevel = newHighlightLevel;
        [self setNeedsDisplayInRect:[self textRect]];
    }
}

- (void)setMarked:(BOOL)newMarked {
    if (marked != newMarked) {
        marked = newMarked;
        [self setNeedsDisplayInRect:[self markRect]];
    }
}

#pragma mark Drawing

- (void)drawRect:(NSRect)dirtyRect {
    NSRect imageRect = [self imageRect];
    NSRect textRect = [self textRect];
    
    [labelCell setBackgroundStyle:[self backgroundStyle]];
    if ([self isSelected]) {
        NSRect rect = NSInsetRect(imageRect, -SELECTION_MARGIN, -SELECTION_MARGIN);
        if (NSIntersectsRect(dirtyRect, rect)) {
            [NSGraphicsContext saveGraphicsState];
            if ([self backgroundStyle] == NSBackgroundStyleDark)
                [[NSColor darkGrayColor] setFill];
            else
                [[NSColor secondarySelectedControlColor] setFill];
            [[NSBezierPath bezierPathWithRoundedRect:rect xRadius:IMAGE_SEL_RADIUS yRadius:IMAGE_SEL_RADIUS] fill];
            [NSGraphicsContext restoreGraphicsState];
        }
        
        CGFloat inset = floor(0.5 * (NSWidth(textRect) - [labelCell cellSize].width));
        rect = NSInsetRect(textRect, inset, 0.0);
        if (NSIntersectsRect(dirtyRect, rect)) {
            [NSGraphicsContext saveGraphicsState];
            if ([[self window] isKeyWindow] || [[self window] isMainWindow]) {
                [[NSColor alternateSelectedControlColor] setFill];
                [labelCell setBackgroundStyle:NSBackgroundStyleDark];
            } else if ([self backgroundStyle] == NSBackgroundStyleDark) {
                [[NSColor darkGrayColor] setFill];
            } else {
                [[NSColor secondarySelectedControlColor] setFill];
            }
            [[NSBezierPath bezierPathWithRoundedRect:rect xRadius:TEXT_SEL_RADIUS yRadius:TEXT_SEL_RADIUS] fill];
            [NSGraphicsContext restoreGraphicsState];
        }
    } else if ([self highlightLevel] > 0) {
        CGFloat inset = fmax(0.0, floor(0.5 * (NSWidth(textRect) - [labelCell cellSize].width)));
        NSRect rect = NSInsetRect(textRect, inset, 0.0);
        if (NSIntersectsRect(rect, dirtyRect)) {
            NSColor *color;
            if ([[self window] isKeyWindow] || [[self window] isMainWindow])
                color = [NSColor alternateSelectedControlColor];
            else if ([self backgroundStyle] == NSBackgroundStyleDark)
                color = [NSColor darkGrayColor];
            else
                color = [NSColor secondarySelectedControlColor];
            [NSGraphicsContext saveGraphicsState];
            [[color colorWithAlphaComponent:fmin(1.0, 0.1 * [self highlightLevel])] setStroke];
            [[NSBezierPath bezierPathWithRoundedRect:NSInsetRect(rect, 0.5, 0.5) xRadius:TEXT_SEL_RADIUS - 0.5 yRadius:TEXT_SEL_RADIUS - 0.5] stroke];
            [NSGraphicsContext restoreGraphicsState];
        }
    }
    
    if ([self isMarked]) {
        NSRect rect = [self markRect];
        if (NSIntersectsRect(dirtyRect, rect)) {
            [NSGraphicsContext saveGraphicsState];
            [[NSColor colorWithCalibratedRed:0.581 green:0.088 blue:0.319 alpha:1.0] setFill];
            NSBezierPath *path = [NSBezierPath bezierPath];
            [path moveToPoint:NSMakePoint(NSMinX(rect), NSMinY(rect))];
            [path lineToPoint:NSMakePoint(NSMidX(rect), NSMinY(rect) + 0.5 * NSWidth(rect))];
            [path lineToPoint:NSMakePoint(NSMaxX(rect), NSMinY(rect))];
            [path lineToPoint:NSMakePoint(NSMaxX(rect), NSMaxY(rect))];
            [path lineToPoint:NSMakePoint(NSMinX(rect), NSMaxY(rect))];
            [path closePath];
            [path fill];
            [NSGraphicsContext restoreGraphicsState];
        }
    }

    if (NSIntersectsRect(dirtyRect, imageRect)) {
        if ([imageCell objectValue] == nil && NSIntersectsRect(imageRect, [self visibleRect]))
            [imageCell setObjectValue:[[self thumbnail] image]];
        
        [imageCell drawWithFrame:imageRect inView:self];
    }
    
    if (NSIntersectsRect(dirtyRect, textRect)) {
        [labelCell drawWithFrame:textRect inView:self];
    }
}

#pragma mark Updating

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (context == &SKThumbnailViewThumbnailObservationContext) {
        [imageCell setObjectValue:nil];
        [self setNeedsDisplayInRect:[self imageRect]];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)handleKeyOrMainStateChangedNotification:(NSNotification *)note {
    if ([self isSelected] || [self highlightLevel] > 0)
        [self setNeedsDisplayInRect:[self textRect]];
}

- (void)handleScrollBoundsChangedNotification:(NSNotification *)note {
    if ([imageCell objectValue] == nil) {
        NSRect imageRect = [self imageRect];
        if (NSIntersectsRect(imageRect, [self visibleRect]))
            [self setNeedsDisplayInRect:imageRect];
    }
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow {
    NSWindow *oldWindow = [self window];
    if (oldWindow) {
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc removeObserver:self name:NSWindowDidBecomeMainNotification object:oldWindow];
        [nc removeObserver:self name:NSWindowDidResignMainNotification object:oldWindow];
        [nc removeObserver:self name:NSWindowDidBecomeKeyNotification object:oldWindow];
        [nc removeObserver:self name:NSWindowDidResignKeyNotification object:oldWindow];
        NSView *clipView = [[self enclosingScrollView] contentView];
        if (clipView)
            [nc removeObserver:self name:NSViewBoundsDidChangeNotification object:clipView];
    }
    if (newWindow) {
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(handleKeyOrMainStateChangedNotification:) name:NSWindowDidBecomeMainNotification object:newWindow];
        [nc addObserver:self selector:@selector(handleKeyOrMainStateChangedNotification:) name:NSWindowDidResignMainNotification object:newWindow];
        [nc addObserver:self selector:@selector(handleKeyOrMainStateChangedNotification:) name:NSWindowDidBecomeKeyNotification object:newWindow];
        [nc addObserver:self selector:@selector(handleKeyOrMainStateChangedNotification:) name:NSWindowDidResignKeyNotification object:newWindow];
    }
    [super viewWillMoveToWindow:newWindow];
}

- (void)viewDidMoveToWindow {
    if ([self window]) {
        NSView *clipView = [[self enclosingScrollView] contentView];
        if (clipView) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleScrollBoundsChangedNotification:) name:NSViewBoundsDidChangeNotification object:clipView];
            [self handleScrollBoundsChangedNotification:nil];
        }
    }
    [super viewDidMoveToWindow];
}

#pragma mark Event handling

- (void)mouseDown:(NSEvent *)theEvent {
    if ([NSApp willDragMouse]) {
        
        id<NSPasteboardWriting> item = [[[self thumbnail] page] filePromise];
        
        if (item) {
            NSRect rect = [self imageRect];
            
            NSImage *dragImage = [NSImage bitmapImageWithSize:rect.size scale:[self backingScale] drawingHandler:^(NSRect dstRect){
                [imageCell drawInteriorWithFrame:dstRect inView:self];
            }];
            
            NSDraggingItem *dragItem = [[[NSDraggingItem alloc] initWithPasteboardWriter:item] autorelease];
            [dragItem setDraggingFrame:rect contents:dragImage];
            [self beginDraggingSessionWithItems:[NSArray arrayWithObjects:dragItem, nil] event:theEvent source:self];
        }
        
    } else {
        
        [super mouseDown:theEvent];
        
    }
}

- (void)copyPage:(id)sender {
    [[[self thumbnail] page] writeToClipboard];
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent {
    PDFPage *page = [[self thumbnail] page];
    NSMenu *menu = nil;
    if (page && [[page document] isLocked] == NO) {
        menu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
        [menu addItemWithTitle:NSLocalizedString(@"Copy", @"Menu item title") action:@selector(copyPage:) target:self];
    }
    return menu;
}

#pragma mark NSDraggingSource protocol

- (NSDragOperation)draggingSession:(NSDraggingSession *)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context {
    return context == NSDraggingContextWithinApplication ? NSDragOperationNone : NSDragOperationEvery;
}

- (void)draggingSession:(NSDraggingSession *)session
           endedAtPoint:(NSPoint)screenPoint
              operation:(NSDragOperation)operation {
    [[session draggingPasteboard] clearContents];
}

@end

