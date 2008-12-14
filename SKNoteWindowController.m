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
#import <SkimNotes/SkimNotes.h>
#import "SKNPDFAnnotationNote_SKExtensions.h"
#import "SKStatusBar.h"
#import "SKPDFDocument.h"
#import "SKPDFView.h"
#import "NSWindowController_SKExtensions.h"
#import "NSUserDefaultsController_SKExtensions.h"
#import "SKStringConstants.h"
#import "SKRuntime.h"
#import "PDFPage_SKExtensions.h"
#import "SKAnnotationTypeImageCell.h"
#import "NSString_SKExtensions.h"

#define SIZE_OFFSET 32.0
#define EM_DASH_CHARACTER 0x2014

static NSString *SKNoteWindowFrameAutosaveName = @"SKNoteWindow";
static NSString *SKGenericNoteWindowFrameAutosaveName = @"SKGenericNoteWindow";

static NSString *SKKeepNoteWindowsOnTopKey = @"SKKeepNoteWindowsOnTop";

static void *SKNoteWindowPageObservationContext = (void *)@"SKNoteWindowPageObservationContext";
static void *SKNoteWindowBoundsObservationContext = (void *)@"SKNoteWindowBoundsObservationContext";
static void *SKNoteWindowDefaultsObservationContext = (void *)@"SKNoteWindowDefaultsObservationContext";
static void *SKNoteWindowStringObservationContext = (void *)@"SKNoteWindowStringObservationContext";

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
    if (self = [super initWithWindowNibName:@"NoteWindow"]) {
        note = [aNote retain];
        
        keepOnTop = [[NSUserDefaults standardUserDefaults] boolForKey:SKKeepNoteWindowsOnTopKey];
        forceOnTop = NO;
        
        [note addObserver:self forKeyPath:SKNPDFAnnotationPageKey options:0 context:SKNoteWindowPageObservationContext];
        [note addObserver:self forKeyPath:SKNPDFAnnotationBoundsKey options:0 context:SKNoteWindowBoundsObservationContext];
        [note addObserver:self forKeyPath:SKNPDFAnnotationStringKey options:0 context:SKNoteWindowStringObservationContext];
        if ([self isNoteType])
            [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeys:[NSArray arrayWithObjects:SKAnchoredNoteFontNameKey, SKAnchoredNoteFontSizeKey, nil] context:SKNoteWindowDefaultsObservationContext];
    }
    return self;
}

- (void)dealloc {
    [note removeObserver:self forKeyPath:SKNPDFAnnotationPageKey];
    [note removeObserver:self forKeyPath:SKNPDFAnnotationBoundsKey];
    [note removeObserver:self forKeyPath:SKNPDFAnnotationStringKey];
    if ([self isNoteType])
        [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeys:[NSArray arrayWithObjects:SKAnchoredNoteFontNameKey, SKAnchoredNoteFontSizeKey, nil]];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [textViewUndoManager release];
    [note release];
    [super dealloc];
}

- (void)updateStatusMessage {
    NSRect bounds = [note bounds];
    [statusBar setLeftStringValue:[NSString stringWithFormat:NSLocalizedString(@"Page %@ at (%i, %i)", @"Status message"), [[note page] displayLabel], (int)NSMidX(bounds), (int)NSMidY(bounds)]];
}

- (void)windowDidLoad {
    [[self window] setBackgroundColor:[NSColor colorWithCalibratedWhite:0.9 alpha:1.0]];
    [[self window] setLevel:keepOnTop || forceOnTop ? NSFloatingWindowLevel : NSNormalWindowLevel];
    [[self window] setHidesOnDeactivate:keepOnTop || forceOnTop];
    
    if ([self isNoteType]) {
        if ([[textView string] length] == 0) {
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
    } else {
        NSView *gradientView = [imageView superview];
        NSTextField *textField = nil;
        NSEnumerator *viewEnum = [[gradientView subviews] objectEnumerator];
        id view;
        
        while (view = [viewEnum nextObject]) {
            if ([view isKindOfClass:[NSTextField class]] && [view isEditable]) {
                textField = view;
                break;
            }
        }
        
        NSRect frame, ignored;
        NSDivideRect([gradientView frame], &ignored, &frame, SIZE_OFFSET, NSMinYEdge);
        [gradientView setFrame:frame];
        NSDivideRect([textField frame], &ignored, &frame, -SIZE_OFFSET, NSMaxXEdge);
        [textField setFrame:frame];
        NSDivideRect([imageView frame], &ignored, &frame, SIZE_OFFSET, NSMinXEdge);
        NSDivideRect(frame, &ignored, &frame, SIZE_OFFSET, NSMinYEdge);
        [imageView setFrame:frame];
        
        SKAnnotationTypeImageCell *cell = [[[SKAnnotationTypeImageCell alloc] init] autorelease];
        [cell setObjectValue:[NSDictionary dictionaryWithObjectsAndKeys:[note type], SKAnnotationTypeImageCellTypeKey, nil]];
        [imageView unbind:@"value"];
        [imageView setCell:cell];
        
        NSSize minimumSize = [[self window] minSize];
        NSSize maximumSize = [[self window] maxSize];
        frame = [[[self window] contentView] frame];
        frame.size.height = NSHeight([statusBar frame]) + NSHeight([gradientView frame]);
        frame = [[self window] frameRectForContentRect:frame];
        minimumSize.height = maximumSize.height = NSHeight(frame);
        [[self window] setMinSize:minimumSize];
        [[self window] setMaxSize:maximumSize];
        [[self window] setFrame:frame display:NO];
    }
    
    [statusBar setLeftAction:@selector(statusBarClicked:)];
    [statusBar setLeftTarget:self];
    
    [self updateStatusMessage];
    
    [self setWindowFrameAutosaveNameOrCascade:[self isNoteType] ? SKNoteWindowFrameAutosaveName : SKGenericNoteWindowFrameAutosaveName];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDocumentWillSaveNotification:) 
                                                 name:SKPDFDocumentWillSaveNotification object:[self document]];
}

- (void)windowWillClose:(NSNotification *)aNotification {
    [noteController commitEditing];
    if ([note respondsToSelector:@selector(setWindowIsOpen:)])
        [(PDFAnnotationText *)note setWindowIsOpen:NO];
    if ([[self window] isKeyWindow])
        [[[[self document] mainWindowController] window] makeKeyWindow];
    else if ([[self window] isMainWindow])
        [[[[self document] mainWindowController] window] makeMainWindow];
}

- (IBAction)showWindow:(id)sender {
    [super showWindow:sender];
    if ([note respondsToSelector:@selector(setWindowIsOpen:)])
        [(PDFAnnotationText *)note setWindowIsOpen:YES];
}

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName {
    return [NSString stringWithFormat:@"%@ %C %@", [[[self note] type] typeName], EM_DASH_CHARACTER, [[self note] string]];
}

- (BOOL)isNoteWindowController { return YES; }

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

- (void)handleDocumentWillSaveNotification:(NSNotification *)notification {
    [noteController commitEditing];
}

- (NSUndoManager *)undoManagerForTextView:(NSTextView *)aTextView {
    if (textViewUndoManager == nil)
        textViewUndoManager = [[NSUndoManager alloc] init];
    return textViewUndoManager;
}

#pragma mark BDSKDragImageView delegate protocol

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
    } else if (context == SKNoteWindowStringObservationContext) {
        [self synchronizeWindowTitleWithDocumentName];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}
@end
