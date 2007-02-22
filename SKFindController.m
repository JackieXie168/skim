//
//  SKFindController.m
//  Skim
//
//  Created by Christiaan Hofman on 16/2/07.
/*
 This software is Copyright (c) 2007
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
#import "BDSKFindFieldEditor.h"
#import "SKDocument.h"
#import <Quartz/Quartz.h>


@implementation SKFindController

static id sharedFindController = nil;

+ (id)sharedFindController {
    if (sharedFindController == nil)
        sharedFindController = [[self alloc] init];
    return sharedFindController;
}

- (id)init {
    if (self = [super init]) {
        ignoreCase = YES;
    }
    return self;
}

- (void)dealloc {
    [fieldEditor release];
    [super dealloc];
}

- (id)retain {
    if (self == sharedFindController)
        return self;
    else
        return [super retain];
}

- (void)release {
    if (self != sharedFindController)
        [super release];
}

- (id)autorelease {
    if (self == sharedFindController)
        return self;
    else
        return [super autorelease];
}

- (NSString *)windowNibName { return @"FindPanel"; }

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
            [self setFindString:self];
            break;
		case NSFindPanelActionSelectAll:
		case NSFindPanelActionSelectAllInSelection:
            NSBeep();
            break;
	}
}

- (IBAction)findNext:(id)sender {
    [[self target] findString:[findField stringValue] options:[self findOptions] & ~NSBackwardsSearch];
}

- (IBAction)findNextAndOrderOutFindPanel:(id)sender {
	[self findNext:sender];
	[[self window] orderOut:self];
}

- (IBAction)findPrevious:(id)sender {
    [[self target] findString:[findField stringValue] options:[self findOptions] | NSBackwardsSearch];
}

- (IBAction)setFindString:(id)sender {
    id source = [self selectionSource];
    if (source) {
        PDFSelection *selection = [[source pdfView] currentSelection];
        if (selection == nil) {
            NSPasteboard *findPasteboard = [NSPasteboard pasteboardWithName:NSFindPboard];
            [findPasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
            [findPasteboard setString:[selection string] forType:NSStringPboardType];
        
            [findField setStringValue:[selection string]];
        }
    }
}

- (BOOL)ignoreCase {
    return ignoreCase;
}

- (void)setIgnoreCase:(BOOL)newIgnoreCase {
    if (ignoreCase != newIgnoreCase) {
        ignoreCase = newIgnoreCase;
    }
}

- (int)findOptions {
	int options = 0;
	
    if (ignoreCase)
        options |= NSCaseInsensitiveSearch;
    
	return options;
}

- (id)target {
    id target = [[NSApp mainWindow] windowController];
    if (target == nil)
        return nil;
    if ([target respondsToSelector:@selector(findString:options:)])
        return target;
    target = [target document];
    if ([target respondsToSelector:@selector(findString:options:)])
        return target;
    return nil;
}

- (id)selectionSource {
    id source = [[NSApp mainWindow] windowController];
    if (source == nil)
        return nil;
    if ([source respondsToSelector:@selector(pdfView)])
        return source;
    source = [source document];
    if ([source respondsToSelector:@selector(pdfView)])
        return source;
    return nil;
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
        fieldEditor = [[BDSKFindFieldEditor alloc] init];
    return fieldEditor;
}

@end
