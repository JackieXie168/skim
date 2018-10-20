//
//  SKThumbnailTableView.m
//  Skim
//
//  Created by Christiaan Hofman on 2/25/07.
/*
 This software is Copyright (c) 2007-2018
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

#import "SKThumbnailTableView.h"
#import "NSColor_SKExtensions.h"
#import "NSEvent_SKExtensions.h"

#define MAX_HIGHLIGHTS 5

@implementation SKThumbnailTableView

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (BOOL)hasHighlights {
    return [[self delegate] respondsToSelector:@selector(tableView:highlightLevelForRow:)] &&
    (RUNNING_BEFORE(10_10) || ([[self window] isKeyWindow] && [[self window] firstResponder] == self));
}

- (void)drawBackgroundInClipRect:(NSRect)clipRect {
    [super drawBackgroundInClipRect:clipRect];
    
    if ([self hasHighlights]) {
        NSRange range = [self rowsInRect:clipRect];
        NSUInteger row;
        NSColor *color = nil;
        
        for (row = range.location; row < NSMaxRange(range); row++) {
            if ([self isRowSelected:row])
                continue;
            
            NSUInteger level = [[self delegate] tableView:self highlightLevelForRow:row];
            if (level >= MAX_HIGHLIGHTS)
                continue;
            
            if (color == nil)
                color = [NSColor sourceListHighlightColorForView:self];
            if (color == nil)
                return;
            
            NSRect rect = NSIntersectionRect([self rectOfRow:row], [self rectOfColumn:0]);
            if (NSIntersectsRect(rect, clipRect)) {
                NSGradient *gradient = [[NSGradient alloc] initWithColors:[NSArray arrayWithObjects:[NSColor clearColor], [color  colorWithAlphaComponent:0.1 * (MAX_HIGHLIGHTS - level)], [NSColor clearColor], nil]];
                [gradient drawInRect:rect angle:0.0];
                [gradient release];
            }
        }
    }
}

- (void)selectRowIndexes:(NSIndexSet *)indexes byExtendingSelection:(BOOL)extendSelection {
    [super selectRowIndexes:indexes byExtendingSelection:extendSelection];
    if ([self hasHighlights])
        [self setNeedsDisplay:YES];
}

- (void)deselectRow:(NSInteger)row {
    [super deselectRow:row];
    if ([self hasHighlights])
        [self setNeedsDisplay:YES];
}

- (BOOL)becomeFirstResponder {
    if ([super becomeFirstResponder]) {
        if ([self hasHighlights])
            [self setNeedsDisplay:YES];
        return YES;
    }
    return NO;
}

- (BOOL)resignFirstResponder {
    if ([super resignFirstResponder]) {
        if ([self hasHighlights])
            [self setNeedsDisplay:YES];
        return YES;
    }
    return NO;
}

- (void)handleKeyOrMainStateChanged:(NSNotification *)note {
    if ([[self delegate] respondsToSelector:@selector(tableView:highlightLevelForRow:)])
        [self setNeedsDisplay:YES];
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow {
    NSWindow *oldWindow = [self window];
    NSArray *names = [NSArray arrayWithObjects:NSWindowDidBecomeMainNotification, NSWindowDidResignMainNotification, NSWindowDidBecomeKeyNotification, NSWindowDidResignKeyNotification, nil];
    if (oldWindow) {
        for (NSString *name in names)
            [[NSNotificationCenter defaultCenter] removeObserver:self name:name object:oldWindow];
    }
    if (newWindow) {
        for (NSString *name in names)
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyOrMainStateChanged:) name:name object:newWindow];
    }
    [super viewWillMoveToWindow:newWindow];
}

- (void)viewDidMoveToWindow {
    [super viewDidMoveToWindow];
    if ([self window])
        [self handleKeyOrMainStateChanged:nil];
}

- (void)mouseDown:(NSEvent *)theEvent {
    if (([theEvent modifierFlags] & NSCommandKeyMask) && [[self delegate] respondsToSelector:@selector(tableView:commandSelectRow:)]) {
        NSInteger row = [self rowAtPoint:[theEvent locationInView:self]];
        if (row != -1 && [[self delegate] tableView:self commandSelectRow:row])
            return;
    }
    [super mouseDown:theEvent];
}

- (id <SKThumbnailTableViewDelegate>)delegate { return (id <SKThumbnailTableViewDelegate>)[super delegate]; }
- (void)setDelegate:(id <SKThumbnailTableViewDelegate>)newDelegate { [super setDelegate:newDelegate]; }

@end
