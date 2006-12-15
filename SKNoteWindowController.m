//
//  SKNoteWindowController.m
//  Skim
//
//  Created by Christiaan Hofman on 15/12/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "SKNoteWindowController.h"
#import "SKNote.h"


@implementation SKNoteWindowController

- (id)init {
    return self = [self initWithNote:nil];
}

- (id)initWithNote:(SKNote *)aNote {
    if (self = [super init]) {
        note = [aNote copy];
        theModalDelegate = nil;
        theDidEndSelector = NULL;
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

- (SKNote *)note {
    return note;
}

- (void)setNote:(SKNote *)newNote {
    if (note != newNote) {
        [note release];
        note = [newNote copy];
    }
}

- (void)beginSheetModalForWindow:(NSWindow *)window modalDelegate:(id)modalDelegate didEndSelector:(SEL)didEndSelector contextInfo:(void *)contextInfo{
    [self retain];
    
    theModalDelegate = modalDelegate;
    theDidEndSelector = didEndSelector;
    
    [NSApp beginSheet: [self window]
       modalForWindow: window
        modalDelegate: self
       didEndSelector: @selector(sheetDidEnd:returnCode:contextInfo:)
          contextInfo: contextInfo];
}

- (IBAction)dismissSheet:(id)sender {
    [NSApp endSheet:[self window] returnCode:[sender tag]];
    [[self window] orderOut:self];
    [self release];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo{
	if(returnCode == NSOKButton)
        [self commitEditing];
    if(theModalDelegate != nil && theDidEndSelector != NULL){
		NSMethodSignature *signature = [theModalDelegate methodSignatureForSelector:theDidEndSelector];
        NSAssert2(nil != signature, @"%@ does not implement %@", theModalDelegate, NSStringFromSelector(theDidEndSelector));
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
		[invocation setSelector:theDidEndSelector];
		[invocation setArgument:&self atIndex:2];
		[invocation setArgument:&returnCode atIndex:3];
		[invocation setArgument:&contextInfo atIndex:4];
		[invocation invokeWithTarget:theModalDelegate];
	}
    
    theModalDelegate = nil;
    theDidEndSelector = NULL;
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

@end
