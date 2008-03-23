//
//  PDFDocument_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 2/17/08.
/*
 This software is Copyright (c) 2008
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

#import "PDFDocument_SKExtensions.h"
#import "PDFSelection_SKExtensions.h"
#import "OBUtilities.h"


@interface PDFDocument (SKPrivateDeclarations)
- (NSPrintOperation *)getPrintOperationForPrintInfo:(NSPrintInfo *)printInfo autoRotate:(BOOL)autoRotate;
@end


@interface PDFDocument (SKPrivateExtensions)
- (NSPrintOperation *)replacementGetPrintOperationForPrintInfo:(NSPrintInfo *)printInfo autoRotate:(BOOL)autoRotate;
- (void)replacementCleanupAfterPrintOperation:(NSPrintOperation *)printOperation;
@end


@implementation PDFDocument (SKExtensions)

static IMP originalGetPrintOperationForPrintInfo = NULL;

+ (void)load {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    if ([self instancesRespondToSelector:@selector(getPrintOperationForPrintInfo:autoRotate:)])
        originalGetPrintOperationForPrintInfo = OBReplaceMethodImplementationWithSelector(self, @selector(getPrintOperationForPrintInfo:autoRotate:), @selector(replacementGetPrintOperationForPrintInfo:autoRotate:));
    [pool release];
}

- (NSPrintOperation *)replacementGetPrintOperationForPrintInfo:(NSPrintInfo *)printInfo autoRotate:(BOOL)autoRotate {
    NSPrintOperation *printOperation = originalGetPrintOperationForPrintInfo(self, _cmd, printInfo, autoRotate);
    BOOL suppressPrintPanel = [[[[printOperation printInfo] dictionary] objectForKey:@"SKSuppressPrintPanel"] boolValue];
    
    if (suppressPrintPanel) {
        [printOperation setShowsPrintPanel:NO];
    }
    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_4) {
        NSPrintPanel *printPanel = [printOperation printPanel];
        [printPanel setOptions:NSPrintPanelShowsCopies | NSPrintPanelShowsPageRange | NSPrintPanelShowsPaperSize | NSPrintPanelShowsOrientation | NSPrintPanelShowsScaling | NSPrintPanelShowsPreview];
        
        Class printAccessoryControllerClass = NSClassFromString(@"SKPrintAccessoryController");
        if (printAccessoryControllerClass == Nil) {
            [[NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"Skim-Leopard" ofType:@"bundle"]] load];
            printAccessoryControllerClass = NSClassFromString(@"SKPrintAccessoryController");
        }
        id printAccessoryViewController = [[[printAccessoryControllerClass alloc] init] autorelease];
        if (printAccessoryViewController)
            [printPanel addAccessoryController:printAccessoryViewController];
    } 
    return printOperation;
}

- (PDFSelection *)selectionByExtendingSelection:(PDFSelection *)selection toPage:(PDFPage *)page atPoint:(NSPoint)point {
    PDFSelection *sel = selection;
    NSArray *pages = [selection pages];
    
    if ([pages count]) {
        PDFPage *firstPage = [pages objectAtIndex:0];
        PDFPage *lastPage = [pages lastObject];
        unsigned int pageIndex = [self indexForPage:page];
        unsigned int firstPageIndex = [self indexForPage:firstPage];
        unsigned int lastPageIndex = [self indexForPage:lastPage];
        unsigned int n = [selection safeNumberOfRangesOnPage:lastPage];
        unsigned int firstChar = n ? [selection safeRangeAtIndex:0 onPage:firstPage].location : NSNotFound;
        unsigned int lastChar = n ? NSMaxRange([selection safeRangeAtIndex:n - 1 onPage:lastPage]) : NSNotFound;
        NSRect firstRect, lastRect;
        
        if (firstChar != NSNotFound) {
            firstRect = [firstPage characterBoundsAtIndex:firstChar];
        } else {
            NSRect bounds = [selection boundsForPage:firstPage];
            firstRect = NSMakeRect(NSMinX(bounds), NSMaxY(bounds) - 10.0, 5.0, 10.0);
        }
        if (lastChar != NSNotFound && lastChar != 0) {
            lastRect = [lastPage characterBoundsAtIndex:lastChar - 1];
        } else {
            NSRect bounds = [selection boundsForPage:lastPage];
            lastRect = NSMakeRect(NSMaxX(bounds) - 5.0, NSMinY(bounds), 5.0, 10.0);
        }
        if (pageIndex < firstPageIndex || (pageIndex == firstPageIndex && (point.y > NSMaxY(firstRect) || (point.y > NSMinY(firstRect) && point.x < NSMinX(firstRect)))))
            sel = [self selectionFromPage:page atPoint:point toPage:lastPage atPoint:NSMakePoint(NSMaxX(lastRect), NSMidY(lastRect))];
        if (pageIndex > lastPageIndex || (pageIndex == lastPageIndex && (point.y < NSMinY(lastRect) || (point.y < NSMaxY(lastRect) && point.x > NSMaxX(lastRect)))))
            sel = [self selectionFromPage:firstPage atPoint:NSMakePoint(NSMinX(firstRect), NSMidY(firstRect)) toPage:page atPoint:point];
    }
    return sel;
}

@end
