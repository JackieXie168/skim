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

static char SKPDFAnnotationPropertiesObservationContext;

@interface SKTextNoteEditor (SKPrivate)

- (void)updateFrame;
- (void)updateFont;
- (void)updateColor;
- (void)updateTextColor;
- (void)updateAlignment;

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
        [textField setStringValue:[annotation string]];
        [textField setDelegate:self];
        [self updateFont];
        [self updateColor];
        [self updateTextColor];
        [self updateAlignment];
        [annotation addObserver:self forKeyPath:SKNPDFAnnotationBoundsKey options:0 context:&SKPDFAnnotationPropertiesObservationContext];
        [annotation addObserver:self forKeyPath:SKNPDFAnnotationFontKey options:0 context:&SKPDFAnnotationPropertiesObservationContext];
        [annotation addObserver:self forKeyPath:SKNPDFAnnotationFontColorKey options:0 context:&SKPDFAnnotationPropertiesObservationContext];
        [annotation addObserver:self forKeyPath:SKNPDFAnnotationAlignmentKey options:0 context:&SKPDFAnnotationPropertiesObservationContext];
        [annotation addObserver:self forKeyPath:SKNPDFAnnotationColorKey options:0 context:&SKPDFAnnotationPropertiesObservationContext];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleScaleChangedNotification:) name:PDFViewScaleChangedNotification object:pdfView];
    }
    return self;
}

- (void)dealloc {
    @try {
        [annotation removeObserver:self forKeyPath:SKNPDFAnnotationBoundsKey];
        [annotation removeObserver:self forKeyPath:SKNPDFAnnotationFontKey];
        [annotation removeObserver:self forKeyPath:SKNPDFAnnotationFontColorKey];
        [annotation removeObserver:self forKeyPath:SKNPDFAnnotationAlignmentKey];
        [annotation removeObserver:self forKeyPath:SKNPDFAnnotationColorKey];
    }
    @catch(id e) {}
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
    font = [[NSFontManager sharedFontManager] convertFont:font toSize:[font pointSize] * [pdfView scaleFactor]];
    [textField setFont:font];
}

- (void)updateColor {
    NSColor *color = [annotation color];
    CGFloat alpha = [color alphaComponent];
    if (alpha < 1.0)
        color = [[NSColor controlBackgroundColor] blendedColorWithFraction:alpha ofColor:[color colorWithAlphaComponent:1.0]];
    [textField setBackgroundColor:color];
    // the field editor does not update the background color automatically, even as we set it explicitly, so we use this trick
    [[textField currentEditor] setDrawsBackground:NO];
    [[textField currentEditor] setDrawsBackground:YES];
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

- (void)layout {
    if (NSLocationInRange([annotation pageIndex], [pdfView displayedPageIndexRange])) {
        [self updateFrame];
        if ([textField superview] == nil) {
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
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
