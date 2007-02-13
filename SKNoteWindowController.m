//
//  SKNoteWindowController.m
//  Skim
//
//  Created by Christiaan Hofman on 15/12/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "SKNoteWindowController.h"
#import <Quartz/Quartz.h>
#import "BDSKDragImageView.h"
#import "SKPDFAnnotationNote.h"


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
    CFRelease(editors);
    [note release];
    [super dealloc];
}

- (NSString *)windowNibName {
    return @"NoteWindow";
}

- (void)awakeFromNib {
    [[self window] setBackgroundColor:[NSColor colorWithDeviceWhite:0.9 alpha:1.0]];
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

