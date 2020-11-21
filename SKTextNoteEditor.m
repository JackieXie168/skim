//
//  SKTextNoteEditor.m
//  Skim
//
//  Created by Christiaan Hofman on 12/11/12.
/*
 This software is Copyright (c) 2012-2020
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

#import "SKTextNoteEditor.h"
#import "PDFView_SKExtensions.h"
#import "PDFAnnotation_SKExtensions.h"
#import "PDFPage_SKExtensions.h"
#import "NSView_SKExtensions.h"
#import "NSGraphics_SKExtensions.h"
#import "NSEvent_SKExtensions.h"
#import <SkimNotes/SkimNotes.h>

static char SKPDFAnnotationPropertiesObservationContext;

@interface SKTextNoteTextView : NSTextView
@end

#pragma mark -

@implementation SKTextNoteEditor

@dynamic currentString;

+ (NSArray *)keysToObserve {
    return [NSArray arrayWithObjects:SKNPDFAnnotationBoundsKey, SKNPDFAnnotationFontKey, SKNPDFAnnotationFontColorKey, SKNPDFAnnotationAlignmentKey, SKNPDFAnnotationColorKey, SKNPDFAnnotationBorderKey, SKNPDFAnnotationStringKey, nil];
}

- (id)initWithPDFView:(PDFView *)aPDFView annotation:(PDFAnnotationFreeText *)anAnnotation {
    self = [super initWithFrame:[annotation bounds]];
    if (self) {
        pdfView = aPDFView;
        annotation = [anAnnotation retain];
        
        for (NSString *key in [[self class] keysToObserve])
            [annotation addObserver:self forKeyPath:key options:0 context:&SKPDFAnnotationPropertiesObservationContext];
        
        SKSetHasLightAppearance(self);
    }
    return self;
}

- (void)dealloc {
    if (annotation)
        SKENSURE_MAIN_THREAD(
            for (NSString *key in [[self class] keysToObserve]) {
                @try { [annotation removeObserver:self forKeyPath:key]; }
                @catch(id e) {}
            }
        );
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    pdfView = nil;
    SKDESTROY(annotation);
    SKDESTROY(textView);
    [super dealloc];
}

- (NSString *)currentString {
    return [textView string] ?: [annotation string];
}

- (void)updateFrame:(NSNotification *)note {
    NSRect frame = [pdfView backingAlignedRect:[pdfView convertRect:[annotation bounds] fromPage:[annotation page]] options:NSAlignAllEdgesNearest];
    frame = [pdfView convertRect:frame toView:[pdfView documentView]];
    [self setFrame:frame];
}

- (void)updateParagraphStyle {
    NSFont *font = [annotation font];
    NSMutableParagraphStyle *parStyle = [[NSMutableParagraphStyle alloc] init];
    CGFloat descent = -[font descender];
    CGFloat lineHeight = ceil([font ascender]) + ceil(descent);
    [parStyle setLineBreakMode:NSLineBreakByWordWrapping];
    [parStyle setLineSpacing:-[font leading]];
    [parStyle setMinimumLineHeight:lineHeight];
    [parStyle setMaximumLineHeight:lineHeight];
    [parStyle setAlignment:[annotation alignment]];
    NSMutableDictionary *typingAttrs = [[textView typingAttributes] mutableCopy];
    [typingAttrs setObject:parStyle forKey:NSParagraphStyleAttributeName];
    [textView setDefaultParagraphStyle:parStyle];
    [[textView textStorage] addAttribute:NSParagraphStyleAttributeName value:parStyle range:NSMakeRange(0, [[textView string] length])];
    [textView setTypingAttributes:typingAttrs];
    if (RUNNING_AFTER(10_13))
        [textView setTextContainerInset:NSMakeSize(0.0, 3.0 + round(descent) - descent)];
    [parStyle release];
    [typingAttrs release];
}

- (void)setUpTextView {
    if (textView)
        return;
    
    textView  = [[SKTextNoteTextView alloc] initWithFrame:[self bounds]];
    [textView setRichText:NO];
    [textView setDrawsBackground:NO];
    [textView setFocusRingType:NSFocusRingTypeNone];
    [textView setHorizontallyResizable:NO];
    [textView setVerticallyResizable:YES];
    [textView setAutoresizingMask:NSViewWidthSizable];
    [textView setUsesFontPanel:NO];
    [textView setDelegate:self];
    [textView setString:[annotation string] ?: @""];
    [textView setFont:[annotation font]];
    [textView setTextColor:[annotation fontColor]];
    [textView setAlignment:[annotation alignment]];
    [[textView textContainer] setContainerSize:NSMakeSize(NSWidth([self bounds]), CGFLOAT_MAX)];
    [[textView textContainer] setWidthTracksTextView:YES];
    [[textView textContainer] setLineFragmentPadding:2.0];
    if (RUNNING_AFTER(10_13))
        [textView setTextContainerInset:NSMakeSize(0.0, 3.0)];
    [textView setSelectedRange:NSMakeRange(0, 0)];
    NSClipView *clipView = [[[NSClipView alloc] initWithFrame:[self bounds]] autorelease];
    [clipView setDrawsBackground:NO];
    [clipView setDocumentView:textView];
    [clipView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [self addSubview:clipView];
    
    [self updateParagraphStyle];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateFrame:) name:PDFViewScaleChangedNotification object:pdfView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateFrame:) name:SKPDFPageBoundsDidChangeNotification object:[pdfView document]];
}

- (void)endEditingWithCommit:(BOOL)commit {
    for (NSString *key in [[self class] keysToObserve])
        [annotation removeObserver:self forKeyPath:key];
    
    if (commit) {
        NSString *newValue = [textView string] ?: @"";
        if (textView && [newValue isEqualToString:[annotation string] ?: @""] == NO)
            [annotation setString:newValue];
    }
    
    [annotation setShouldDisplay:[annotation shouldPrint]];
    
    SKDESTROY(annotation);
    
    // avoid getting textDidEndDelegate: messages
    [textView setDelegate:nil];
    
    if ([self superview]) {
        BOOL wasFirstResponder = (textView && [[pdfView window] firstResponder] == textView);
        [self removeFromSuperview];
        [[pdfView window] recalculateKeyViewLoop];
        if (wasFirstResponder)
            [[pdfView window] makeFirstResponder:pdfView];
    }
    
    PDFView *thePdfView = pdfView;
    pdfView = nil;
    
    if ([thePdfView respondsToSelector:@selector(textNoteEditorDidEndEditing:)])
        [thePdfView textNoteEditorDidEndEditing:self];
}

- (void)layoutWithEvent:(NSEvent *)event {
    if ([pdfView isPageAtIndexDisplayed:[annotation pageIndex]]) {
        [self setUpTextView];
        [self updateFrame:nil];
        if ([self superview] == nil) {
            [[pdfView documentView] addSubview:self];
            [[pdfView window] recalculateKeyViewLoop];
            [textView scrollPoint:NSZeroPoint];
            if (event) {
                [[textView window] makeFirstResponder:textView];
                [textView mouseDown:event];
            } else if ([[[pdfView window] firstResponder] isEqual:pdfView]) {
                NSRange range = NSMakeRange(0, [[textView string] length]);
                [textView setSelectedRange:range];
                [[textView window] makeFirstResponder:textView];
            }
            [annotation setShouldDisplay:NO];
        }
    } else {
        [self endEditingWithCommit:YES];
    }
}

- (void)discardEditing {
    [self endEditingWithCommit:NO];
}

- (BOOL)commitEditing {
    [self endEditingWithCommit:YES];
    return YES;
}

- (BOOL)textView:(NSTextView *)aTextView doCommandBySelector:(SEL)command {
    if (command == @selector(insertTab:)) {
        [self endEditingWithCommit:YES];
        return YES;
    } else if (command == @selector(cancelOperation:)) {
        [self endEditingWithCommit:NO];
        return YES;
    }
    return NO;
}

- (void)textDidEndEditing:(NSNotification *)notification {
    [self endEditingWithCommit:YES];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == &SKPDFAnnotationPropertiesObservationContext) {
        if ([keyPath isEqualToString:SKNPDFAnnotationBoundsKey]) {
            [self updateFrame:nil];
        } else if ([keyPath isEqualToString:SKNPDFAnnotationFontKey]) {
            [textView setFont:[annotation font]];
            [self updateParagraphStyle];
        } else if ([keyPath isEqualToString:SKNPDFAnnotationFontColorKey]) {
            [textView setTextColor:[annotation fontColor]];
        } else if ([keyPath isEqualToString:SKNPDFAnnotationAlignmentKey]) {
            [textView setAlignment:[annotation alignment]];
            [self updateParagraphStyle];
        } else if ([keyPath isEqualToString:SKNPDFAnnotationStringKey]) {
            [textView setString:[annotation string] ?: @""];
        } else if ([keyPath isEqualToString:SKNPDFAnnotationColorKey] || [keyPath isEqualToString:SKNPDFAnnotationBorderKey]) {
            [self setNeedsDisplay:YES];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)drawRect:(NSRect)dirtyRect {
    NSRect bounds = [self bounds];
    NSColor *color = [annotation color];
    
    [NSGraphicsContext saveGraphicsState];
    
    if ((RUNNING(10_13) || RUNNING(10_14)) && (color == nil || [color alphaComponent] < 1.0)) {
        [[PDFView defaultPageBackgroundColor] setFill];
        [NSBezierPath fillRect:bounds];
    }
    
    if (color) {
        [color setFill];
        [NSBezierPath fillRect:bounds];
    }
    
    CGFloat width = [annotation lineWidth];
    if (width > 0.0) {
        CGFloat scale = [self convertSizeFromBacking:NSMakeSize(1.0, 1.0)].width;
        width *= scale;
        NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSInsetRect(bounds, 0.5 * width, 0.5 * width)];
        if ([annotation borderStyle] == kPDFBorderStyleDashed && RUNNING_BEFORE(10_12)) {
            NSArray *dashPattern = [annotation dashPattern];
            NSUInteger count = [dashPattern count];
            if (count > 0) {
                NSUInteger i;
                CGFloat pattern[count];
                for (i = 0; i < count; i++)
                    pattern[i] = scale * [[dashPattern objectAtIndex:i] doubleValue];
                [path setLineDash:pattern count:count phase:0.0];
            }
        }
        [path setLineWidth:width];
        [[NSColor blackColor] setStroke];
        [path stroke];
    }
    
    [NSGraphicsContext restoreGraphicsState];
}

@end

#pragma mark -

@implementation SKTextNoteTextView

- (BOOL)respondsToSelector:(SEL)aSelector {
    if (aSelector == @selector(changeFont:) || aSelector == @selector(changeAttributes:) || aSelector == @selector(changeColor:) || aSelector == @selector(alignLeft:) || aSelector == @selector(alignRight:) || aSelector == @selector(alignCenter:))
        return NO;
    return [super respondsToSelector:aSelector];
}

- (void)keyDown:(NSEvent *)theEvent {
    unichar eventChar = [theEvent firstCharacter];
    NSUInteger modifiers = [theEvent standardModifierFlags];
    if ((eventChar == '=' && (modifiers & ~(NSAlternateKeyMask | NSShiftKeyMask)) == NSControlKeyMask) || ((eventChar == NSUpArrowFunctionKey || eventChar == NSDownArrowFunctionKey || eventChar == NSLeftArrowFunctionKey || eventChar == NSRightArrowFunctionKey) && (modifiers == (NSAlternateKeyMask | NSControlKeyMask) || modifiers == (NSShiftKeyMask | NSControlKeyMask))))
        [[self nextResponder] keyDown:theEvent];
    else
        [super keyDown:theEvent];
}

@end
