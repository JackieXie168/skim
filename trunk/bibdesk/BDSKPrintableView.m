//
//  BDSKPrintableView.m
//  Bibdesk
//
//  Created by Adam Maxwell on 09/02/05.
/*
 This software is Copyright (c) 2005,2006,2007
 Adam Maxwell. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 - Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 - Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in
 the documentation and/or other materials provided with the
 distribution.
 
 - Neither the name of Adam Maxwell nor the names of any
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

#import "BDSKPrintableView.h"
#import "BDSKFontManager.h"
#import "BibPrefController.h"

/* Most of this code was borrowed from TextEdit.  This is designed mainly to give a PDF data representation of plain or attributed text, as the AppKit provides no easy way to do this programmatically.  Page layout features have been overriden in order for better on-screen display, as the default margins from NSPrintInfo are too large for many cases; pass NO to initForScreenDisplay to get the default NSPrintInfo values (which are more appropriate for hard-copy results). */

@implementation BDSKPrintableView

- (id)initWithFrame:(NSRect)frameRect{
    OBASSERT_NOT_REACHED("This method is not the designated initializer for this class");
    return [self initForScreenDisplay:NO];
}

// designated initializer for this subclass
- (id)initForScreenDisplay:(BOOL)onScreen{
    if(self = ([super initWithFrame:NSZeroRect])){
        hasMultiplePages = NO;

        if(onScreen){
            [self setAllMargins:20.0];
        } else {
            // set up default margin struct using super's printInfo; we don't want to use printInfo for on-screen display in many cases, as it has a minimum margin of 72? pts
            margins.left = [printInfo leftMargin];
            margins.right = [printInfo rightMargin];
            margins.top = [printInfo topMargin];
            margins.bottom = [printInfo bottomMargin];
        }
        
        scrollView = [[NSScrollView alloc] init];
        clipView = [[NSClipView alloc] init];
        
        [self setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];    
        [clipView setDocumentView:self];
        
        [scrollView setContentView:clipView];
        [clipView release]; // retained by the scroll view
        
        textStorage = [[NSTextStorage alloc] initWithString:@""];
        NSLayoutManager *lm = [[NSLayoutManager alloc] init];
        [textStorage addLayoutManager:lm];
        [lm release]; // owned by the text storage
        [lm setDelegate:self];
        [self addPage];
        [self setTextColor:[NSColor blackColor]];
        [self setFont:[NSFont systemFontOfSize:[NSFont systemFontSize]]];
    }
    return self;
}

- (void)dealloc{
    [scrollView release];
    [textStorage release];
    [super dealloc];
}

- (NSLayoutManager *)layoutManager{
    return [[textStorage layoutManagers] objectAtIndex:0];
}

- (void)printInfoUpdated {
    unsigned cnt, numberOfPages = [self numberOfPages];
    NSArray *textContainers = [[self layoutManager] textContainers];
    
    [self setPrintInfo:printInfo];
    
    for (cnt = 0; cnt < numberOfPages; cnt++) {
        NSRect textFrame = [self documentRectForPageNumber:cnt];
        NSTextContainer *textContainer = [textContainers objectAtIndex:cnt];
        [textContainer setContainerSize:textFrame.size];
        [[textContainer textView] setFrame:textFrame];
    }
}

- (void)addPage {
    NSZone *zone = [self zone];
    unsigned numberOfPages = [self numberOfPages];
    NSSize textSize = [self documentSizeInPage];
    NSTextContainer *textContainer = [[NSTextContainer allocWithZone:zone] initWithContainerSize:textSize];
    NSTextView *textView;
    [self setNumberOfPages:numberOfPages + 1];
    textView = [[NSTextView allocWithZone:zone] initWithFrame:[self documentRectForPageNumber:numberOfPages] textContainer:textContainer];
    [textView setHorizontallyResizable:NO];
    [textView setVerticallyResizable:NO];
    [self addSubview:textView];
    [[self layoutManager] addTextContainer:textContainer];
    [textView release];
    [textContainer release];
}

- (void)removePage {
    unsigned numberOfPages = [self numberOfPages];
    NSArray *textContainers = [[self layoutManager] textContainers];
    NSTextContainer *lastContainer = [textContainers objectAtIndex:[textContainers count] - 1];
    [self setNumberOfPages:numberOfPages - 1];
    [[lastContainer textView] removeFromSuperview];
    [[lastContainer layoutManager] removeTextContainerAtIndex:[textContainers count] - 1];
}

- (void)setNumberOfPages:(unsigned int)pages{
    [super setNumberOfPages:pages];
    hasMultiplePages = (pages > 1);
}

- (void)layoutManager:(NSLayoutManager *)layoutManager didCompleteLayoutForTextContainer:(NSTextContainer *)textContainer atEnd:(BOOL)layoutFinishedFlag {

    NSArray *containers = [layoutManager textContainers];
    
    if (!layoutFinishedFlag || (textContainer == nil)) {
        // Either layout is not finished or it is but there are glyphs laid nowhere.
        NSTextContainer *lastContainer = [containers lastObject];
        
        if ((textContainer == lastContainer) || (textContainer == nil)) {
            // Add a new page if the newly full container is the last container or the nowhere container.
            // Do this only if there are glyphs laid in the last container (temporary solution for 3729692, until AppKit makes something better available.)
            if ([layoutManager glyphRangeForTextContainer:lastContainer].length > 0) [self addPage];
        }
    } else {
        // Layout is done and it all fit.  See if we can axe some pages.
        unsigned lastUsedContainerIndex = [containers indexOfObjectIdenticalTo:textContainer];
        unsigned numContainers = [containers count];
        while (++lastUsedContainerIndex < numContainers) {
            [self removePage];
        }
    }
}

- (void)setFont:(NSFont *)font{
    if(currentFont != font){
        [currentFont release];
        currentFont = [font retain];
        [textStorage addAttribute:NSFontAttributeName value:currentFont range:NSMakeRange(0, [textStorage length])];
    }
}

- (void)setTextColor:(NSColor *)color{
    if(currentColor != color){
        [currentColor release];
        currentColor = [color retain];
        [textStorage addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, [textStorage length])];
    }
}

- (void)forceLayoutBeforePrinting{
    // force layout before printing
    unsigned len;
    unsigned loc = INT_MAX;
    if (loc > 0 && (len = [textStorage length]) > 0) {
        NSRange glyphRange;
        if (loc >= len) loc = len - 1;
        /* Find out which glyph index the desired character index corresponds to */
        glyphRange = [[self layoutManager] glyphRangeForCharacterRange:NSMakeRange(loc, 1) actualCharacterRange:NULL];
        if (glyphRange.location > 0) {
            /* Now cause layout by asking a question which has to determine where the glyph is */
            (void)[[self layoutManager] textContainerForGlyphAtIndex:glyphRange.location - 1 effectiveRange:NULL];
        }
    }    
}

- (void)setString:(NSString *)aString{
    [textStorage beginEditing];
    [[textStorage mutableString] setString:aString];
    [textStorage addAttribute:NSFontAttributeName value:currentFont range:NSMakeRange(0, [textStorage length])];
    [textStorage addAttribute:NSForegroundColorAttributeName value:currentColor range:NSMakeRange(0, [textStorage length])];
	[textStorage endEditing];
    [self forceLayoutBeforePrinting];
}

- (void)setAttributedString:(NSAttributedString *)attrString{
    [textStorage beginEditing];
    [textStorage setAttributedString:attrString];
    [textStorage endEditing];
    [self forceLayoutBeforePrinting];
}

- (NSData *)PDFDataWithAttributedString:(NSAttributedString *)attrString{
    [self setAttributedString:attrString];
    return [self dataWithPDFInsideRect:[self bounds]];
}

- (NSData *)PDFDataWithString:(NSString *)aString{
    [self setString:aString];
    return [self dataWithPDFInsideRect:[self bounds]];
}

// sets all margins to a uniform inset
- (void)setAllMargins:(float)width{
    margins.left = width;
    margins.right = width;
    margins.top = width;
    margins.bottom = width;
    [self printInfoUpdated];
    [self setNeedsDisplay:YES];
}

- (NSSize)documentSizeInPage {
    NSSize paperSize = [printInfo paperSize];
    paperSize.width -= (margins.left + margins.right);
    paperSize.height -= (margins.top + margins.bottom);
    return paperSize;
}

- (NSRect)documentRectForPageNumber:(unsigned)pageNumber {	/* First page is page 0, of course! */
    NSRect rect = [self pageRectForPageNumber:pageNumber];
    rect.origin.x += margins.left;
    rect.origin.y += margins.top;
    rect.size = [self documentSizeInPage];
    return rect;
}

- (NSRect)pageRectForPageNumber:(unsigned)pageNumber {
    NSRect rect;
    rect.size = [printInfo paperSize];
    rect.origin = [self frame].origin;
    rect.origin.y += ((rect.size.height + [self pageSeparatorHeight]) * pageNumber);
    return rect;
}

@end