//
//  BDSKFindController.h
//  Bibdesk
//
//  Created by Adam Maxwell on 06/21/05.
//
/*
 This software is Copyright (c) 2005,2006,2007
 Adam Maxwell. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 - Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 - Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in
 the documentation and/or other materials provided with the
 distribution.
 
 - Neither the name of Adam Maxwell nor the names of any
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

#import <Cocoa/Cocoa.h>
#import <OmniFoundation/OmniFoundation.h>
#import "BDSKStatusBar.h"

@class BibDocument;

@interface BDSKFindController : NSWindowController {    
    // outlets
    IBOutlet NSComboBox *fieldToSearchComboBox;
    IBOutlet NSPopUpButton *searchTypePopUpButton;
    IBOutlet NSPopUpButton *searchScopePopUpButton;
    IBOutlet NSButton *ignoreCaseCheckbox;
    IBOutlet NSMatrix *searchSelectionMatrix;
    IBOutlet NSComboBox *findComboBox;
    IBOutlet NSComboBox *replaceComboBox;
    IBOutlet NSButton *findAsMacroCheckbox;
    IBOutlet NSButton *replaceAsMacroCheckbox;
    IBOutlet NSButton *replaceButton;
    IBOutlet NSView *controlsView;
    IBOutlet BDSKStatusBar *statusBar;

	
	NSTextView *findFieldEditor;
	NSMutableArray *findHistory;
	NSMutableArray *replaceHistory;
	NSString *findString;
	NSString *replaceString;
	int searchType;
	int searchScope;
	BOOL ignoreCase;
	BOOL wrapAround;
	BOOL searchSelection;
	BOOL findAsMacro;
	BOOL replaceAsMacro;
	BOOL overwrite;
	int shouldMove;
	NSString *replaceAllTooltip;
    CFArrayRef editors;
}

/*!
    @method     sharedFindController
    @abstract   Returns the shared instance of the find controller.  This object operates on the current
                document from the NSDocumentController.
    @discussion (comprehensive description)
    @result     (description)
*/
+ (BDSKFindController *)sharedFindController;

    /*!
    @method     updateUI
    @abstract   Call this after changing a UI element (button, field, etc); it performs some validation.
    @discussion (comprehensive description)
*/
- (void)updateUI;

- (BOOL)commitEditing;

/*!
    @method     regexIsValid:
    @abstract   Check to make sure the regular expression is valid.  AGRegex returns nil if the
                regex is not valid.
    @discussion (comprehensive description)
    @param      value (description)
    @result     (description)
*/
- (BOOL)regexIsValid:(NSString *)value;

/*!
    @method     stringIsValidAsComplexString:errorMessage:
    @abstract   Wrapper around exception handling to check for problems parsing the complex strings as
                BibTeX strings.  Returns an error message by reference if the string was not valid.
    @discussion (comprehensive description)
    @param      btstring BibTeX macro string
    @param      errString (description)
    @result     (description)
*/
- (BOOL)stringIsValidAsComplexString:(NSString *)btstring errorMessage:(NSString **)errString;

- (IBAction)openHelp:(id)sender;

- (NSString *)field;
- (void)setField:(NSString *)newFieldName;

- (NSString *)findString;
- (void)setFindString:(NSString *)newFindString;

- (NSString *)replaceString;
- (void)setReplaceString:(NSString *)newReplaceString;

- (int)searchType;
- (void)setSearchType:(int)newSearchType;

- (int)searchScope;
- (void)setSearchScope:(int)newSearchScope;

- (BOOL)ignoreCase;
- (void)setIgnoreCase:(BOOL)newIgnoreCase;

- (BOOL)wrapAround;
- (void)setWrapAround:(BOOL)newWrapAround;

- (BOOL)searchSelection;
- (void)setSearchSelection:(BOOL)newSearchSelection;

- (BOOL)findAsMacro;
- (void)setFindAsMacro:(BOOL)newFindAsMacro;

- (BOOL)replaceAsMacro;
- (void)setReplaceAsMacro:(BOOL)newReplaceAsMacro;

- (BOOL)overwrite;
- (void)setOverwrite:(BOOL)newOverwrite;

- (NSString *)replaceAllTooltip;
- (void)setReplaceAllTooltip:(NSString *)newReplaceAllTooltip;

- (BOOL)validateField:(id *)value error:(NSError **)error;
- (BOOL)validateFindString:(id *)value error:(NSError **)error;
- (BOOL)validateReplaceString:(id *)value error:(NSError **)error;
- (BOOL)validateSearchType:(id *)value error:(NSError **)error;
- (BOOL)validateSearchScope:(id *)value error:(NSError **)error;
- (BOOL)validateIgnoreCase:(id *)value error:(NSError **)error;
- (BOOL)validateSearchSelection:(id *)value error:(NSError **)error;
- (BOOL)validateFindAsMacro:(id *)value error:(NSError **)error;
- (BOOL)validateReplaceAsMacro:(id *)value error:(NSError **)error;
- (BOOL)validateOverwrite:(id *)value error:(NSError **)error;

- (NSArray *)findHistory;
- (unsigned)countOfFindHistory;
- (id)objectInFindHistoryAtIndex:(unsigned)index;
- (void)insertObject:(id)obj inFindHistoryAtIndex:(unsigned)index;
- (void)removeObjectFromFindHistoryAtIndex:(unsigned)index;

- (NSArray *)replaceHistory;
- (unsigned)countOfReplaceHistory;
- (id)objectInReplaceHistoryAtIndex:(unsigned)index;
- (void)insertObject:(id)obj inReplaceHistoryAtIndex:(unsigned)index;
- (void)removeObjectFromReplaceHistoryAtIndex:(unsigned)index;

- (IBAction)toggleStatusBar:(id)sender;

// general find panel action, the actual action depends on the sender's tag
- (IBAction)performFindPanelAction:(id)sender;

- (void)setFindFromSelection;

/*!
    @method     replace
    @abstract   Replaces in the selected item if there is a selection.
    @discussion (comprehensive description)
*/
- (void)replace;

/*!
    @method     findAndHighlightWithReplace:next:
    @abstract   Replaces in the selected item if there is a selection and replace is YES, then highlights the next match.
                Search wraps around by default.
    @discussion (comprehensive description)
    @param      replace (description)
    @param      next (description)
*/
- (void)findAndHighlightWithReplace:(BOOL)replace next:(BOOL)next;

/*!
    @method     replaceAllInSelection:
    @abstract   Replaces in all items. Uses the selected items if selected is YES, otherwise uses the current selection.
                Search wraps around by default.
    @discussion (comprehensive description)
    @param      selection (description)
*/
- (void)replaceAllInSelection:(BOOL)selection;

/*!
    @method     currentFoundItemsInDocument:
    @abstract   Returns an array of BibItems representing the current search results for the given document.
    @discussion (comprehensive description)
    @param      theDocument (description)
    @result     (description)
*/
- (NSArray *)currentFoundItemsInDocument:(BibDocument *)theDocument;

/*!
    @method     findAndReplaceInItems:ofDocument:
    @abstract   Does a find-and-replace on all the items in arrayOfPubs for the given document
    @discussion (comprehensive description)
    @param      arrayOfPubs Array of BibItems
    @param      theDocument The document containing the publications
    @result     The number of replacements made
*/
- (unsigned int)findAndReplaceInItems:(NSArray *)arrayOfPubs ofDocument:(BibDocument *)theDocument;

- (void)setField:field ofItem:bibItem toValue:newValue withInfos:(NSMutableArray *)paperInfos;

@end
