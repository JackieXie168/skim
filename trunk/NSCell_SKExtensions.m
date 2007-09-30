//
//  NSCell_SKExtensions.h
//  Skim
//
//  Created by Christiaan Hofman on 9/4/07.
//  Copyright 2007 Christiaan Hofman. All rights reserved.
//
/*
 This software is Copyright (c) 2007
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

#import "NSCell_SKExtensions.h"
#import "OBUtilities.h"
#import "SKPDFView.h"


@implementation NSCell (SKExtensions)

static IMP originalHighlightColorWithFrameInView = NULL;

+ (void)load {
    originalHighlightColorWithFrameInView = OBReplaceMethodImplementationWithSelector(self, @selector(highlightColorWithFrame:inView:), @selector(replacementHighlightColorWithFrame:inView:));
}

- (NSColor *)replacementHighlightColorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    if ([controlView respondsToSelector:@selector(highlightColor)])
        return [(id)controlView highlightColor];
    else
        return originalHighlightColorWithFrameInView(self, _cmd, cellFrame, controlView);
}

@end


@implementation NSTextFieldCell (SKExtensions)

static IMP originalSetUpFieldEditorAttributes = NULL;

+ (void)load {
    originalSetUpFieldEditorAttributes = OBReplaceMethodImplementationWithSelector(self, @selector(setUpFieldEditorAttributes:), @selector(replacementSetUpFieldEditorAttributes:));
}

- (NSText *)replacementSetUpFieldEditorAttributes:(NSText *)textObj {
    textObj = originalSetUpFieldEditorAttributes(self, _cmd, textObj);
    if ([textObj respondsToSelector:@selector(setBackgroundColor:)] && [[self controlView] respondsToSelector:@selector(setBackgroundColor:)] && [[self controlView] respondsToSelector:@selector(delegate)]) {
        id delegate = [(NSTextField *)[self controlView] delegate];
        if ([delegate respondsToSelector:@selector(control:backgroundColorForFieldEditor:)]) {
            NSColor *color = [delegate control:(NSTextField *)[self controlView] backgroundColorForFieldEditor:textObj];
            if (color) {
                [(NSTextField *)[self controlView] setBackgroundColor:color];
                [(NSTextView *)textObj setBackgroundColor:color];
            }
        }
    }
    return textObj;
}

@end


@implementation NSTextField (SKExtensions)

static IMP originalSetDelegate = NULL;

+ (void)load {
    originalSetDelegate = OBReplaceMethodImplementationWithSelector(self, @selector(setDelegate:), @selector(replacementSetDelegate:));
}

- (void)replacementSetDelegate:(id)delegate {
    originalSetDelegate(self, _cmd, delegate);
    NSText *currentEditor = [self currentEditor];
    if (currentEditor && [currentEditor respondsToSelector:@selector(setBackgroundColor:)] && [delegate respondsToSelector:@selector(control:backgroundColorForFieldEditor:)]) {
        NSColor *color = [delegate control:self backgroundColorForFieldEditor:currentEditor];
        if (color) {
            [(NSTextField *)self setBackgroundColor:color];
            [(NSTextView *)currentEditor setBackgroundColor:color];
        }
    }
}

@end
