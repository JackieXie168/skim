//
//  SKFindController.m
//  Skim
//
//  Created by Christiaan Hofman on 16/2/07.
/*
 This software is Copyright (c) 2007-2010
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

#import "SKFindController.h"
#import "SKFindFieldEditor.h"
#import "NSGeometry_SKExtensions.h"

#define SKFindPanelFrameAutosaveName @"SKFindPanel"

@implementation SKFindController

@synthesize findField, ignoreCaseCheckbox, ownerController, labelField, buttons, findString, ignoreCase;
@dynamic findOptions, target, selectionSource;

+ (id)sharedFindController {
    static SKFindController *sharedFindController = nil;
    if (sharedFindController == nil)
        sharedFindController = [[self alloc] init];
    return sharedFindController;
}

- (id)init {
    if (self = [super initWithWindowNibName:@"FindPanel"]) {
        ignoreCase = YES;
    }
    return self;
}

- (void)dealloc {
    SKDESTROY(findString);
    SKDESTROY(fieldEditor);
    SKDESTROY(findField);
    SKDESTROY(ignoreCaseCheckbox);
    SKDESTROY(ownerController);
    SKDESTROY(labelField);
    SKDESTROY(buttons);
    [super dealloc];
}

- (void)windowDidLoad {
    SKAutoSizeButtons(buttons, YES);
    SKAutoSizeLabelFields([NSArray arrayWithObjects:labelField, nil], [NSArray arrayWithObjects:findField, ignoreCaseCheckbox, nil], YES);
    
    [self setWindowFrameAutosaveName:SKFindPanelFrameAutosaveName];
    
    [[self window] setCollectionBehavior:NSWindowCollectionBehaviorMoveToActiveSpace];
}

- (void)windowDidBecomeKey:(NSNotification *)notification {
    NSPasteboard *findPboard = [NSPasteboard pasteboardWithName:NSFindPboard];
    if (lastChangeCount < [findPboard changeCount] && [findPboard availableTypeFromArray:[NSArray arrayWithObject:NSStringPboardType]]) {
        [self setFindString:[findPboard stringForType:NSStringPboardType]];
        lastChangeCount = [findPboard changeCount];
    }
}

- (void)updateFindPboard {
    NSPasteboard *findPboard = [NSPasteboard pasteboardWithName:NSFindPboard];
    [findPboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
    [findPboard setString:findString forType:NSStringPboardType];
    lastChangeCount = [findPboard changeCount];
}

- (IBAction)performFindPanelAction:(id)sender {
	switch ([sender tag]) {
		case NSFindPanelActionShowFindPanel:
            [[self window] makeKeyAndOrderFront:self];
            break;
		case NSFindPanelActionNext:
            [self findNext:sender];
            break;
		case NSFindPanelActionPrevious:
            [self findPrevious:sender];
            break;
		case NSFindPanelActionReplaceAll:
		case NSFindPanelActionReplace:
		case NSFindPanelActionReplaceAndFind:
		case NSFindPanelActionReplaceAllInSelection:
            NSBeep();
            break;
		case NSFindPanelActionSetFindString:
            [self pickFindString:self];
            break;
		case NSFindPanelActionSelectAll:
		case NSFindPanelActionSelectAllInSelection:
            NSBeep();
            break;
	}
}

- (IBAction)findNext:(id)sender {
    [ownerController commitEditing];
    if ([findString length]) {
        [[self target] findString:findString options:[self findOptions] & ~NSBackwardsSearch];
        [self updateFindPboard];
    }
}

- (IBAction)findNextAndOrderOutFindPanel:(id)sender {
	[self findNext:sender];
	[[self window] orderOut:self];
}

- (IBAction)findPrevious:(id)sender {
    [ownerController commitEditing];
    if ([findString length]) {
        [[self target] findString:findString options:[self findOptions] | NSBackwardsSearch];
        [self updateFindPboard];
    }
}

- (IBAction)pickFindString:(id)sender {
    NSString *string = [[self selectionSource] findString];
    if (string) {
        [self setFindString:string];
        [self updateFindPboard];
    }
}

- (NSInteger)findOptions {
	NSInteger options = 0;
	
    if (ignoreCase)
        options |= NSCaseInsensitiveSearch;
    
	return options;
}

static id responderForSelector(SEL selector) {
    id responder = [[NSApp mainWindow] windowController];
    if (responder == nil)
        return nil;
    if ([responder respondsToSelector:selector])
        return responder;
    responder = [responder document];
    if ([responder respondsToSelector:selector])
        return responder;
    return nil;
}

- (id)target {
    return responderForSelector(@selector(findString:options:));
}

- (id)selectionSource {
    return responderForSelector(@selector(findString));
}

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem {
	if ([anItem action] == @selector(performFindPanelAction:)) {
        switch ([anItem tag]) {
            case NSFindPanelActionShowFindPanel:
                return YES;
            case NSFindPanelActionNext:
            case NSFindPanelActionPrevious:
                return [[findField stringValue] length] > 0;
            case NSFindPanelActionReplaceAll:
            case NSFindPanelActionReplace:
            case NSFindPanelActionReplaceAndFind:
            case NSFindPanelActionReplaceAllInSelection:
                return NO;
            case NSFindPanelActionSetFindString:
                return [self selectionSource] != nil;
            case NSFindPanelActionSelectAll:
            case NSFindPanelActionSelectAllInSelection:
                return NO;
        }
	}
	
	return YES;
}

- (id)windowWillReturnFieldEditor:(NSWindow *)sender toObject:(id)anObject {
    if (fieldEditor == nil)
        fieldEditor = [[SKFindFieldEditor alloc] init];
    return fieldEditor;
}

@end
