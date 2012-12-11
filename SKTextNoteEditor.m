//
//  SKTextNoteEditor.m
//  Skim
//
//  Created by Christiaan Hofman on 12/11/12.
/*
 This software is Copyright (c) 2012
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
#import <SkimNotes/SkimNotes.h>


@implementation SKTextNoteEditor

@synthesize textField;

- (id)initWithPDFView:(PDFView *)aPDFView annotation:(PDFAnnotationFreeText *)anAnnotation {
    self = [super init];
    if (self) {
        pdfView = aPDFView;
        annotation = [anAnnotation retain];
        NSColor *color = [annotation color];
        NSColor *fontColor = [annotation fontColor];
        CGFloat alpha = [color alphaComponent];
        if (alpha < 1.0)
            color = [[NSColor controlBackgroundColor] blendedColorWithFraction:alpha ofColor:[color colorWithAlphaComponent:1.0]];
        textField = [[NSTextField alloc] init];
        [textField setBackgroundColor:color];
        [textField setTextColor:fontColor];
        [textField setAlignment:[annotation alignment]];
        [textField setStringValue:[annotation string]];
        [textField setDelegate:self];
        [self updateFont];
        [self updateFrame];
    }
    return self;
}

- (void)dealloc {
    pdfView = nil;
    SKDESTROY(annotation);
    SKDESTROY(textField);
    [super dealloc];
}

- (void)updateFont {
    NSFont *font = [annotation font];
    font = [[NSFontManager sharedFontManager] convertFont:font toSize:[font pointSize] * [pdfView scaleFactor]];
    [textField setFont:font];
}

- (void)updateFrame {
    NSRect frame = [pdfView convertRect:[annotation bounds] toDocumentViewFromPage:[annotation page]];
    [textField setFrame:frame];
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)command {
    if (command == @selector(insertNewline:) || command == @selector(insertTab:) || command == @selector(insertBacktab:)) {
        [pdfView commitEditing];
        [[pdfView window] makeFirstResponder:pdfView];
        return YES;
    }
    return NO;
}

@end
