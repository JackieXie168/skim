//
//  SKNoteWindowController.m
//  Skim
//
//  Created by Christiaan Hofman on 12/15/06.
/*
 This software is Copyright (c) 2006-2008
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

#import "SKNoteWindowController.h"
#import <Quartz/Quartz.h>
#import "BDSKDragImageView.h"
#import <SkimNotes/PDFAnnotation_SKNExtensions.h>
#import <SkimNotes/SKNPDFAnnotationNote.h>
#import "SKNPDFAnnotationNote_SKExtensions.h"
#import "SKStatusBar.h"
#import "SKPDFDocument.h"
#import "SKPDFView.h"
#import "NSWindowController_SKExtensions.h"
#import "NSUserDefaultsController_SKExtensions.h"
#import "SKStringConstants.h"
#import "NSObject_SKExtensions.h"
#import "PDFPage_SKExtensions.h"

static NSString *SKNoteWindowFrameAutosaveName = @"SKNoteWindow";

static NSString *SKKeepNoteWindowsOnTopKey = @"SKKeepNoteWindowsOnTop";

static void *SKNoteWindowPageObservationContext = (void *)@"SKNoteWindowPageObservationContext";
static void *SKNoteWindowBoundsObservationContext = (void *)@"SKNoteWindowBoundsObservationContext";
static void *SKNoteWindowDefaultsObservationContext = (void *)@"SKNoteWindowDefaultsObservationContext";

@implementation SKNoteWindowController

static NSImage *noteIcons[7] = {nil, nil, nil, nil, nil, nil, nil};

+ (void)makeNoteIcons {
    if (noteIcons[0]) return;
    
    NSRect bounds = {NSZeroPoint, SKNPDFAnnotationNoteSize};
    PDFAnnotationText *annotation = [[PDFAnnotationText alloc] initWithBounds:bounds];
    PDFPage *page = [[PDFPage alloc] init];
    [page setBounds:bounds forBox:kPDFDisplayBoxMediaBox];
    [page addAnnotation:annotation];
    [annotation release];
    
    unsigned int i;
    for (i = 0; i < 7; i++) {
        noteIcons[i] = [[NSImage alloc] initWithSize:SKNPDFAnnotationNoteSize];
        [noteIcons[i] lockFocus];
        [annotation setIconType:i];
        [annotation drawWithBox:kPDFDisplayBoxMediaBox];
        [noteIcons[i] unlockFocus];
    }
    [page release];
}

+ (void)initialize {
    OBINITIALIZE;
    [self makeNoteIcons];
}

- (id)init {
    return self = [self initWithNote:nil];
}

- (id)initWithNote:(PDFAnnotation *)aNote {
    if (self = [super init]) {
        note = [aNote retain];
        editors = CFArrayCreateMutable(kCFAllocatorMallocZone, 0, NULL);
        
        keepOnTop = [[NSUserDefaults standardUserDefaults] boolForKey:SKKeepNoteWindowsOnTopKey];
        forceOnTop = NO;
        
        [note addObserver:self forKeyPath:SKNPDFAnnotationPageKey options:0 context:SKNoteWindowPageObservationContext];
        [note addObserver:self forKeyPath:SKNPDFAnnotationBoundsKey options:0 context:SKNoteWindowBoundsObservationContext];
        [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeys:[NSArray arrayWithObjects:SKAnchoredNoteFontNameKey, SKAnchoredNoteFontSizeKey, nil] context:SKNoteWindowDefaultsObservationContext];
    }
    return self;
}

- (void)dealloc {
    [note removeObserver:self forKeyPath:SKNPDFAnnotationPageKey];
    [note removeObserver:self forKeyPath:SKNPDFAnnotationBoundsKey];
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeys:[NSArray arrayWithObjects:SKAnchoredNoteFontNameKey, SKAnchoredNoteFontSizeKey, nil]];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    CFRelease(editors);
    [textViewUndoManager release];
    [note release];
    [super dealloc];
}

- (NSString *)windowNibName {
    return @"NoteWindow";
}

- (void)updateStatusMessage {
    NSRect bounds = [note bounds];
    [statusBar setLeftStringValue:[NSString stringWithFormat:NSLocalizedString(@"Page %@ at (%i, %i)", @"Status message"), [[note page] displayLabel], (int)NSMidX(bounds), (int)NSMidY(bounds)]];
}

- (void)windowDidLoad {
    [[self window] setBackgroundColor:[NSColor colorWithCalibratedWhite:0.9 alpha:1.0]];
    [[self window] setLevel:keepOnTop || forceOnTop ? NSFloatingWindowLevel : NSNormalWindowLevel];
    [[self window] setHidesOnDeactivate:keepOnTop || forceOnTop];
    
    if ([self isNoteType] && [[textView string] length] == 0) {
        NSString *fontName = [[NSUserDefaults standardUserDefaults] stringForKey:SKAnchoredNoteFontNameKey];
        float fontSize = [[NSUserDefaults standardUserDefaults] floatForKey:SKAnchoredNoteFontSizeKey];
        NSFont *font = fontName ? [NSFont fontWithName:fontName size:fontSize] : nil;
        if (font)
            [textView setFont:font];
    }
    
    unsigned i, count = [iconTypePopUpButton numberOfItems];
    for (i = 0; i < count; i++) {
        NSMenuItem *item = [iconTypePopUpButton itemAtIndex:i];
        [item setImage:noteIcons[[item tag]]];
    }
    
    [statusBar setLeftAction:@selector(statusBarClicked:)];
    [statusBar setLeftTarget:self];
    
    [self updateStatusMessage];
    
    [self setWindowFrameAutosaveNameOrCascade:SKNoteWindowFrameAutosaveName];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDocumentWillSaveNotification:) 
                                                 name:SKPDFDocumentWillSaveNotification object:[self document]];
}

- (void)windowWillClose:(NSNotification *)aNotification {
    [self commitEditing];
    if ([note respondsToSelector:@selector(setWindowIsOpen:)])
        [(PDFAnnotationText *)note setWindowIsOpen:NO];
}

- (IBAction)showWindow:(id)sender {
    [super showWindow:sender];
    if ([note respondsToSelector:@selector(setWindowIsOpen:)])
        [(PDFAnnotationText *)note setWindowIsOpen:YES];
}

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName {
    return [[self note] string];
}

- (PDFAnnotation *)note {
    return note;
}

- (void)setSkimNote:(PDFAnnotation *)newNote {
    if (note != newNote) {
        [note removeObserver:self forKeyPath:SKNPDFAnnotationPageKey];
        [note removeObserver:self forKeyPath:SKNPDFAnnotationBoundsKey];
        [note release];
        note = [newNote retain];
        [note addObserver:self forKeyPath:SKNPDFAnnotationPageKey options:0 context:NULL];
        [note addObserver:self forKeyPath:SKNPDFAnnotationBoundsKey options:0 context:NULL];
    }
}

- (BOOL)isNoteType {
    return [[note type] isEqualToString:SKNNoteString];
}

- (BOOL)keepOnTop {
    return keepOnTop;
}

- (void)setKeepOnTop:(BOOL)flag {
    keepOnTop = flag;
    [[self window] setLevel:keepOnTop || forceOnTop ? NSFloatingWindowLevel : NSNormalWindowLevel];
    [[self window] setHidesOnDeactivate:keepOnTop || forceOnTop];
}

- (BOOL)forceOnTop {
    return forceOnTop;
}

- (void)setForceOnTop:(BOOL)flag {
    forceOnTop = flag;
    [[self window] setLevel:keepOnTop || forceOnTop ? NSFloatingWindowLevel : NSNormalWindowLevel];
    [[self window] setHidesOnDeactivate:keepOnTop || forceOnTop];
}

- (void)statusBarClicked:(id)sender {
    SKPDFView *pdfView = [(SKPDFDocument *)[self document] pdfView];
    [pdfView scrollAnnotationToVisible:note];
    [pdfView setActiveAnnotation:note];
}

- (void)objectDidBeginEditing:(id)editor {
    if (CFArrayGetFirstIndexOfValue(editors, CFRangeMake(0, CFArrayGetCount(editors)), editor) == -1)
		CFArrayAppendValue((CFMutableArrayRef)editors, editor);		
}

- (void)objectDidEndEditing:(id)editor {
    CFIndex idx = CFArrayGetFirstIndexOfValue(editors, CFRangeMake(0, CFArrayGetCount(editors)), editor);
    if (idx != -1)
		CFArrayRemoveValueAtIndex((CFMutableArrayRef)editors, idx);		
}

- (BOOL)commitEditing {
    CFIndex idx = CFArrayGetCount(editors);
    
	while (idx--)
		if([(NSObject *)(CFArrayGetValueAtIndex(editors, idx)) commitEditing] == NO)
			return NO;
    
    return YES;
}

- (void)handleDocumentWillSaveNotification:(NSNotification *)notification {
    [self commitEditing];
}

- (NSUndoManager *)undoManagerForTextView:(NSTextView *)aTextView {
    if (textViewUndoManager == nil)
        textViewUndoManager = [[NSUndoManager alloc] init];
    return textViewUndoManager;
}

#pragma mark BDSKDragImageView delegate protocol

- (NSDragOperation)dragImageView:(BDSKDragImageView *)view validateDrop:(id <NSDraggingInfo>)sender;
{
    if ([[sender draggingSource] isEqual:view] == NO &&
        [NSImage canInitWithPasteboard:[sender draggingPasteboard]] &&
        [self isNoteType])
        return NSDragOperationCopy;
    else
        return NSDragOperationNone;
}

- (BOOL)dragImageView:(BDSKDragImageView *)view acceptDrop:(id <NSDraggingInfo>)sender;
{
    NSImage *image = [[NSImage alloc] initWithPasteboard:[sender draggingPasteboard]];
    
    if (image) {
        [(SKNPDFAnnotationNote *)note setImage:image];
        [image release];
        return YES;
    } else return NO;
}

- (BOOL)dragImageView:(BDSKDragImageView *)view writeDataToPasteboard:(NSPasteboard *)pasteboard {
    NSImage *image = [self isNoteType] ? [(SKNPDFAnnotationNote *)note image] : nil;
    if (image) {
        NSString *name = [note string];
        if ([name length] == 0)
            name = @"NoteImage";
        [pasteboard declareTypes:[NSArray arrayWithObjects:NSFilesPromisePboardType, NSTIFFPboardType, nil] owner:nil];
        [pasteboard setPropertyList:[NSArray arrayWithObjects:[name stringByAppendingPathExtension:@"tiff"], nil] forType:NSFilesPromisePboardType];
        [pasteboard setData:[image TIFFRepresentation] forType:NSTIFFPboardType];
        return YES;
    } else return NO;
}

- (NSArray *)dragImageView:(BDSKDragImageView *)view namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination {
    NSImage *image = [self isNoteType] ? [(SKNPDFAnnotationNote *)note image] : nil;
    if (image) {
        NSString *name = [note string];
        if ([name length] == 0)
            name = @"NoteImage";
        NSString *basePath = [[dropDestination path] stringByAppendingPathComponent:[note string]];
        NSString *path = [basePath stringByAppendingPathExtension:@"tiff"];
        int i = 0;
        NSFileManager *fm = [NSFileManager defaultManager];
        while ([fm fileExistsAtPath:path])
            path = [[basePath stringByAppendingFormat:@"-%i", ++i] stringByAppendingPathExtension:@"tiff"];
        if ([[image TIFFRepresentation] writeToFile:path atomically:YES])
            return [NSArray arrayWithObjects:[path lastPathComponent], nil];
    }
    return nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == SKNoteWindowDefaultsObservationContext) {
        NSString *key = [keyPath substringFromIndex:7];
        if (([key isEqualToString:SKAnchoredNoteFontNameKey] || [key isEqualToString:SKAnchoredNoteFontSizeKey]) && [self isNoteType] && [[textView string] length] == 0) {
            NSString *fontName = [[NSUserDefaults standardUserDefaults] stringForKey:SKAnchoredNoteFontNameKey];
            float fontSize = [[NSUserDefaults standardUserDefaults] floatForKey:SKAnchoredNoteFontSizeKey];
            NSFont *font = fontName ? [NSFont fontWithName:fontName size:fontSize] : nil;
            if (font)
                [textView setFont:font];
        }
    } else if (context == SKNoteWindowBoundsObservationContext || context == SKNoteWindowPageObservationContext) {
        [self updateStatusMessage];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}
@end
