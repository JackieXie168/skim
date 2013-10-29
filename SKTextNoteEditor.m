//
//  SKTextNoteEditor.m
//  Skim
//
//  Created by Christiaan Hofman on 12/11/12.
/*
 This software is Copyright (c) 2012-2013
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
#import <SkimNotes/SkimNotes.h>
#import "NSColor_SKExtensions.h"
#import "NSBezierPath_SKExtensions.h"

static char SKPDFAnnotationPropertiesObservationContext;

@interface SKTextNoteFieldCell : NSTextFieldCell {
    CGFloat highlightWidth;
    CGFloat lineWidth;
    NSArray *dashPattern;
}
@property (nonatomic) CGFloat highlightWidth;
@property (nonatomic) CGFloat lineWidth;
@property (nonatomic, copy) NSArray *dashPattern;
@end

#pragma mark -

@interface SKTextNoteEditor (SKPrivate)

- (void)updateFrame;
- (void)updateFont;
- (void)updateColor;
- (void)updateTextColor;
- (void)updateAlignment;
- (void)updateBorder;
- (void)updateHighlight;

- (void)handleScaleChangedNotification:(NSNotification *)notification;

@end

@implementation SKTextNoteEditor

@synthesize textField;

- (id)initWithPDFView:(PDFView *)aPDFView annotation:(PDFAnnotationFreeText *)anAnnotation {
    self = [super init];
    if (self) {
        pdfView = aPDFView;
        annotation = [anAnnotation retain];
        textField = [[NSTextField alloc] init];
        [textField setCell:[[[SKTextNoteFieldCell alloc] initTextCell:[annotation string]] autorelease]];
        [textField setDelegate:self];
        [self updateFont];
        [self updateColor];
        [self updateTextColor];
        [self updateAlignment];
        [self updateBorder];
        [self updateHighlight];
        for (NSString *key in [NSArray arrayWithObjects:SKNPDFAnnotationBoundsKey, SKNPDFAnnotationFontKey, SKNPDFAnnotationFontColorKey, SKNPDFAnnotationAlignmentKey, SKNPDFAnnotationColorKey, SKNPDFAnnotationBorderKey, nil])
            [annotation addObserver:self forKeyPath:key options:0 context:&SKPDFAnnotationPropertiesObservationContext];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleScaleChangedNotification:) name:PDFViewScaleChangedNotification object:pdfView];
    }
    return self;
}

- (void)dealloc {
    for (NSString *key in [NSArray arrayWithObjects:SKNPDFAnnotationBoundsKey, SKNPDFAnnotationFontKey, SKNPDFAnnotationFontColorKey, SKNPDFAnnotationAlignmentKey, SKNPDFAnnotationColorKey, SKNPDFAnnotationBorderKey, nil]) {
        @try { [annotation removeObserver:self forKeyPath:key]; }
        @catch(id e) {}
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    pdfView = nil;
    SKDESTROY(annotation);
    SKDESTROY(textField);
    [super dealloc];
}

- (void)updateFrame {
    NSRect frame = [pdfView convertRect:[annotation bounds] toDocumentViewFromPage:[annotation page]];
    [textField setFrame:frame];
}

- (void)updateFont {
    NSFont *font = [annotation font];
    // Mavericks scales the whole text field, including the font, which it really shouldn't do
    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_8)
        font = [[NSFontManager sharedFontManager] convertFont:font toSize:[font pointSize] * [pdfView scaleFactor]];
    [textField setFont:font];
}

- (void)updateColor {
    [textField setBackgroundColor:[annotation color]];
}

- (void)updateTextColor {
    [textField setTextColor:[annotation fontColor]];
    // the text color is not synchronized automatically so we have to set it explicitly on the field editor
    [[textField currentEditor] setTextColor:[annotation fontColor]];
}

- (void)updateAlignment {
    // updating the alignment while editing does not work, alignment is not changed and the field editor is lost
    NSArray *selection = [(NSTextView *)[textField currentEditor] selectedRanges];
    if (selection)
        [[pdfView window] makeFirstResponder:pdfView];
    [textField setAlignment:[annotation alignment]];
    if (selection) {
        [[textField window] makeFirstResponder:textField];
        [(NSTextView *)[textField currentEditor] setSelectedRanges:selection];
    }
}

- (void)updateBorder {
    CGFloat lineWidth = [annotation lineWidth];
    NSArray *dashPattern = [annotation dashPattern];
    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_8) {
        lineWidth /= [pdfView scaleFactor];
        if ([dashPattern count] > 0) {
            NSMutableArray *tmpPattern = [NSMutableArray array];
            for (NSNumber *number in dashPattern)
                [tmpPattern addObject:[NSNumber numberWithDouble:[number doubleValue] / [pdfView scaleFactor]]];
        }
    }
    [[textField cell] setLineWidth:lineWidth];
    [[textField cell] setDashPattern:dashPattern];
}

- (void)updateHighlight {
    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_8)
        [[textField cell] setHighlightWidth:1.0 / [pdfView scaleFactor]];
}

- (void)layout {
    if (NSLocationInRange([annotation pageIndex], [pdfView displayedPageIndexRange])) {
        [self updateFrame];
        if ([textField superview] == nil) {
            [annotation setShouldDisplay:NO];
            [[pdfView documentView] addSubview:textField];
            if ([[[pdfView window] firstResponder] isEqual:pdfView])
                [textField selectText:nil];
        }
    } else if ([textField superview]) {
        BOOL wasFirstResponder = ([textField currentEditor] != nil);
        [textField removeFromSuperview];
        if (wasFirstResponder)
            [[pdfView window] makeFirstResponder:pdfView];
    }
}

- (void)discardEditing {
    [textField abortEditing];
    [textField removeFromSuperview];
    
    [annotation setShouldDisplay:[annotation shouldPrint]];
    
    if ([pdfView respondsToSelector:@selector(textNoteEditorDidEndEditing:)])
        [pdfView textNoteEditorDidEndEditing:self];
}

- (BOOL)commitEditing {
    if ([textField currentEditor] && [[pdfView window] makeFirstResponder:pdfView] == NO)
        return NO;
    
    NSString *newValue = [textField stringValue];
    if ([newValue isEqualToString:[annotation string]] == NO)
        [annotation setString:newValue];
    
    [textField removeFromSuperview];
    
    [annotation setShouldDisplay:[annotation shouldPrint]];
    
    if ([pdfView respondsToSelector:@selector(textNoteEditorDidEndEditing:)])
        [pdfView textNoteEditorDidEndEditing:self];
    
    return YES;
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)command {
    if (command == @selector(insertNewline:) || command == @selector(insertTab:) || command == @selector(insertBacktab:)) {
        [self commitEditing];
        return YES;
    }
    return NO;
}

- (void)handleScaleChangedNotification:(NSNotification *)notification  {
    [self updateFrame];
    [self updateFont];
    [self updateBorder];
    [self updateHighlight];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == &SKPDFAnnotationPropertiesObservationContext) {
        if ([keyPath isEqualToString:SKNPDFAnnotationBoundsKey])
            [self updateFrame];
        else if ([keyPath isEqualToString:SKNPDFAnnotationFontKey])
            [self updateFont];
        else if ([keyPath isEqualToString:SKNPDFAnnotationColorKey])
            [self updateColor];
        else if ([keyPath isEqualToString:SKNPDFAnnotationFontColorKey])
            [self updateTextColor];
        else if ([keyPath isEqualToString:SKNPDFAnnotationAlignmentKey])
            [self updateAlignment];
        else if ([keyPath isEqualToString:SKNPDFAnnotationBorderKey])
            [self updateBorder];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end

#pragma mark -

@implementation SKTextNoteFieldCell

@synthesize highlightWidth, lineWidth, dashPattern;

- (id)initTextCell:(NSString *)aString {
    self = [super initTextCell:aString];
    if (self) {
        highlightWidth = 1.0;
        lineWidth = 0.0;
        dashPattern = nil;
        [self setEditable:YES];
        [self setFocusRingType:NSFocusRingTypeNone];
    }
    return self;
}

- (void)setHighlightWidth:(CGFloat)newHighlightWidth {
    highlightWidth = newHighlightWidth;
    [(NSControl *)[self controlView] updateCell:self];
}

- (void)setLineWidth:(CGFloat)newLineWidth {
    lineWidth = newLineWidth;
    [(NSControl *)[self controlView] updateCell:self];
}

- (void)setDashPattern:(NSArray *)newDashPattern {
    if (dashPattern != newDashPattern) {
        [dashPattern release];
        dashPattern = [newDashPattern copy];
        [(NSControl *)[self controlView] updateCell:self];
    }
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    [NSGraphicsContext saveGraphicsState];
    
    [[self backgroundColor] setFill];
    [NSBezierPath fillRect:cellFrame];
    
    if ([self lineWidth] > 0.0) {
        NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSInsetRect(cellFrame, 0.5 * [self lineWidth], 0.5 * [self lineWidth])];
        [path setLineWidth:[self lineWidth]];
        [path setDashPattern:[self dashPattern]];
        [[NSColor blackColor] setStroke];
        [path stroke];
    }
    
    [[self showsFirstResponder] ? [NSColor selectionHighlightColor] : [NSColor disabledSelectionHighlightColor] setFill];
    NSFrameRectWithWidth(cellFrame, [self highlightWidth]);
    
    [NSGraphicsContext restoreGraphicsState];
    
    [super drawWithFrame:cellFrame inView:controlView];
}

@end
