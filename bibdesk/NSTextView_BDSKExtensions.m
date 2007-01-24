//  NSTextView_BDSKExtensions.m

//  Created by Michael McCracken on Thu Jul 18 2002.
/*
 This software is Copyright (c) 2002,2003,2004,2005,2006,2007
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

#import "NSTextView_BDSKExtensions.h"
#import "BibPrefController.h"
#import <OmniFoundation/OmniFoundation.h>
#import "BDSKTextViewFindController.h"
#import <OmniAppKit/OAApplication.h>
#import "NSObject_BDSKExtensions.h"

@implementation NSTextView (BDSKExtensions)

static BDSKTextViewFindController *findController = nil;

- (IBAction)performFindPanelAction:(id)sender{
    if (findController == nil)
        findController = [[BDSKTextViewFindController alloc] init];
	[findController performFindPanelAction:sender];
}

// flag changes during a drag are not forwarded to the application, so we fix that at the end of the drag
- (void)draggedImage:(NSImage *)anImage endedAt:(NSPoint)aPoint operation:(NSDragOperation)operation{
    // there is not original implementation
    [[NSNotificationCenter defaultCenter] postNotificationName:OAFlagsChangedNotification object:[NSApp currentEvent]];
}

- (void)selectLineNumber:(int) line;
{
    int i;
    NSString *string;
    unsigned start;
    unsigned end;
    NSRange myRange;

    string = [self string];
    
    myRange.location = 0;
    myRange.length = 0; // use zero length range so getLineStart: doesn't raise an exception if we're looking for the last line
    for (i = 1; i <= line; i++) {
        [string getLineStart:&start
                       end:&end
               contentsEnd:NULL
                  forRange:myRange];
        myRange.location = end;
    }
    myRange.location = start;
    myRange.length = (end - start);
    [self setSelectedRange:myRange];
    [self scrollRangeToVisible:myRange];
}

// allows persistent spell checking in text views

- (void)toggleContinuousSpellChecking:(id)sender{
    BOOL state = ![[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKEditorShouldCheckSpellingContinuouslyKey];
    [sender setState:state];
    [[OFPreferenceWrapper sharedPreferenceWrapper] setBool:state forKey:BDSKEditorShouldCheckSpellingContinuouslyKey];
}

- (BOOL)isContinuousSpellCheckingEnabled{
    return [[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKEditorShouldCheckSpellingContinuouslyKey];
}

- (void)highlightComponentsOfSearchString:(NSString *)searchString;
{
    NSParameterAssert(searchString != nil);
    NSTextStorage *textStorage = [self textStorage];
    NSMutableArray *allSearchComponents = [NSMutableArray array];
    NSArray *searchComponents = [searchString searchComponents];
    
    [allSearchComponents performSelector:@selector(addObjectsFromArray:) withObjectsFromArray:searchComponents];

    [textStorage beginEditing];
    [self performSelector:@selector(highlightOccurrencesOfString:) withObjectsFromArray:allSearchComponents];
    [textStorage endEditing];
}

- (void)highlightOccurrencesOfString:(NSString *)substring;
{
    NSParameterAssert(substring != nil);
    NSString *string = [self string];
    NSTextStorage *textStorage = [self textStorage];
    NSRange range = [string rangeOfString:substring options:NSCaseInsensitiveSearch];
    unsigned int maxRangeLoc;
    unsigned int length = [string length];
    
    // Mail.app appears to use a light gray highlight, which is rather ugly, but we don't want to use the selected text highlight
    static NSDictionary *highlightAttributes = nil;
    if(highlightAttributes == nil)
        highlightAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:[NSColor lightGrayColor], NSBackgroundColorAttributeName, nil];
    
    // use the layout manager to add temporary attributes; the advantage for our purpose is that temporary attributes don't print
    NSLayoutManager *layoutManager = [self layoutManager];
    OBPRECONDITION(layoutManager);
    if(layoutManager == nil)
        return;
    
    // docs say we can nest beginEditing/endEditing messages, so we'll make sure the changes are processed in a batch
    [textStorage beginEditing];
    while(range.location != NSNotFound){
        
        [layoutManager addTemporaryAttributes:highlightAttributes forCharacterRange:range];        
        maxRangeLoc = NSMaxRange(range);
        range = [string rangeOfString:substring options:NSCaseInsensitiveSearch range:NSMakeRange(maxRangeLoc, length - maxRangeLoc)];
    }
    [textStorage endEditing];
}

- (IBAction)invertSelection:(id)sender;
{
    // Note the guarantees in the header for -selectedRanges and requirements for setSelectedRanges:
    NSArray *ranges = [self selectedRanges];
    NSMutableArray *newRanges = [NSMutableArray array];
    unsigned i, iMax = [ranges count];
    
    // this represents the entire string
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [[self string] length])];
    
    // remove current selections
    for (i = 0; i < iMax; i++) {
        [indexes removeIndexesInRange:[[ranges objectAtIndex:i] rangeValue]];
    }
    
    i = [indexes firstIndex];
    if (NSNotFound == i) {
        // nothing to select (select all, then choose to invert)
        [newRanges addObject:[NSValue valueWithRange:NSMakeRange(0, 0)]];
    } else {
        
        unsigned start, next;
        start = i;
        
        while (NSNotFound != i) {
            next = [indexes indexGreaterThanIndex:i];
            // a discontinuity in the sequence indicates the start of a new range
            if (NSNotFound == next || next != (i + 1)) {
                [newRanges addObject:[NSValue valueWithRange:NSMakeRange(start, i - start + 1)]];
                start = next;
            }
            i = next;
        }
    }
    
    [self setSelectedRanges:newRanges];
}

- (NSPoint)locationForCompletionWindow;
{
    // give our delegate (and possibly its delegate) a chance to override this
    if([[self delegate] respondsToSelector:@selector(locationForCompletionWindowInTextView:)])
        return [[self delegate] locationForCompletionWindowInTextView:self];
    else if([[self delegate] respondsToSelector:@selector(delegate)]){
        id controlDelegate = [[self delegate] delegate];  // e.g. delegate of NSTextField
        if([controlDelegate respondsToSelector:@selector(control:locationForCompletionWindowInTextView:)])
            return [controlDelegate control:[self delegate] locationForCompletionWindowInTextView:self];
    }
    
    NSPoint point = NSZeroPoint;
    
    NSRange selRange = [self rangeForUserCompletion];

    // @@ hack: if there is no character at this point (it may be just an accent), our line fragment rect will not be accurate for what we really need, so returning NSZeroPoint indicates to the caller that this is invalid
    if(selRange.length == 0 || selRange.location == NSNotFound)
        return point;
    
    NSLayoutManager *layoutManager = [self layoutManager];
    
    // get the rect for the first glyph in our affected range
    NSRange glyphRange = [layoutManager glyphRangeForCharacterRange:selRange actualCharacterRange:NULL];
    NSRect rect = NSZeroRect;

    // check length, or the layout manager will raise an exception
    if(glyphRange.length > 0){
        rect = [layoutManager lineFragmentRectForGlyphAtIndex:glyphRange.location effectiveRange:NULL];
        point = rect.origin;

        // the above gives the rect for the full line
        NSPoint glyphLoc = [layoutManager locationForGlyphAtIndex:glyphRange.location];
        point.x += glyphLoc.x;
        // don't adjust based on glyphLoc.y; we'll use the lineFragmentRect for that
    }
        
    // adjust for the line height + border/focus ring
    point.y += NSHeight(rect) + 3;
    
    // adjust for the text container origin
    NSPoint tcOrigin = [self textContainerOrigin];
    point.x += tcOrigin.x;
    point.y += tcOrigin.y;
    
    // make sure we have integral coordinates
    point.x = ceilf(point.x);
    point.y = ceilf(point.y);
    
    // make sure we don't put the window before the textfield when the text is scrolled
    if (point.x < [self visibleRect].origin.x) 
        point.x = [self visibleRect].origin.x;
    
    // convert to screen coordinates
    point = [self convertPoint:point toView:nil];
    point = [[self window] convertBaseToScreen:point];  
    
    return point;
}

@end
