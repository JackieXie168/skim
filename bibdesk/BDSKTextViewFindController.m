//
//  BDSKTextViewFindController.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 4/6/06.
/*
 This software is Copyright (c) 2005,2006
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

#import "BDSKTextViewFindController.h"
#import <OmniAppKit/OAFindPattern.h>
#import <AGRegex/AGRegex.h>
#import "BDSKRegExFindPattern.h"
#import "BDSKFindFieldEditor.h"

/* Almost all of this code is copy-and-paste from OAFindController, except that we replace the findTypeMatrix by findTypePopUp and use our interface */

static NSString *BDSKTextViewFindPanelTitle = @"Find";

@interface BDSKTextViewFindController (Private)
- (void)loadInterface;
- (id <OAFindPattern>)currentPatternWithBackwardsFlag:(BOOL)backwardsFlag;
@end

@implementation BDSKTextViewFindController

- (id)init {
    if (self = [super init]) {
		findFieldEditor = nil;
    }
    return self;
}

- (void)dealloc {
    [findFieldEditor release];
    [super dealloc];
}

- (IBAction)performFindPanelAction:(id)sender;
{
	switch ([sender tag]) {
		case NSFindPanelActionShowFindPanel:
			[self showFindPanel:sender];
			break;
		case NSFindPanelActionNext:
			[self panelFindNext:sender];
			break;
		case NSFindPanelActionPrevious:
			[self panelFindPrevious:sender];
			break;
		case NSFindPanelActionReplaceAll:
			[self replaceAll:sender];
			break;
		case NSFindPanelActionReplace:
            [self replace:sender];
            break;
		case NSFindPanelActionReplaceAndFind:
			[self replaceAndFind:sender];
			break;
		case NSFindPanelActionSetFindString:
			[self enterSelection:sender];
			break;
		case NSFindPanelActionReplaceAllInSelection:
			[replaceInSelectionCheckbox setState:NSOnState];
			[self replaceAll:sender];
			break;
	}
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem{
    if ([menuItem action] == @selector(performFindPanelAction:)) {
		switch ([menuItem tag]) {
			case NSFindPanelActionShowFindPanel:
			case NSFindPanelActionNext:
			case NSFindPanelActionPrevious:
			case NSFindPanelActionReplaceAll:
			case NSFindPanelActionReplace:
			case NSFindPanelActionReplaceAndFind:
			case NSFindPanelActionSetFindString:
				return YES;
			default:
				return NO;
		}
	}
	return YES;
}

- (id)windowWillReturnFieldEditor:(NSWindow *)sender toObject:(id)anObject {
	if (findFieldEditor == nil) {
		findFieldEditor = [[BDSKFindFieldEditor alloc] initWithFrame:NSZeroRect];
	}
	return findFieldEditor;
}

- (IBAction)findTypeChanged:(id)sender;
{
    [wholeWordButton setEnabled:([[findTypePopUp selectedItem] tag] == 0)];
}

- (void)controlTextDidEndEditing:(NSNotification *)aNotification
{
    if ([[aNotification object] isEqual:searchTextForm]) {
        // validate the search string as a regex
        AGRegex *regex = [AGRegex regexWithPattern:[[searchTextForm cellAtIndex:0] stringValue]];
        if (regex == nil) {
            NSBeep();
            [findTypePopUp selectItemWithTag:0];
        }
    }
}

@end

@implementation BDSKTextViewFindController (Private)

// overwrite of private OAFindController methods, load our interface instead
- (void)loadInterface;
{
    [[NSBundle mainBundle] loadNibNamed:@"BDSKTextViewFindPanel.nib" owner:self];
    [replaceInSelectionCheckbox retain];
    [findPanel setFrameUsingName:BDSKTextViewFindPanelTitle];
    [findPanel setFrameAutosaveName:BDSKTextViewFindPanelTitle];
    [self findTypeChanged:self];
}

- (id <OAFindPattern>)currentPatternWithBackwardsFlag:(BOOL)backwardsFlag;
{
    id <OAFindPattern> pattern;
    NSString *findString;

    if ([findPanel isVisible])
        findString = [[searchTextForm cellAtIndex:0] stringValue];
    else
        findString = [self restoreFindText];
    [self saveFindText:findString];
        
    if (![findString length])
        return nil;

    if ([[findTypePopUp selectedItem] tag] == 0) {
        pattern = [[OAFindPattern alloc] initWithString:findString ignoreCase:[ignoreCaseButton state] wholeWord:[wholeWordButton state] backwards:backwardsFlag];
    } else {
        pattern = [[BDSKRegExFindPattern alloc] initWithString:findString ignoreCase:[ignoreCaseButton state] backwards:backwardsFlag];
    }
    
    [currentPattern release];
    currentPattern = pattern;
    return pattern;
}

@end
