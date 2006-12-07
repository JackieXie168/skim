//
//  BDSKZoomablePDFView.m
//  Bibdesk
//
//  Created by Adam Maxwell on 07/23/05.
/*
 This software is Copyright (c) 2005,2006
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

#import "BDSKZoomablePDFView.h"
#import <OmniAppKit/NSView-OAExtensions.h>
#import <OmniBase/OBUtilities.h>
#import "BDSKHeaderPopUpButton.h"
#import "NSString_BDSKExtensions.h"
#import <OmniFoundation/NSString-OFExtensions.h>
#import "NSURL_BDSKExtensions.h"

@interface NSScrollView (BDSKZoomablePDFViewExtensions)
@end

@implementation NSScrollView (BDSKZoomablePDFViewExtensions)

static IMP originalTile;

+ (void)didLoad;
{
    originalTile = OBReplaceMethodImplementationWithSelector(self, @selector(tile), @selector(_replacementTile));
}

- (void)_replacementTile;
{
    // ARM: This is simpler than replacing the scrollview in the PDFView hierarchy, since we need to make sure the popup gets drawn at the right time in the scrollview, yet the popup action is handled by the PDFView.
    // Further, using [self replaceSubview:] in the PDFView init method to reimplement -tile in a trivial NSScrollView subclass will crash with the following backtrace:
    // 0   <<00000000>> 	0xfffeff18 objc_msgSend_rtp + 24
    // 1   com.apple.PDFKit             	0x96441778 -[PDFView adjustScrollbars:] + 592
    // 2   com.apple.Foundation         	0x9294d4c0 __NSFirePerformTimer + 308
    
    originalTile(self, _cmd);
    NSView *superview = [self superview];
        
    if([superview respondsToSelector:@selector(layoutScrollView)])
        [superview performSelector:@selector(layoutScrollView)];
}

@end

@implementation BDSKZoomablePDFView

/* For genstrings:
    NSLocalizedStringFromTable(@"10%", @"ZoomValues", @"Zoom popup entry")
    NSLocalizedStringFromTable(@"25%", @"ZoomValues", @"Zoom popup entry")
    NSLocalizedStringFromTable(@"50%", @"ZoomValues", @"Zoom popup entry")
    NSLocalizedStringFromTable(@"75%", @"ZoomValues", @"Zoom popup entry")
    NSLocalizedStringFromTable(@"100%", @"ZoomValues", @"Zoom popup entry")
    NSLocalizedStringFromTable(@"128%", @"ZoomValues", @"Zoom popup entry")
    NSLocalizedStringFromTable(@"200%", @"ZoomValues", @"Zoom popup entry")
    NSLocalizedStringFromTable(@"400%", @"ZoomValues", @"Zoom popup entry")
    NSLocalizedStringFromTable(@"800%", @"ZoomValues", @"Zoom popup entry")
*/   
static NSString *BDSKDefaultScaleMenuLabels[] = {/* @"Set...", */ @"Auto", @"10%", @"25%", @"50%", @"75%", @"100%", @"128%", @"150%", @"200%", @"400%", @"800%"};
static float BDSKDefaultScaleMenuFactors[] = {/* 0.0, */ 0, 0.1, 0.25, 0.5, 0.75, 1.0, 1.28, 1.5, 2.0, 4.0, 8.0};
static float BDSKScaleMenuFontSize = 11.0;

#pragma mark Instance methods

- (id)initWithFrame:(NSRect)rect {
    if (self = [super initWithFrame:rect]) {
		scaleFactor = 1.0;
        pasteboardInfo = [[NSMutableDictionary alloc] initWithCapacity:2];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
		scaleFactor = 1.0;
        pasteboardInfo = [[NSMutableDictionary alloc] initWithCapacity:2];
    }
    return self;
}

- (void)dealloc{
    [pasteboardInfo release];
    [super dealloc];
}

#pragma mark Copying

// used to cache the selection info and document for lazy copying
- (void)updatePasteboardInfo;
{    
    PDFSelection *theSelection = [self currentSelection];
    if(!theSelection)
        theSelection = [[self document] selectionForEntireDocument];
    
    [pasteboardInfo setValue:theSelection forKey:@"selection"];
    [pasteboardInfo setValue:[self document] forKey:@"document"];
    [pasteboardInfo setValue:[self currentPage] forKey:@"page"];
}

// override so we can put the entire document on the pasteboard if there is no selection
- (void)copy:(id)sender;
{
    NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSGeneralPboard];
    [pboard declareTypes:[NSArray arrayWithObjects:NSPDFPboardType, NSStringPboardType, NSRTFPboardType, nil] owner:self];
    [self updatePasteboardInfo];
}

- (void)pasteboard:(NSPasteboard *)sender provideDataForType:(NSString *)type;
{    
    PDFSelection *theSelection = [pasteboardInfo valueForKey:@"selection"];
    PDFDocument *theDocument = [pasteboardInfo valueForKey:@"document"];
    PDFPage *thePage = [pasteboardInfo valueForKey:@"page"];
    
    // use a private type to signal that we need to provide a page as PDF
    if([type isEqualToString:NSPDFPboardType] && [[sender types] containsObject:@"BDSKPrivatePDFPageDataPboardType"]){
        [sender setData:[thePage dataRepresentation] forType:type];
    } else if([type isEqualToString:NSPDFPboardType]){ 
        // write the whole document
        [sender setData:[theDocument dataRepresentation] forType:type];
    } else if([type isEqualToString:NSStringPboardType]){
        [sender setString:[theSelection string] forType:type];
    } else if([type isEqualToString:NSRTFPboardType]){
        NSAttributedString *attrString = [theSelection attributedString];
        [sender setData:[attrString RTFFromRange:NSMakeRange(0, [attrString length]) documentAttributes:nil] forType:type];
    } else NSBeep();
}

- (void)copyAsPDF:(id)sender;
{
    NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSGeneralPboard];
    [pboard declareTypes:[NSArray arrayWithObjects:NSPDFPboardType, @"BDSKPrivatePDFPageDataPboardType", nil] owner:self];
    [self updatePasteboardInfo];
}

- (void)copyAsText:(id)sender;
{
    NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSGeneralPboard];
    [pboard declareTypes:[NSArray arrayWithObjects:NSStringPboardType, NSRTFPboardType, nil] owner:self];
    [self updatePasteboardInfo];
}

- (void)copyPDFPage:(id)sender;
{
    [self copyAsPDF:nil];
}

- (void)saveDocumentSheetDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode  contextInfo:(void  *)contextInfo;
{
    NSError *error = nil;
    if(returnCode == NSOKButton){
        // -[PDFDocument writeToURL:] returns YES even if you don't have write permission, so we'll use NSData rdar://problem/4475062
        NSData *data = [[self document] dataRepresentation];
        
        if([data writeToURL:[sheet URL] options:NSAtomicWrite error:&error] == NO){
            [sheet orderOut:nil];
            [self presentError:error];
        }
    }
}
    
- (void)saveDocumentAs:(id)sender;
{
    NSString *name = [[[self document] documentURL] lastPathComponent];
    [[NSSavePanel savePanel] beginSheetForDirectory:nil file:(name ? name : NSLocalizedString(@"Untitled.pdf", @"")) modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(saveDocumentSheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent;
{
    NSMenu *menu = [super menuForEvent:theEvent];
    [menu addItem:[NSMenuItem separatorItem]];
    NSMenuItem *item = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Copy Document as PDF", @"") action:@selector(copyAsPDF:) keyEquivalent:@""];
    [menu addItem:item];
    [item release];
    
    item = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Copy Page as PDF", @"") action:@selector(copyPDFPage:) keyEquivalent:@""];
    [menu addItem:item];
    [item release];

    NSString *title = (nil == [self currentSelection]) ? NSLocalizedString(@"Copy All Text", @"") : NSLocalizedString(@"Copy Selected Text", @"");
    
    item = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:title action:@selector(copyAsText:) keyEquivalent:@""];
    [menu addItem:item];
    [item release];
    
    [menu addItem:[NSMenuItem separatorItem]];
    
    item = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[NSLocalizedString(@"Save PDF As", @"") stringByAppendingEllipsis] action:@selector(saveDocumentAs:) keyEquivalent:@""];
    [menu addItem:item];
    [item release];

    return menu;
}
    
#pragma mark Popup button

- (void)makeScalePopUpButton {
    
    if (scalePopUpButton == nil) {
        
        NSScrollView *scrollView = [self scrollView];

        unsigned cnt, numberOfDefaultItems = (sizeof(BDSKDefaultScaleMenuLabels) / sizeof(NSString *));
        id curItem;

        // create it        
        scalePopUpButton = [[NSClassFromString(@"BDSKHeaderPopUpButton") allocWithZone:[self zone]] initWithFrame:NSMakeRect(0.0, 0.0, 1.0, 1.0) pullsDown:NO];
        
        NSControlSize controlSize = [[scrollView horizontalScroller] controlSize];
        [[scalePopUpButton cell] setControlSize:controlSize];
		
        // fill it
        for (cnt = 0; cnt < numberOfDefaultItems; cnt++) {
            [scalePopUpButton addItemWithTitle:NSLocalizedStringFromTable(BDSKDefaultScaleMenuLabels[cnt], @"ZoomValues", nil)];
            curItem = [scalePopUpButton itemAtIndex:cnt];
            [curItem setRepresentedObject:(BDSKDefaultScaleMenuFactors[cnt] != 0.0 ? [NSNumber numberWithFloat:BDSKDefaultScaleMenuFactors[cnt]] : nil)];
        }
        // select the appropriate item, adjusting the scaleFactor if necessary
		[self setScaleFactor:scaleFactor adjustPopup:YES];

        // hook it up
        [scalePopUpButton setTarget:self];
        [scalePopUpButton setAction:@selector(scalePopUpAction:)];

        // set a suitable font, the control size is 0, 1 or 2
        [scalePopUpButton setFont:[NSFont toolTipsFontOfSize: BDSKScaleMenuFontSize - controlSize]];

        // Make sure the popup is big enough to fit the cells.
        [scalePopUpButton sizeToFit];

		// don't let it become first responder
		[scalePopUpButton setRefusesFirstResponder:YES];

        // put it in the scrollview
        [scrollView addSubview:scalePopUpButton];
        [scalePopUpButton release];
        
        NSRect frameRect = [scrollView frame];
        frameRect.origin.y += 3;
        frameRect.size.height -= 3;
        [scrollView setFrame:frameRect];
    }
}

- (void)drawRect:(NSRect)rect {
    [super drawRect:rect];

    if ([scalePopUpButton superview]) {
        NSRect shadowRect = [scalePopUpButton frame];
        shadowRect.origin.x -= 1.0;
        shadowRect.origin.y -= 1.0;
        shadowRect.size.width += 1.0;
        shadowRect.size.height += 1.0;
		shadowRect = [self convertRect:shadowRect fromView:[scalePopUpButton superview]];
        if (NSIntersectsRect(rect, shadowRect)) {
            [[NSColor lightGrayColor] set];
            NSRectFill(shadowRect);
        }
    }
}

- (void)scalePopUpAction:(id)sender {
    NSNumber *selectedFactorObject = [[sender selectedCell] representedObject];
    if(!selectedFactorObject)
        [super setAutoScales:YES];
    else
        [self setScaleFactor:[selectedFactorObject floatValue] adjustPopup:NO];
}

- (void)setScaleFactor:(float)newScaleFactor {
    NSPoint scrollPoint = (NSPoint)[self scrollPositionAsPercentage];
	[self setScaleFactor:newScaleFactor adjustPopup:YES];
    [self setScrollPositionAsPercentage:scrollPoint];
}

- (void)setScaleFactor:(float)newScaleFactor adjustPopup:(BOOL)flag {
    
    if(!newScaleFactor)
        [self setAutoScales:YES];
    else
        [super setScaleFactor:newScaleFactor];
    
	if (flag) {
		unsigned cnt = 0, numberOfDefaultItems = (sizeof(BDSKDefaultScaleMenuFactors) / sizeof(float));
		
		// We only work with some preset zoom values, so choose one of the appropriate values (Fudge a little for floating point == to work)
		while (cnt < numberOfDefaultItems && newScaleFactor * .99 > BDSKDefaultScaleMenuFactors[cnt]) cnt++;
		if (cnt == numberOfDefaultItems) cnt--;
		[scalePopUpButton selectItemAtIndex:cnt];
		newScaleFactor = BDSKDefaultScaleMenuFactors[cnt];
    }
	
}

#pragma mark Scrollview

- (NSScrollView *)scrollView;
{
    return [[self documentView] enclosingScrollView];
}

- (void)setScrollerSize:(NSControlSize)controlSize;
{
    NSScrollView *scrollView = [[self documentView] enclosingScrollView];
    [scrollView setHasHorizontalScroller:YES];
    [scrollView setHasVerticalScroller:YES];
    [[scrollView horizontalScroller] setControlSize:controlSize];
    [[scrollView verticalScroller] setControlSize:controlSize];
	if(scalePopUpButton){
		[[scalePopUpButton cell] setControlSize:controlSize];
        [scalePopUpButton setFont:[NSFont toolTipsFontOfSize: BDSKScaleMenuFontSize - controlSize]];
	}
}

- (void)layoutScrollView;
{
    NSScrollView *scrollView = [self scrollView];
    
    // make sure we always have a scroller; disabling autohide isn't enough
    [scrollView setHasHorizontalScroller:YES];
    [scrollView setAutohidesScrollers:NO];
    
    if (!scalePopUpButton) [self makeScalePopUpButton];

    NSRect horizScrollerFrame, buttonFrame;
    buttonFrame = [scalePopUpButton frame];
	if (![scrollView hasHorizontalScroller]) {
        if (scalePopUpButton) [scalePopUpButton removeFromSuperview];
        scalePopUpButton = nil;
    } else {
        NSScroller *horizScroller;
        horizScroller = [scrollView horizontalScroller];
        horizScrollerFrame = [horizScroller frame];
        
        // Now we'll just adjust the horizontal scroller size and set the button size and location.
        // Set it based on our frame, not the scroller's frame, since this gets called repeatedly; 15 is for the window's thumb.
        horizScrollerFrame.size.width = [scrollView frame].size.width - buttonFrame.size.width - NSWidth([[scrollView verticalScroller] frame]) - 1.0;
        [horizScroller setFrameSize:horizScrollerFrame.size];

        buttonFrame.origin.x = NSMaxX(horizScrollerFrame) + 1.0;
        buttonFrame.origin.y = horizScrollerFrame.origin.y + 1.0;
        buttonFrame.size.height = horizScrollerFrame.size.height - 1.0;
    }
    [scalePopUpButton setFrame:buttonFrame];
}


@end
