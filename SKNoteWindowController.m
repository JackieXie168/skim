//
//  SKNoteWindowController.m
//  Skim
//
//  Created by Christiaan Hofman on 12/15/06.
/*
 This software is Copyright (c) 2006,2007
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
#import "SKPDFAnnotationNote.h"
#import "SKDocument.h"

static NSString *SKNoteWindowFrameAutosaveName = @"SKNoteWindowFrameAutosaveName";

@interface SKRectStringTransformer : NSValueTransformer
@end

@implementation SKNoteWindowController

+ (void)initialize {
    SKRectStringTransformer *transformer = [[SKRectStringTransformer alloc] init];
    [NSValueTransformer setValueTransformer:transformer forName:@"SKRectStringTransformer"];
    [transformer release];
}

- (id)init {
    return self = [self initWithNote:nil];
}

- (id)initWithNote:(PDFAnnotation *)aNote {
    if (self = [super init]) {
        note = [aNote retain];
        editors = CFArrayCreateMutable(kCFAllocatorMallocZone, 0, NULL);
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    CFRelease(editors);
    [note release];
    [super dealloc];
}

- (NSString *)windowNibName {
    return @"NoteWindow";
}

- (void)windowDidLoad {
    [[self window] setBackgroundColor:[NSColor colorWithDeviceWhite:0.9 alpha:1.0]];
    
    [[self window] setFrameUsingName:SKNoteWindowFrameAutosaveName];
    static NSPoint nextWindowLocation = {0.0, 0.0};
    [self setShouldCascadeWindows:NO];
    if ([[self window] setFrameAutosaveName:SKNoteWindowFrameAutosaveName]) {
        NSRect windowFrame = [[self window] frame];
        nextWindowLocation = NSMakePoint(NSMinX(windowFrame), NSMaxY(windowFrame));
    }
    nextWindowLocation = [[self window] cascadeTopLeftFromPoint:nextWindowLocation];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDocumentWillSaveNotification:) 
                                                 name:SKDocumentWillSaveNotification object:[self document]];
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

- (IBAction)changeKeepOnTop:(id)sender {
    [[self window] setLevel:[sender state] == NSOnState ? NSFloatingWindowLevel : NSNormalWindowLevel];
}

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName {
    return [[self note] contents];
}

- (PDFAnnotation *)note {
    return note;
}

- (void)setNote:(PDFAnnotation *)newNote {
    if (note != newNote) {
        [note release];
        note = [newNote retain];
    }
}

- (BOOL)isNoteType {
    return [[note type] isEqualToString:@"Note"];
}

- (void)objectDidBeginEditing:(id)editor {
    if (CFArrayGetFirstIndexOfValue(editors, CFRangeMake(0, CFArrayGetCount(editors)), editor) == -1)
		CFArrayAppendValue((CFMutableArrayRef)editors, editor);		
}

- (void)objectDidEndEditing:(id)editor {
    CFIndex index = CFArrayGetFirstIndexOfValue(editors, CFRangeMake(0, CFArrayGetCount(editors)), editor);
    if (index != -1)
		CFArrayRemoveValueAtIndex((CFMutableArrayRef)editors, index);		
}

- (BOOL)commitEditing {
    CFIndex index = CFArrayGetCount(editors);
    
	while (index--)
		if([(NSObject *)(CFArrayGetValueAtIndex(editors, index)) commitEditing] == NO)
			return NO;
    
    return YES;
}

- (void)handleDocumentWillSaveNotification:(NSNotification *)notification {
    [self commitEditing];
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
        [(SKPDFAnnotationNote *)note setImage:image];
        [image release];
        return YES;
    } else return NO;
}

@end


@implementation SKRectStringTransformer

+ (Class)transformedValueClass {
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation {
    return NO;
}

- (id)transformedValue:(id)value {
    NSRect rect = [value rectValue];
	return [NSString stringWithFormat:@"(%i, %i)", (int)NSMidX(rect), (int)NSMidY(rect)];
}

@end

