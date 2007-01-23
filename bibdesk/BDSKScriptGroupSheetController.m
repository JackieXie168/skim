//
//  BDSKScriptGroupSheetController.m
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

#import "BDSKScriptGroupSheetController.h"
#import "BDSKScriptGroup.h"
#import "NSArray_BDSKExtensions.h"
#import "NSWorkspace_BDSKExtensions.h"
#import "BDSKFieldEditor.h"
#import "BDSKDragTextField.h"

static BOOL isAppleScriptAtPath(NSString *path)
{
    path = [path stringByStandardizingPath];
    NSString *theUTI = [[NSWorkspace sharedWorkspace] UTIForURL:[NSURL fileURLWithPath:path]];
    return theUTI ? (UTTypeConformsTo((CFStringRef)theUTI, CFSTR("com.apple.applescript.script")) ||
                     UTTypeConformsTo((CFStringRef)theUTI, CFSTR("com.apple.applescript.text"))) : NO;
}

static BOOL isFolderAtPath(NSString *path)
{
    path = [path stringByStandardizingPath];
    NSString *theUTI = [[NSWorkspace sharedWorkspace] UTIForURL:[NSURL fileURLWithPath:path]];
    return theUTI ? UTTypeEqual((CFStringRef)theUTI, kUTTypeFolder) : NO;
}

static BOOL isExecutableFileAtPath(NSString *path)
{
    path = [path stringByStandardizingPath];
    BOOL isExecutable = [[NSFileManager defaultManager] isExecutableFileAtPath:path];
    // exclude packages and directories, which are not executable data
    BOOL isDir;
    [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];
    return (isExecutable && NO == isDir);
}

@implementation BDSKScriptGroupSheetController

- (id)init {
    self = [self initWithGroup:nil];
    return self;
}

- (id)initWithGroup:(BDSKScriptGroup *)aGroup {
    if (self = [super init]) {
        group = [aGroup retain];
        path = [[group scriptPath] retain];
        arguments = [[group scriptArguments] retain];
        type = [group scriptType];
        undoManager = nil;
        dragFieldEditor = nil;
        editors = CFArrayCreateMutable(kCFAllocatorMallocZone, 0, NULL);
    }
    return self;
}

- (void)dealloc {
    [path release];
    [arguments release];
    [group release];
    [undoManager release];
    [dragFieldEditor release];
    CFRelease(editors);
    [super dealloc];
}

- (void)awakeFromNib {
    [pathField registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
}

- (NSString *)windowNibName {
    return @"BDSKScriptGroupSheet";
}

- (BOOL)isValidScriptFileAtPath:(NSString *)thePath error:(NSString **)message
{
    NSParameterAssert(nil != message);
    BOOL isValid;
    BOOL isDir;
    // path is bound to the text field and not validated, so we can get a tilde-path
    thePath = [thePath stringByStandardizingPath];
    if (NO == [[NSFileManager defaultManager] fileExistsAtPath:thePath isDirectory:&isDir]) {
        // no file; this will never work...
        isValid = NO;
        *message = NSLocalizedString(@"The specified file does not exist.", @"Error description");
    } else if (isDir) {
        // directories aren't scripts
        isValid = NO;
        *message = NSLocalizedString(@"The specified file is a directory, not a script file.", @"Error description");
    } else if (isExecutableFileAtPath(thePath) == NO && isAppleScriptAtPath(thePath) == NO) {
        // it's not executable
        isValid = NO;
        *message = NSLocalizedString(@"The file does not have execute permission set.", @"Error description");
    } else {
        isValid = YES;
    }

    return isValid;
}

- (IBAction)dismiss:(id)sender {
    if ([sender tag] == NSOKButton) {
        
        if ([self commitEditing] == NO)
            return;
        
        if (isAppleScriptAtPath([path stringByStandardizingPath]))
            type = BDSKAppleScriptType;
        else
            type = BDSKShellScriptType;
        
        if(group == nil){
            group = [[BDSKScriptGroup alloc] initWithScriptPath:path scriptArguments:arguments scriptType:type];
        }else{
            [group setScriptPath:path];
            [group setScriptArguments:arguments];
            [group setScriptType:type];
            [[group undoManager] setActionName:NSLocalizedString(@"Edit Script Group", @"Undo action name")];
        }
        
    }
    [super dismiss:sender];
}

- (void)chooseScriptPathPanelDidEnd:(NSOpenPanel *)oPanel returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSOKButton) {
        NSURL *url = [[oPanel URLs] firstObject];
        [self setPath:[url path]];
    }
}

// open panel delegate method
- (BOOL)panel:(id)sender shouldShowFilename:(NSString *)filename {
    return (isAppleScriptAtPath(filename) || isExecutableFileAtPath(filename) || isFolderAtPath(filename));        
}

- (IBAction)chooseScriptPath:(id)sender {
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    [oPanel setAllowsMultipleSelection:NO];
    [oPanel setResolvesAliases:NO];
    [oPanel setCanChooseDirectories:NO];
    [oPanel setPrompt:NSLocalizedString(@"Choose", @"Prompt for Choose panel")];
    [oPanel setDelegate:self];
    
    [oPanel beginSheetForDirectory:nil 
                              file:nil 
                    modalForWindow:[self window]
                     modalDelegate:self 
                    didEndSelector:@selector(chooseScriptPathPanelDidEnd:returnCode:contextInfo:) 
                       contextInfo:nil];
}

- (BDSKScriptGroup *)group {
    return group;
}

- (NSString *)path{
    return path;
}

- (void)setPath:(NSString *)newPath{
    if(path != newPath){
        [(BDSKScriptGroupSheetController *)[[self undoManager] prepareWithInvocationTarget:self] setPath:path];
        [path release];
        path = [newPath retain];
    }
}

- (NSString *)arguments{
    return arguments;
}

- (void)setArguments:(NSString *)newArguments{
    if(arguments != newArguments){
        [(BDSKScriptGroupSheetController *)[[self undoManager] prepareWithInvocationTarget:self] setArguments:arguments];
        [arguments release];
        arguments = [newArguments retain];
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
    
    NSString *errorMessage;
    if ([self isValidScriptFileAtPath:path error:&errorMessage] == NO) {
        NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Invalid Script Path", @"Message in alert dialog when path for script group is invalid")
                                         defaultButton:nil
                                       alternateButton:nil
                                           otherButton:nil
                            informativeTextWithFormat:errorMessage];
        [alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:NULL contextInfo:NULL];
        return NO;
    }
    
    return YES;
}

#pragma mark Dragging support

- (id)windowWillReturnFieldEditor:(NSWindow *)sender toObject:(id)anObject {
    if (anObject == pathField) {
        if (dragFieldEditor == nil) {
            dragFieldEditor = [[BDSKFieldEditor alloc] init];
            [(BDSKFieldEditor *)dragFieldEditor registerForDelegatedDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
        }
        return dragFieldEditor;
    }
    return nil;
}

- (NSDragOperation)dragTextField:(BDSKDragTextField *)textField validateDrop:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard = [sender draggingPasteboard];
	NSString *dragType = [pboard availableTypeFromArray:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
    
    return dragType ? NSDragOperationEvery : NSDragOperationNone;
}

- (BOOL)dragTextField:(BDSKDragTextField *)textField acceptDrop:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard = [sender draggingPasteboard];
    
    if ([pboard availableTypeFromArray:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]]) {
        NSArray *fileNames = [pboard propertyListForType:NSFilenamesPboardType];
        if ([fileNames count]) {
            NSString *thePath = [[fileNames objectAtIndex:0] stringByExpandingTildeInPath];
            NSString *message = nil;
            if ([self isValidScriptFileAtPath:thePath error:&message]) {
                [self setPath:thePath];
                return YES;
            }
        }
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
