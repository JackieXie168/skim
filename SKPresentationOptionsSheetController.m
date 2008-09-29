//
//  SKPresentationOptionsSheetController.m
//  Skim
//
//  Created by Christiaan Hofman on 9/28/08.
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

#import "SKPresentationOptionsSheetController.h"
#import <Quartz/Quartz.h>
#import "SKPDFDocument.h"
#import "SKDocumentController.h"


@implementation SKPresentationOptionsSheetController

- (id)initForDocument:(SKPDFDocument *)aDocument {
    if (self = [super init]) {
        document = aDocument;
    }
    return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void)handleDocumentsDidChangeNotification:(NSNotification *)note {
    id currentDoc = [[[notesDocumentPopUpButton selectedItem] representedObject] retain];
    
    while ([notesDocumentPopUpButton numberOfItems] > 1)
        [notesDocumentPopUpButton removeItemAtIndex:[notesDocumentPopUpButton numberOfItems] - 1];
    
    NSEnumerator *docEnum = [[[NSDocumentController sharedDocumentController] documents] objectEnumerator];
    id doc;
    NSMutableArray *documents = [NSMutableArray array];
    unsigned pageCount = [[document pdfDocument] pageCount];
    while (doc = [docEnum nextObject]) {
        if ([doc respondsToSelector:@selector(pdfDocument)] && doc != document && [[doc pdfDocument] pageCount] == pageCount)
            [documents addObject:doc];
    }
    NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"displayName" ascending:YES] autorelease];
    [documents sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    docEnum = [documents objectEnumerator];
    while (doc = [docEnum nextObject]) {
        [notesDocumentPopUpButton addItemWithTitle:[doc displayName]];
        [[notesDocumentPopUpButton lastItem] setRepresentedObject:doc];
    }
    
    int docIndex = [notesDocumentPopUpButton indexOfItemWithRepresentedObject:currentDoc];
    [notesDocumentPopUpButton selectItemAtIndex:docIndex == -1 ? 0 : docIndex];
    [currentDoc release];
}

- (void)windowDidLoad {
    NSArray *filterNames = [SKTransitionController transitionFilterNames];
    int i, count = [filterNames count];
    for (i = 0; i < count; i++) {
        NSString *name = [filterNames objectAtIndex:i];
        [transitionStylePopUpButton addItemWithTitle:[CIFilter localizedNameForFilterName:name]];
        NSMenuItem *item = [transitionStylePopUpButton lastItem];
        [item setTag:SKCoreImageTransition + i];
    }
    
    [self handleDocumentsDidChangeNotification:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDocumentsDidChangeNotification:) 
                                                 name:SKDocumentDidShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDocumentsDidChangeNotification:) 
                                                 name:SKDocumentControllerDidRemoveDocumentNotification object:nil];
}

- (NSString *)windowNibName {
    return @"TransitionSheet";
}

- (SKPDFDocument *)document {
    return document;
}

- (SKAnimationTransitionStyle)transitionStyle {
    [self window];
    return [[transitionStylePopUpButton selectedItem] tag];
}

- (void)setTransitionStyle:(SKAnimationTransitionStyle)style {
    [self window];
    [transitionStylePopUpButton selectItemWithTag:style];
}

- (float)duration {
    [self window];
    return fmaxf([transitionDurationField floatValue], 0.0);
}

- (void)setDuration:(float)newDuration {
    [self window];
    [transitionDurationField setFloatValue:newDuration];
    [transitionDurationSlider setFloatValue:newDuration];
}

- (BOOL)shouldRestrict {
    [self window];
    return (BOOL)[[transitionExtentMatrix selectedCell] tag];
}

- (void)setShouldRestrict:(BOOL)flag {
    [self window];
    [transitionExtentMatrix selectCellWithTag:(int)flag];
}

- (SKPDFDocument *)notesDocument {
    [self window];
    return [[notesDocumentPopUpButton selectedItem] representedObject];
}

- (void)setNotesDocument:(SKPDFDocument *)newNotesDocument {
    [self window];
    int docIndex = [notesDocumentPopUpButton indexOfItemWithRepresentedObject:newNotesDocument];
    [notesDocumentPopUpButton selectItemAtIndex:docIndex > 0 ? docIndex : 0];
}

@end
