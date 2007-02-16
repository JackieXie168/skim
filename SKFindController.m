//
//  SKFindController.m
//  Skim
//
//  Created by Christiaan Hofman on 16/2/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SKFindController.h"
#import "BDSKFindFieldEditor.h"
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
    if ([source respondsToSelector:@selector(pdfView:)])
        return source;
    source = [source document];
    if ([source respondsToSelector:@selector(pdfView:)])
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
