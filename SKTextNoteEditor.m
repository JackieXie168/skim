//
//  SKTextNoteEditor.m
//  Skim
//
//  Created by Christiaan Hofman on 12/11/12.
/*
 This software is Copyright (c) 2012-2014
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
#import "SKTextNoteField.h"
#import "PDFView_SKExtensions.h"
#import "PDFAnnotation_SKExtensions.h"
#import "PDFPage_SKExtensions.h"
#import <SkimNotes/SkimNotes.h>

static char SKPDFAnnotationPropertiesObservationContext;

@interface SKTextNoteEditor (SKPrivate)

- (void)updateFrame;
- (void)updateFont;
- (void)updateColor;
- (void)updateTextColor;
- (void)updateAlignment;
- (void)updateBorder;
- (void)updateScaleFactor;

- (void)handleScaleChangedNotification:(NSNotification *)notification;
- (void)handlePageBoundsChangedNotification:(NSNotification *)notification;

@end

@implementation SKTextNoteEditor

@synthesize textField;

- (id)initWithPDFView:(PDFView *)aPDFView annotation:(PDFAnnotationFreeText *)anAnnotation {
    self = [super init];
    if (self) {
        pdfView = aPDFView;
        annotation = [anAnnotation retain];
        textField = [[SKTextNoteField alloc] init];
        [textField setBezeled:NO];
        [textField setBordered:NO];
        [textField setDrawsBackground:NO];
        [[textField cell] setFocusRingType:NSFocusRingTypeNone];
        [textField setDelegate:self];
        [textField setStringValue:[annotation string]];
        [self updateFont];
        [self updateColor];
        [self updateTextColor];
        [self updateAlignment];
        [self updateBorder];
        [self updateScaleFactor];
        for (NSString *key in [NSArray arrayWithObjects:SKNPDFAnnotationBoundsKey, SKNPDFAnnotationFontKey, SKNPDFAnnotationFontColorKey, SKNPDFAnnotationAlignmentKey, SKNPDFAnnotationColorKey, SKNPDFAnnotationBorderKey, nil])
            [annotation addObserver:self forKeyPath:key options:0 context:&SKPDFAnnotationPropertiesObservationContext];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleScaleChangedNotification:) name:PDFViewScaleChangedNotification object:pdfView];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePageBoundsChangedNotification:) name:SKPDFPageBoundsDidChangeNotification object:[pdfView document]];
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
    NSRect frame = [pdfView convertRect:NSIntegralRect([pdfView convertRect:[annotation bounds] fromPage:[annotation page]]) toView:[pdfView documentView]];
    [textField setFrame:frame];
    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_8) {
        frame.origin = NSZeroPoint;
        frame.size.width /= [pdfView scaleFactor];
        frame.size.height /= [pdfView scaleFactor];
        [textField setBounds:frame];
    }
}

- (void)updateFont {
    [textField setFont:[annotation font]];
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
        [[pdfView window] makeFirstResponder:nil];
    [textField setAlignment:[annotation alignment]];
    if (selection) {
        [[textField window] makeFirstResponder:textField];
        [(NSTextView *)[textField currentEditor] setSelectedRanges:selection];
    }
}

- (void)updateBorder {
    [[textField cell] setLineWidth:[annotation lineWidth]];
    [[textField cell] setDashPattern:[annotation borderStyle] == kPDFBorderStyleDashed ? [annotation dashPattern] : nil];
}

- (void)updateScaleFactor {
    [[textField cell] setScaleFactor:[pdfView scaleFactor]];
}

- (void)layout {
    if (NSLocationInRange([annotation pageIndex], [pdfView displayedPageIndexRange])) {
        [self updateFrame];
        if ([textField superview] == nil) {
            [[pdfView documentView] addSubview:textField];
            [[pdfView window] recalculateKeyViewLoop];
            if ([[[pdfView window] firstResponder] isEqual:pdfView])
                [textField selectText:nil];
            [annotation setShouldDisplay:NO];
        }
    } else if ([textField superview]) {
        BOOL wasFirstResponder = ([textField currentEditor] != nil);
        [annotation setShouldDisplay:[annotation shouldPrint]];
        [textField removeFromSuperview];
        [[pdfView window] recalculateKeyViewLoop];
        if (wasFirstResponder)
            [[pdfView window] makeFirstResponder:pdfView];
    }
}

- (void)discardEditing {
    [annotation setShouldDisplay:[annotation shouldPrint]];
    
    [textField abortEditing];
    [textField removeFromSuperview];
    [[pdfView window] recalculateKeyViewLoop];
    
    if ([pdfView respondsToSelector:@selector(textNoteEditorDidEndEditing:)])
        [pdfView textNoteEditorDidEndEditing:self];
}

- (BOOL)commitEditing {
    [annotation setShouldDisplay:[annotation shouldPrint]];
    
    BOOL wasFirstResponder = ([textField currentEditor] != nil);
    if (wasFirstResponder && [[textField window] makeFirstResponder:nil] == NO)
        return NO;
    
    NSString *newValue = [textField stringValue];
    if ([newValue isEqualToString:[annotation string]] == NO)
        [annotation setString:newValue];
    
    [textField removeFromSuperview];
    [[pdfView window] recalculateKeyViewLoop];
    
    if (wasFirstResponder)
        [[pdfView window] makeFirstResponder:pdfView];
    
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
    [self updateScaleFactor];
}

- (void)handlePageBoundsChangedNotification:(NSNotification *)notification  {
    [self updateFrame];
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
