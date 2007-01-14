//
//  BDSKURLGroupSheetController.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 11/10/06.
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

#import "BDSKURLGroupSheetController.h"
#import "BDSKURLGroup.h"
#import "NSArray_BDSKExtensions.h"
#import "NSError_BDSKExtensions.h"
#import "BibDocument.h"
#import "BDSKFieldEditor.h"

@implementation BDSKURLGroupSheetController

- (id)init {
    self = [self initWithGroup:nil];
    return self;
}

- (id)initWithGroup:(BDSKURLGroup *)aGroup {
    if (self = [super init]) {
        group = [aGroup retain];
        urlString = [[[group URL] absoluteString] retain];
        editors = CFArrayCreateMutable(kCFAllocatorMallocZone, 0, NULL);
        undoManager = nil;
        dragFieldEditor = nil;
    }
    return self;
}

- (void)dealloc {
    [urlString release];
    [group release];
    [undoManager release];
    [dragFieldEditor release];
    CFRelease(editors);
    [super dealloc];
}

- (void)awakeFromNib {
    [urlField registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, NSURLPboardType, BDSKWeblocFilePboardType, nil]];
}

- (NSString *)windowNibName {
    return @"BDSKURLGroupSheet";
}

- (IBAction)dismiss:(id)sender {
    if ([sender tag] == NSOKButton) {
        
        if ([self commitEditing] == NO) {
            NSBeep();
            return;
        }
        
        NSURL *url = nil;
        if ([urlString rangeOfString:@"://"].location == NSNotFound) {
            if ([[NSFileManager defaultManager] fileExistsAtPath:urlString])
                url = [NSURL fileURLWithPath:urlString];
            else
                url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", urlString]];
        } else
            url = [NSURL URLWithString:urlString];
        
        if(group == nil){
            group = [[BDSKURLGroup alloc] initWithURL:url];
        }else{
            [group setURL:url];
            [[group undoManager] setActionName:NSLocalizedString(@"Edit External File Group", @"Undo action name")];
        }
    }
    
    [super dismiss:sender];
}

- (void)chooseURLPanelDidEnd:(NSOpenPanel *)oPanel returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSOKButton) {
        NSURL *url = [[oPanel URLs] firstObject];
        [self setUrlString:[url absoluteString]];
    }
}

- (IBAction)chooseURL:(id)sender {
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    [oPanel setAllowsMultipleSelection:NO];
    [oPanel setResolvesAliases:NO];
    [oPanel setPrompt:NSLocalizedString(@"Choose", @"Prompt for Choose panel")];
    
    [oPanel beginSheetForDirectory:nil 
                              file:nil 
                    modalForWindow:[self window]
                     modalDelegate:self 
                    didEndSelector:@selector(chooseURLPanelDidEnd:returnCode:contextInfo:) 
                       contextInfo:nil];
}

- (BDSKURLGroup *)group {
    return group;
}

- (NSString *)urlString {
    return [[urlString retain] autorelease];
}

- (void)setUrlString:(NSString *)newUrlString {
    if (urlString != newUrlString) {
        [[[self undoManager] prepareWithInvocationTarget:self] setUrlString:urlString];
        [urlString release];
        urlString = [newUrlString copy];
        [[self undoManager] setActionName:NSLocalizedString(@"Edit URL", @"Undo action name")];
    }
}

#pragma mark NSEditorRegistration

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
    
    if ([NSString isEmptyString:urlString]) {
        NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Empty URL", @"Message in alert dialog when URL for external file group is invalid")
                                         defaultButton:nil
                                       alternateButton:nil
                                           otherButton:nil
                            informativeTextWithFormat:NSLocalizedString(@"Unable to create a group with an empty string", @"Informative text in alert dialog when URL for external file group is invalid")];
        [alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:NULL contextInfo:NULL];
        return NO;
    }
    return YES;
}

#pragma mark Dragging support

- (id)windowWillReturnFieldEditor:(NSWindow *)sender toObject:(id)anObject {
	if (dragFieldEditor == nil) {
		dragFieldEditor = [[BDSKFieldEditor alloc] init];
		[(BDSKFieldEditor *)dragFieldEditor registerForDelegatedDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, NSURLPboardType, BDSKWeblocFilePboardType, nil]];
	}
	return dragFieldEditor;
}

- (NSDragOperation)dragTextField:(BDSKDragTextField *)textField validateDrop:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard = [sender draggingPasteboard];
	NSString *dragType = [pboard availableTypeFromArray:[NSArray arrayWithObjects:BDSKWeblocFilePboardType, NSFilenamesPboardType, NSURLPboardType, nil]];
    
    return dragType ? NSDragOperationEvery : NSDragOperationNone;
}

- (BOOL)dragTextField:(BDSKDragTextField *)textField acceptDrop:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard = [sender draggingPasteboard];
	NSString *dragType = [pboard availableTypeFromArray:[NSArray arrayWithObjects:BDSKWeblocFilePboardType, NSFilenamesPboardType, NSURLPboardType, nil]];
    NSURL *url = nil;
    
    if ([dragType isEqualToString:NSFilenamesPboardType]) {
        NSArray *fileNames = [pboard propertyListForType:NSFilenamesPboardType];
        if ([fileNames count])
            url = [NSURL fileURLWithPath:[[fileNames objectAtIndex:0] stringByExpandingTildeInPath]]; 
    } else if ([dragType isEqualToString:NSURLPboardType]) {
        url = [NSURL URLFromPasteboard:pboard];
    } else if ([dragType isEqualToString:BDSKWeblocFilePboardType]) {
        url = [NSURL URLWithString:[pboard stringForType:BDSKWeblocFilePboardType]];
    }
    if (url) {
        [self setUrlString:[url absoluteString]];
        return YES;
    }
    return NO;
}

#pragma mark Undo support

- (NSUndoManager *)undoManager{
    if(undoManager == nil)
        undoManager = [[NSUndoManager alloc] init];
    return undoManager;
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)sender{
    return [self undoManager];
}

@end
