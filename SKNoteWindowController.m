//
//  SKNoteWindowController.m
//  Skim
//
//  Created by Christiaan Hofman on 12/15/06.
/*
 This software is Copyright (c) 2006-2011
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
#import "SKDragImageView.h"
#import <SkimNotes/SkimNotes.h>
#import "SKNPDFAnnotationNote_SKExtensions.h"
#import "SKStatusBar.h"
#import "SKMainDocument.h"
#import "SKPDFView.h"
#import "NSWindowController_SKExtensions.h"
#import "NSUserDefaultsController_SKExtensions.h"
#import "SKStringConstants.h"
#import "PDFPage_SKExtensions.h"
#import "SKAnnotationTypeImageCell.h"
#import "NSString_SKExtensions.h"
#import "SKGradientView.h"
#import "NSGeometry_SKExtensions.h"
#import "NSGraphics_SKExtensions.h"
#import "SKNoteTextView.h"

#define EM_DASH_CHARACTER 0x2014

#define SKNoteWindowFrameAutosaveName @"SKNoteWindow"
#define SKAnyNoteWindowFrameAutosaveName @"SKAnyNoteWindow"

#define SKKeepNoteWindowsOnTopKey @"SKKeepNoteWindowsOnTop"

static char SKNoteWindowPageObservationContext;
static char SKNoteWindowBoundsObservationContext;
static char SKNoteWindowDefaultsObservationContext;
static char SKNoteWindowStringObservationContext;

@implementation SKNoteWindowController

@synthesize textView, gradientView, imageView, statusBar, iconTypePopUpButton, iconLabelField, checkButton, noteController, note, keepOnTop, forceOnTop;
@dynamic isNoteType;

static NSImage *noteIcons[7] = {nil, nil, nil, nil, nil, nil, nil};

+ (void)makeNoteIcons {
    if (noteIcons[0]) return;
    
    NSRect bounds = {NSZeroPoint, SKNPDFAnnotationNoteSize};
    PDFAnnotationText *annotation = [[PDFAnnotationText alloc] initWithBounds:bounds];
    PDFPage *page = [[PDFPage alloc] init];
    [page setBounds:bounds forBox:kPDFDisplayBoxMediaBox];
    [page addAnnotation:annotation];
    [annotation release];
    
    NSUInteger i;
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
    SKINITIALIZE;
    [self makeNoteIcons];
}

- (id)init {
    return [self initWithNote:nil];
}

- (id)initWithNote:(PDFAnnotation *)aNote {
    self = [super initWithWindowNibName:@"NoteWindow"];
    if (self) {
        note = [aNote retain];
        
        keepOnTop = [[NSUserDefaults standardUserDefaults] boolForKey:SKKeepNoteWindowsOnTopKey];
        forceOnTop = NO;
        
        [note addObserver:self forKeyPath:SKNPDFAnnotationPageKey options:0 context:&SKNoteWindowPageObservationContext];
        [note addObserver:self forKeyPath:SKNPDFAnnotationBoundsKey options:0 context:&SKNoteWindowBoundsObservationContext];
        [note addObserver:self forKeyPath:SKNPDFAnnotationStringKey options:0 context:&SKNoteWindowStringObservationContext];
        if ([self isNoteType])
            [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeys:[NSArray arrayWithObjects:SKAnchoredNoteFontNameKey, SKAnchoredNoteFontSizeKey, nil] context:&SKNoteWindowDefaultsObservationContext];
    }
    return self;
}

- (void)dealloc {
    @try { [textView unbind:[self isNoteType] ? @"attributedString" : @"value"]; }
    @catch (id e) {}
    [note removeObserver:self forKeyPath:SKNPDFAnnotationPageKey];
    [note removeObserver:self forKeyPath:SKNPDFAnnotationBoundsKey];
    [note removeObserver:self forKeyPath:SKNPDFAnnotationStringKey];
    if ([self isNoteType])
        [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeys:[NSArray arrayWithObjects:SKAnchoredNoteFontNameKey, SKAnchoredNoteFontSizeKey, nil]];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[self window] setDelegate:nil];
    [imageView setDelegate:nil];
    [textView setDelegate:nil];
    SKDESTROY(textViewUndoManager);
    SKDESTROY(note);
    SKDESTROY(textView);
    SKDESTROY(gradientView);
    SKDESTROY(imageView);
    SKDESTROY(statusBar);
    SKDESTROY(iconTypePopUpButton);
    SKDESTROY(iconLabelField);
    SKDESTROY(checkButton);
    SKDESTROY(noteController);
    [super dealloc];
}

- (void)updateStatusMessage {
    NSRect bounds = [note bounds];
    [statusBar setLeftStringValue:[NSString stringWithFormat:NSLocalizedString(@"Page %@ at (%ld, %ld)", @"Status message"), [[note page] displayLabel], (long)NSMidX(bounds), (long)NSMidY(bounds)]];
}

- (void)windowDidLoad {
    [[self window] setLevel:keepOnTop || forceOnTop ? NSFloatingWindowLevel : NSNormalWindowLevel];
    [[self window] setHidesOnDeactivate:keepOnTop || forceOnTop];
    
    [[self window] setAutorecalculatesContentBorderThickness:NO forEdge:NSMinYEdge];
    [[self window] setContentBorderThickness:22.0 forEdge:NSMinYEdge];
    
    [[[[statusBar subviews] lastObject] cell] setBackgroundStyle:NSBackgroundStyleRaised];
    
    if ([self isNoteType]) {
        [gradientView setEdges:SKMinYEdgeMask];
        [gradientView setAlternateGradient:nil];
        
        NSString *fontName = [[NSUserDefaults standardUserDefaults] stringForKey:SKAnchoredNoteFontNameKey];
        CGFloat fontSize = [[NSUserDefaults standardUserDefaults] floatForKey:SKAnchoredNoteFontSizeKey];
        NSFont *font = fontName ? [NSFont fontWithName:fontName size:fontSize] : nil;
        if (font)
            [textView setFont:font];
        [textView bind:@"attributedString" toObject:noteController withKeyPath:@"selection.text" options:nil];
        
        for (NSMenuItem *item in [iconTypePopUpButton itemArray])
            [item setImage:noteIcons[[item tag]]];
        
        SKAutoSizeLabelFields([NSArray arrayWithObjects:iconLabelField, nil], [NSArray arrayWithObjects:iconTypePopUpButton, nil], YES);
        
    } else {
        [gradientView setHidden:YES];
        
        NSRect frame = NSUnionRect([[textView enclosingScrollView] frame], [gradientView frame]);
        [[textView enclosingScrollView] setFrame:frame];
        [textView setRichText:NO];
        [textView setUsesDefaultFontSize:YES];
        [textView bind:@"value" toObject:noteController withKeyPath:@"selection.string" options:nil];
        
        NSSize minimumSize = [[self window] minSize];
        frame = [[[self window] contentView] frame];
        frame.size.height = NSHeight([statusBar frame]) + 29.0;
        frame = [[self window] frameRectForContentRect:frame];
        minimumSize.height = NSHeight(frame);
        [[self window] setMinSize:minimumSize];
        [[self window] setFrame:frame display:NO];
    }
    
    NSRect buttonFrame = [checkButton frame];
    CGFloat right = NSMaxX(buttonFrame);
    [checkButton sizeToFit];
    buttonFrame = [checkButton frame];
    buttonFrame.origin.x = right - NSWidth(buttonFrame);
    [checkButton setFrame:buttonFrame];
    
    SKAnnotationTypeImageCell *cell = [[[SKAnnotationTypeImageCell alloc] initImageCell:nil] autorelease];
    [cell setObjectValue:[NSDictionary dictionaryWithObjectsAndKeys:[note type], SKAnnotationTypeImageCellTypeKey, nil]];
    
    [statusBar setLeftAction:@selector(statusBarClicked:)];
    [statusBar setLeftTarget:self];
    [statusBar setIconCell:cell];
    
    [self updateStatusMessage];
    
    [self setWindowFrameAutosaveNameOrCascade:[self isNoteType] ? SKNoteWindowFrameAutosaveName : SKAnyNoteWindowFrameAutosaveName];
}

- (BOOL)windowShouldClose:(id)window {
    return [self commitEditing];
}

- (void)windowWillClose:(NSNotification *)aNotification {
    if ([self commitEditing] == NO)
        [self discardEditing];
    if ([note respondsToSelector:@selector(setWindowIsOpen:)])
        [(PDFAnnotationText *)note setWindowIsOpen:NO];
    if ([[self window] isKeyWindow])
        [[[[self document] mainWindowController] window] makeKeyWindow];
    else if ([[self window] isMainWindow])
        [[[[self document] mainWindowController] window] makeMainWindow];
}

- (void)setDocument:(NSDocument *)document {
    // in case the document is reset before windowWillClose: is called, I think this can happen on Tiger
    if ([self document] && document == nil) {
        if ([self commitEditing] == NO)
            [self discardEditing];
        if (isEditing) {
            [[self document] objectDidEndEditing:self];
            isEditing = NO;
        }
    }
    [super setDocument:document];
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

- (BOOL)isNoteType {
    return [[note type] isEqualToString:SKNNoteString];
}

- (void)setKeepOnTop:(BOOL)flag {
    keepOnTop = flag;
    [[self window] setLevel:keepOnTop || forceOnTop ? NSFloatingWindowLevel : NSNormalWindowLevel];
    [[self window] setHidesOnDeactivate:keepOnTop || forceOnTop];
}

- (void)setForceOnTop:(BOOL)flag {
    forceOnTop = flag;
    [[self window] setLevel:keepOnTop || forceOnTop ? NSFloatingWindowLevel : NSNormalWindowLevel];
    [[self window] setHidesOnDeactivate:keepOnTop || forceOnTop];
}

- (void)statusBarClicked:(id)sender {
    SKPDFView *pdfView = [(SKMainDocument *)[self document] pdfView];
    [pdfView scrollAnnotationToVisible:note];
    [pdfView setActiveAnnotation:note];
}

- (NSUndoManager *)undoManagerForTextView:(NSTextView *)aTextView {
    if (textViewUndoManager == nil)
        textViewUndoManager = [[NSUndoManager alloc] init];
    return textViewUndoManager;
}

#pragma mark NSEditorRegistration and NSEditor protocol

- (void)objectDidBeginEditing:(id)editor {
    if (isEditing == NO) {
        [[self document] objectDidBeginEditing:self];
        isEditing = YES;
    }
}

- (void)objectDidEndEditing:(id)editor {
    if (isEditing) {
        [[self document] objectDidEndEditing:self];
        isEditing = NO;
    }
}

- (void)discardEditing {
    [noteController discardEditing];
}

- (BOOL)commitEditing {
    return [noteController commitEditing];
}

- (void)editor:(id)editor didCommit:(BOOL)didCommit contextInfo:(void *)contextInfo {
    NSInvocation *invocation = [(NSInvocation *)contextInfo autorelease];
    if (invocation) {
        [invocation setArgument:&didCommit atIndex:3];
        [invocation invoke];
    }
}

- (void)commitEditingWithDelegate:(id)delegate didCommitSelector:(SEL)didCommitSelector contextInfo:(void *)contextInfo {
    if (delegate && didCommitSelector) {
        NSInvocation *invocation = [[NSInvocation invocationWithMethodSignature:[delegate methodSignatureForSelector:didCommitSelector]] retain];
        [invocation setTarget:delegate];
        [invocation setSelector:didCommitSelector];
        [invocation setArgument:&self atIndex:2];
        [invocation setArgument:&contextInfo atIndex:4];
        return [noteController commitEditingWithDelegate:self didCommitSelector:@selector(editor:didCommit:contextInfo:) contextInfo:invocation];
    }
    return [noteController commitEditingWithDelegate:delegate didCommitSelector:didCommitSelector contextInfo:contextInfo];
}

#pragma mark SKDragImageView delegate protocol

- (BOOL)dragImageView:(SKDragImageView *)view writeDataToPasteboard:(NSPasteboard *)pasteboard {
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

- (NSArray *)dragImageView:(SKDragImageView *)view namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination {
    NSImage *image = [self isNoteType] ? [(SKNPDFAnnotationNote *)note image] : nil;
    if (image) {
        NSString *name = [note string];
        if ([name length] == 0)
            name = @"NoteImage";
        NSString *basePath = [[dropDestination path] stringByAppendingPathComponent:name];
        NSString *path = [basePath stringByAppendingPathExtension:@"tiff"];
        NSInteger i = 0;
        NSFileManager *fm = [NSFileManager defaultManager];
        while ([fm fileExistsAtPath:path])
            path = [[basePath stringByAppendingFormat:@"-%ld", (long)++i] stringByAppendingPathExtension:@"tiff"];
        if ([[image TIFFRepresentation] writeToFile:path atomically:YES])
            return [NSArray arrayWithObjects:[path lastPathComponent], nil];
    }
    return nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == &SKNoteWindowDefaultsObservationContext) {
        NSString *key = [keyPath substringFromIndex:7];
        if (([key isEqualToString:SKAnchoredNoteFontNameKey] || [key isEqualToString:SKAnchoredNoteFontSizeKey]) && [self isNoteType] && [[textView string] length] == 0) {
            NSString *fontName = [[NSUserDefaults standardUserDefaults] stringForKey:SKAnchoredNoteFontNameKey];
            CGFloat fontSize = [[NSUserDefaults standardUserDefaults] floatForKey:SKAnchoredNoteFontSizeKey];
            NSFont *font = fontName ? [NSFont fontWithName:fontName size:fontSize] : nil;
            if (font)
                [textView setFont:font];
        }
    } else if (context == &SKNoteWindowBoundsObservationContext || context == &SKNoteWindowPageObservationContext) {
        [self updateStatusMessage];
    } else if (context == &SKNoteWindowStringObservationContext) {
        [self synchronizeWindowTitleWithDocumentName];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
