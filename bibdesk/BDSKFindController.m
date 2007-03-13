//
//  BDSKFindController.m
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

#import "BDSKFindController.h"
#import "BibTypeManager.h"
#import "BibDocument.h"
#import "BDSKComplexString.h"
#import "BibDocument+Scripting.h"
#import "BibDocument_Search.h"
#import "BibDocument_Groups.h"
#import "BDSKFieldNameFormatter.h"
#import <AGRegex/AGRegex.h>
#import "BibItem.h"
#import "BibFiler.h"
#import "BDSKAlert.h"
#import "BDSKFindFieldEditor.h"

#define MAX_HISTORY_COUNT	10

static BDSKFindController *sharedFC = nil;

enum {
    FCTextualSearch = 0,
    FCRegexSearch = 1
};

enum {
    FCContainsSearch = 0,
    FCStartsWithSearch = 1,
    FCWholeFieldSearch = 2,
    FCEndsWithSearch = 3,
};

enum {
    FCOperationFindAndReplace = 0,
    FCOperationOverwrite = 1,
    FCOperationPrepend = 2,
    FCOperationAppend = 3,
};

@implementation BDSKFindController

+ (BDSKFindController *)sharedFindController{
    if(sharedFC == nil)
        sharedFC = [[BDSKFindController alloc] init];
    return sharedFC;
}

- (id)init {
    if (self = [super initWithWindowNibName:@"BDSKFindPanel"]) {
		NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSFindPboard];
		NSString *availableType = [pboard availableTypeFromArray:[NSArray arrayWithObject:NSStringPboardType]];
        
		findFieldEditor = nil;
		
		findHistory = [[NSMutableArray alloc] initWithCapacity:MAX_HISTORY_COUNT == NSNotFound ? 10 : MAX_HISTORY_COUNT];
		replaceHistory = [[NSMutableArray alloc] initWithCapacity:MAX_HISTORY_COUNT == NSNotFound ? 10 : MAX_HISTORY_COUNT];
        
		findString = [((availableType == nil)? @"" : [pboard stringForType:NSStringPboardType]) copy];
        replaceString = [@"" retain];
        searchType = FCTextualSearch;
        searchScope = FCContainsSearch;
        ignoreCase = YES;
        wrapAround = YES;
        searchSelection = YES;
        findAsMacro = NO;
        replaceAsMacro = NO;
		overwrite = NO;
        operation = FCOperationFindAndReplace;
		
		NSString *field = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKFindControllerLastFindAndReplaceFieldKey];
		if([field isLocalFileField])
			shouldMove = NSMixedState;
		else
			shouldMove = NSOffState;
		
		replaceAllTooltip = [NSLocalizedString(@"Replace all matches.", @"Tool tip message") retain];
		
        editors = CFArrayCreateMutable(kCFAllocatorMallocZone, 0, NULL);
    }
    return self;
}

- (void)dealloc {
	[findFieldEditor release];
    [findString release];
    [replaceString release];
	[statusBar release];
	[replaceAllTooltip release];
    CFRelease(editors);
    [super dealloc];
}

- (void)awakeFromNib{
    BibTypeManager *btm = [BibTypeManager sharedManager];
    NSArray *fields = [btm allFieldNamesIncluding:[[btm noteFieldsSet] allObjects] excluding:nil];
	[fieldToSearchComboBox removeAllItems];
	[fieldToSearchComboBox addItemsWithObjectValues:fields];

    // make sure we enter valid field names
    BDSKFieldNameFormatter *formatter = [[BDSKFieldNameFormatter alloc] init];
    [fieldToSearchComboBox setFormatter:formatter];
    [formatter release];
	
	[statusBar retain]; // we need to retain, as we might remove it from the window
	if (![[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKShowFindStatusBarKey]) {
		[self toggleStatusBar:nil];
	}
	[statusBar setProgressIndicatorStyle:BDSKProgressIndicatorSpinningStyle];
    
	// IB does not allow us to set the maxSize.height equal to the minSize.height for some reason, but it should be only horizontally resizable
	NSSize maxSize = [[self window] maxSize];
	maxSize.height = [[self window] minSize].height;
	[[self window] setMaxSize:maxSize];
	
	// this fixes a bug with initialization of the menuItem states when using bindings
	int numItems = [searchTypePopUpButton numberOfItems];
	int i;
	for (i = 0; i < numItems; i++) 
		if ([searchTypePopUpButton indexOfSelectedItem] != i)
			[[searchTypePopUpButton itemAtIndex:i] setState:NSOffState];
	numItems = [searchScopePopUpButton numberOfItems];
	for (i = 0; i < numItems; i++) 
		if ([searchScopePopUpButton indexOfSelectedItem] != i)
			[[searchScopePopUpButton itemAtIndex:i] setState:NSOffState];
	
    [self updateUI];
}

// no surprises from replacing unseen items!
- (void)clearFrontDocumentQuickSearch{
    BibDocument *doc = [[NSDocumentController sharedDocumentController] currentDocument];
    [doc setSearchString:@""];
}

- (void)updateUI{
	if(NO == [self findAsMacro] && [self replaceAsMacro] && FCOperationFindAndReplace == [self operation]){
        [searchScopePopUpButton setEnabled:NO];
		[statusBar setStringValue:NSLocalizedString(@"With these settings, only full strings will be replaced", @"Status message")];
	}else{
        [searchScopePopUpButton setEnabled:FCOperationFindAndReplace == [self operation]];
		[statusBar setStringValue:@""];
    }
    
	if (FCOperationOverwrite == [self operation]) {
		[self setReplaceLabel:NSLocalizedString(@"Value to set:", @"Label message")];
        if ([self searchSelection])
			[self setReplaceAllTooltip:NSLocalizedString(@"Overwrite or add the field in all selected publications.", @"Tool tip message")];
		else
			[self setReplaceAllTooltip:NSLocalizedString(@"Overwrite or add the field in all publications.", @"Tool tip message")];
	} else if (FCOperationPrepend == [self operation]) {
		[self setReplaceLabel:NSLocalizedString(@"Prefix to add:", @"Label message")];
		if ([self searchSelection])
			[self setReplaceAllTooltip:NSLocalizedString(@"Add a suffix to the field in all selected publications.", @"Tool tip message")];
		else
			[self setReplaceAllTooltip:NSLocalizedString(@"Add a suffix to the field in all publications.", @"Tool tip message")];
	} else if (FCOperationAppend == [self operation]) {
		[self setReplaceLabel:NSLocalizedString(@"Suffix to add:", @"Label message")];
		if ([self searchSelection])
			[self setReplaceAllTooltip:NSLocalizedString(@"Add a prefix to the field in all selected publications.", @"Tool tip message")];
		else
			[self setReplaceAllTooltip:NSLocalizedString(@"Add a prefix to the field in all publications.", @"Tool tip message")];
	} else {
		[self setReplaceLabel:NSLocalizedString(@"Replace with:", @"Label message")];
		if ([self searchSelection])
			[self setReplaceAllTooltip:NSLocalizedString(@"Replace all matches in all selected publications.", @"Tool tip message")];
		else
			[self setReplaceAllTooltip:NSLocalizedString(@"Replace all matches in all publications.", @"Tool tip message")];
	}
}

- (void)windowDidBecomeKey:(NSNotification *)aNotification{
	[self updateUI];
}

#pragma mark Accessors

- (int)operation {
    return operation;
}

- (void)setOperation:(int)newOperation {
    if (operation != newOperation) {
        operation = newOperation;
		if (FCOperationFindAndReplace != operation) {
			[self setSearchSelection:YES];
			[self setFindString:@""];
		}
		[self updateUI];
    }
}

- (NSString *)field {
    return [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKFindControllerLastFindAndReplaceFieldKey];
}

- (void)setField:(NSString *)newField {
    [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:newField forKey:BDSKFindControllerLastFindAndReplaceFieldKey];
	if([newField isLocalFileField])
		shouldMove = NSMixedState;
	else
		shouldMove = NSOffState;
}

- (NSString *)findString {
	if (findString == nil)
		return @"";
    return [[findString retain] autorelease];
}

- (void)setFindString:(NSString *)newFindString {
    if (findString != newFindString) {
        [findString release];
        findString = [newFindString copy];
		[self insertObject:newFindString inFindHistoryAtIndex:0];
		
		NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSFindPboard];
		[pboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
		[pboard setString:findString forType:NSStringPboardType];
    }
}

- (NSString *)replaceString {
	if (replaceString == nil)
		return @"";
    return [[replaceString retain] autorelease];
}

- (void)setReplaceString:(NSString *)newReplaceString {
    if (replaceString != newReplaceString) {
        [replaceString release];
        replaceString = [newReplaceString copy];
		[self insertObject:newReplaceString inReplaceHistoryAtIndex:0];
    }
}

- (int)searchType {
    return searchType;
}

- (void)setSearchType:(int)newSearchType {
    if (searchType != newSearchType) {
        searchType = newSearchType;
    }
}

- (int)searchScope {
    return searchScope;
}

- (void)setSearchScope:(int)newSearchScope {
    if (searchScope != newSearchScope) {
        searchScope = newSearchScope;
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

- (BOOL)wrapAround {
    return wrapAround;
}

- (void)setWrapAround:(BOOL)newWrapAround {
    if (wrapAround != newWrapAround) {
        wrapAround = newWrapAround;
    }
}

- (BOOL)searchSelection {
    return searchSelection;
}

- (void)setSearchSelection:(BOOL)newSearchSelection {
    if (searchSelection != newSearchSelection) {
        searchSelection = newSearchSelection;
		[self updateUI];
    }
}

- (BOOL)findAsMacro {
    return findAsMacro;
}

- (void)setFindAsMacro:(BOOL)newFindAsMacro {
    if (findAsMacro != newFindAsMacro) {
        findAsMacro = newFindAsMacro;
		[self updateUI];
    }
}

- (BOOL)replaceAsMacro {
    return replaceAsMacro;
}

- (void)setReplaceAsMacro:(BOOL)newReplaceAsMacro {
    if (replaceAsMacro != newReplaceAsMacro) {
        replaceAsMacro = newReplaceAsMacro;
		[self updateUI];
    }
}

- (BOOL)overwrite {
	return overwrite;
}

- (void)setOverwrite:(BOOL)newOverwrite {
    if (overwrite != newOverwrite) {
        overwrite = newOverwrite;
		if (overwrite == YES) {
			[self setSearchSelection:YES];
			[self setFindString:@""];
		}
		[self updateUI];
    }
}

- (NSString *)replaceAllTooltip {
    return [[replaceAllTooltip retain] autorelease];
}

- (void)setReplaceAllTooltip:(NSString *)newReplaceAllTooltip {
    if (replaceAllTooltip != newReplaceAllTooltip) {
        [replaceAllTooltip release];
        replaceAllTooltip = [newReplaceAllTooltip copy];
    }
}

- (NSString *)replaceLabel {
    return [[replaceLabel retain] autorelease];
}

- (void)setReplaceLabel:(NSString *)newReplaceLabel {
    if (replaceLabel != newReplaceLabel) {
        [replaceLabel release];
        replaceLabel = [newReplaceLabel copy];
    }
}

#pragma mark Array accessors

- (NSArray *)findHistory {
    return [[findHistory retain] autorelease];
}

- (unsigned)countOfFindHistory {
    return [findHistory count];
}

- (id)objectInFindHistoryAtIndex:(unsigned)index {
    return [findHistory objectAtIndex:index];
}

- (void)insertObject:(id)obj inFindHistoryAtIndex:(unsigned)index {
    if ([NSString isEmptyString:obj] || [findHistory containsObject:obj])
		return;
	[findHistory insertObject:obj atIndex:index];
	int count = [findHistory count];
	if (count > MAX_HISTORY_COUNT)
		[findHistory removeObjectAtIndex:count - 1];
}

- (void)removeObjectFromFindHistoryAtIndex:(unsigned)index {
    [findHistory removeObjectAtIndex:index];
}

- (NSArray *)replaceHistory {
    return [[replaceHistory retain] autorelease];
}

- (unsigned)countOfReplaceHistory {
    return [replaceHistory count];
}

- (id)objectInReplaceHistoryAtIndex:(unsigned)index {
    return [replaceHistory objectAtIndex:index];
}

- (void)insertObject:(id)obj inReplaceHistoryAtIndex:(unsigned)index {
    if ([NSString isEmptyString:obj] || [replaceHistory containsObject:obj])
		return;
	[replaceHistory insertObject:obj atIndex:index];
	int count = [findHistory count];
	if (count > MAX_HISTORY_COUNT)
		[replaceHistory removeObjectAtIndex:count - 1];
}

- (void)removeObjectFromReplaceHistoryAtIndex:(unsigned)index {
    [replaceHistory removeObjectAtIndex:index];
}

#pragma mark Validation

- (BOOL)validateField:(id *)value error:(NSError **)error {
    // this should have be handled by the formatter
	return YES;
}

- (BOOL)validateFindString:(id *)value error:(NSError **)error {
	if ([self searchType] == FCRegexSearch) { // check the regex
		if ([self regexIsValid:*value] == NO) {
            if(error != nil){
                NSString *description = NSLocalizedString(@"Invalid Regular Expression.", @"Error description");
                NSString *reason = NSLocalizedString(@"The regular expression you entered is not valid.", @"Error reason");
                NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:description, NSLocalizedDescriptionKey, reason, NSLocalizedFailureReasonErrorKey, nil];
                *error = [NSError errorWithDomain:@"BDSKFindErrorDomain" code:1 userInfo:userInfo];
            }
			return NO;
		}
	} else if([self findAsMacro] == YES) { // check the "find" complex string
		NSString *reason = nil;
		if ([self stringIsValidAsComplexString:*value errorMessage:&reason] == NO) {
            if(error != nil){
                NSString *description = NSLocalizedString(@"Invalid BibTeX Macro.", @"Error description");
                NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:description, NSLocalizedDescriptionKey, reason, NSLocalizedFailureReasonErrorKey, nil];
                *error = [NSError errorWithDomain:@"BDSKFindErrorDomain" code:1 userInfo:userInfo];
            }
			return NO;
		}
	}  
    return YES;
}

- (BOOL)validateReplaceString:(id *)value error:(NSError **)error {
	NSString *reason = nil;
	if ([self searchType] == FCTextualSearch && [self replaceAsMacro] == YES && 
		[self stringIsValidAsComplexString:*value errorMessage:&reason] == NO) {
        if(error != nil){
            NSString *description = NSLocalizedString(@"Invalid BibTeX Macro.", @"Error description");
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:description, NSLocalizedDescriptionKey, reason, NSLocalizedFailureReasonErrorKey, nil];
            *error = [NSError errorWithDomain:@"BDSKFindErrorDomain" code:1 userInfo:userInfo];
        }
		return NO;
	}
    return YES;
}

- (BOOL)validateSearchType:(id *)value error:(NSError **)error {
    if ([*value intValue] == FCRegexSearch && 
		[self regexIsValid:[self findString]] == NO) {
        if(error != nil){
            NSString *description = NSLocalizedString(@"Invalid Regular Expression.", @"Error description");
            NSString *reason = [NSString stringWithFormat:NSLocalizedString(@"The entry \"%@\" is not a valid regular expression.", @"Error reason"), [self findString]];
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:description, NSLocalizedDescriptionKey, reason, NSLocalizedFailureReasonErrorKey, nil];
            *error = [NSError errorWithDomain:@"BDSKFindErrorDomain" code:1 userInfo:userInfo];
        }
		[findComboBox selectText:self];
		return NO;
    }
    return YES;
}

- (BOOL)validateSearchScope:(id *)value error:(NSError **)error {
    return YES;
}

- (BOOL)validateIgnoreCase:(id *)value error:(NSError **)error {
    return YES;
}

- (BOOL)validateSearchSelection:(id *)value error:(NSError **)error {
    return YES;
}

- (BOOL)validateFindAsMacro:(id *)value error:(NSError **)error {
	NSString *reason = nil;
    if ([*value boolValue] == YES && [self searchType] == FCTextualSearch &&
	    [self stringIsValidAsComplexString:[self findString] errorMessage:&reason] == NO) {
        if(error != nil){
            NSString *description = NSLocalizedString(@"Invalid BibTeX Macro", @"Error description");
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:description, NSLocalizedDescriptionKey, reason, NSLocalizedFailureReasonErrorKey, nil];
            *error = [NSError errorWithDomain:@"BDSKFindErrorDomain" code:1 userInfo:userInfo];
        }
		[findComboBox selectText:self];
		return NO;
    }
    return YES;
}

- (BOOL)validateReplaceAsMacro:(id *)value error:(NSError **)error {
	NSString *reason = nil;
    if([*value boolValue] == YES && [self searchType] == FCTextualSearch &&
	   [self stringIsValidAsComplexString:[self replaceString] errorMessage:&reason] == NO){
        if(error != nil){
            NSString *description = NSLocalizedString(@"Invalid BibTeX Macro", @"Error description");
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:description, NSLocalizedDescriptionKey, reason, NSLocalizedFailureReasonErrorKey, nil];
            *error = [NSError errorWithDomain:@"BDSKFindErrorDomain" code:1 userInfo:userInfo];
        }
		[replaceComboBox selectText:self];
		return NO;
    }
    return YES;
}

- (BOOL)validateOperation:(id *)value error:(NSError **)error {
	return YES;
}

- (BOOL)regexIsValid:(NSString *)value{
    AGRegex *testRegex = [AGRegex regexWithPattern:value];
    if(testRegex == nil)
        return NO;
    
    return YES;
}

- (BOOL)stringIsValidAsComplexString:(NSString *)btstring errorMessage:(NSString **)errString{
    BOOL valid = YES;
    volatile BDSKComplexString *compStr;
    NSString *reason = nil;    
    
    NS_DURING
        compStr = [NSString stringWithBibTeXString:btstring macroResolver:nil];
    NS_HANDLER
        if([[localException name] isEqualToString:BDSKComplexStringException]){
            valid = NO;
            reason = [localException reason];
        } else {
            [localException raise];
        }
    NS_ENDHANDLER
    
    if(!valid && errString != nil){
        if(reason == nil)
            reason = @"Complex string is invalid for unknown reason"; // shouldn't happen
        
        *errString = reason;
    }
    return valid;
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem{
    if ([menuItem action] == @selector(toggleStatusBar:)) {
		if ([statusBar isVisible]) {
			[menuItem setTitle:NSLocalizedString(@"Hide Status Bar", @"Menu item title")];
		} else {
			[menuItem setTitle:NSLocalizedString(@"Show Status Bar", @"Menu item title")];
		}
		return YES;
    } else if ([menuItem action] == @selector(performFindPanelAction:)) {
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
    
    return YES;
}

#pragma mark Action methods

- (IBAction)openHelp:(id)sender{
    NSString *helpBookName = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleHelpBookName"];
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"FindAndReplace" inBook:helpBookName];
}

- (IBAction)toggleStatusBar:(id)sender{
	[statusBar toggleInWindow:[self window] offset:1.0];
	[[OFPreferenceWrapper sharedPreferenceWrapper] setBool:[statusBar isVisible] forKey:BDSKShowFindStatusBarKey];
}

#pragma mark Find and Replace Action methods

- (IBAction)performFindPanelAction:(id)sender{
	switch ([sender tag]) {
		case NSFindPanelActionShowFindPanel:
			[[self window] makeKeyAndOrderFront:sender];
			break;
		case NSFindPanelActionNext:
			[self findAndHighlightWithReplace:NO next:YES];
			break;
		case NSFindPanelActionPrevious:
			[self findAndHighlightWithReplace:NO next:NO];
			break;
		case NSFindPanelActionReplaceAll:
			[self replaceAllInSelection:NO];
			break;
		case NSFindPanelActionReplace:
			[self replace];
			break;
		case NSFindPanelActionReplaceAndFind:
			[self findAndHighlightWithReplace:YES next:YES];
			break;
		case NSFindPanelActionSetFindString:
			[self setFindFromSelection];
			// nothing to support here, as we have no selection
			break;
		case NSFindPanelActionReplaceAllInSelection:
			[self replaceAllInSelection:YES];
			break;
	}
}

#pragma mark Find and Replace implementation

- (void)setFindFromSelection{
    BibDocument *theDocument = [[NSDocumentController sharedDocumentController] currentDocument];
    if(!theDocument){
        NSBeep();
		return;
	}
	NSString *selString = [theDocument selectedStringForFind];
	if ([NSString isEmptyString:selString]){
        NSBeep();
		return;
	}
	[self setFindString:selString];
}

- (void)replace{
	[statusBar setStringValue:@""];
    
    BibDocument *theDocument = [[NSDocumentController sharedDocumentController] currentDocument];
    if(!theDocument){
        NSBeep();
		[statusBar setStringValue:NSLocalizedString(@"No document selected", @"Status message")];
        return;
	}else if([theDocument hasExternalGroupsSelected]){
        NSBeep();
		[statusBar setStringValue:NSLocalizedString(@"Cannot replace in external items", @"Status message")];
        return;
	}
    
    BibItem *selItem = [[[theDocument selectedPublications] objectEnumerator] nextObject];
    
    if(selItem == nil){
        NSBeep();
		[statusBar setStringValue:NSLocalizedString(@"Nothing selected", @"Status message")];
        return;
    }

    [self findAndReplaceInItems:[NSArray arrayWithObject:selItem] ofDocument:theDocument];
    // make sure we only highlight this item
    [theDocument selectPublication:selItem];
}

- (void)findAndHighlightWithReplace:(BOOL)replace next:(BOOL)next{
	[statusBar setStringValue:@""];
    
    BibDocument *theDocument = [[NSDocumentController sharedDocumentController] currentDocument];
    if(!theDocument){
        NSBeep();
		[statusBar setStringValue:NSLocalizedString(@"No document selected", @"Status message")];
        return;
	}else if(replace && ([theDocument hasExternalGroupsSelected])){
        NSBeep();
		[statusBar setStringValue:NSLocalizedString(@"Cannot replace in external items", @"Status message")];
        return;
    }else if([self commitEditing] == NO){
        NSBeep();
		[statusBar setStringValue:NSLocalizedString(@"There were invalid values", @"Status message")];
        return;
    }
    
    [self clearFrontDocumentQuickSearch];
   
    // this can change between clicks of the Find button, so we can't cache it
    NSArray *currItems = [self currentFoundItemsInDocument:theDocument];
    //NSLog(@"currItems has %@", currItems);
    if(currItems == nil){
        NSBeep();
		[statusBar setStringValue:NSLocalizedString(@"Nothing found", @"Status message")];
        return;
    }

    NSEnumerator *selPubE = [[theDocument selectedPublications] objectEnumerator];
    BibItem *selItem = [selPubE nextObject];
    unsigned indexOfSelectedItem;
    if(selItem == nil){ // no selection, so select the first one
        indexOfSelectedItem = 0;
    } else {        
        // see if the selected pub is one of the current found items, or just some random item
        indexOfSelectedItem = [[theDocument displayedPublications] indexOfObjectIdenticalTo:selItem];
        
        // if we're doing a replace & find, we need to replace in this item before we change the selection
        if(replace){
            [self findAndReplaceInItems:[NSArray arrayWithObject:selItem] ofDocument:theDocument];
		}
        
        // see if current search results have an item identical to the selected one
        indexOfSelectedItem = [currItems indexOfObjectIdenticalTo:selItem];
        if(indexOfSelectedItem != NSNotFound){ // we've already selected an item from the search results...so select the next one
            if(next){
				if(++indexOfSelectedItem == [currItems count])
					indexOfSelectedItem = wrapAround ? 0 : NSNotFound; // wrap around
			}else{
				if(indexOfSelectedItem-- == 0)
					indexOfSelectedItem = wrapAround ? [currItems count] - 1 : NSNotFound; // wrap around
			}
        } else {
            // the selected pub was some item we don't care about, so select item 0
            indexOfSelectedItem = 0;
        }
    }
    
    if(indexOfSelectedItem != NSNotFound) {
        [theDocument selectPublication:[currItems objectAtIndex:indexOfSelectedItem]];
    } else {
        NSBeep();
		[statusBar setStringValue:NSLocalizedString(@"Nothing found", @"Status message")];
    }
}

- (void)replaceAllInSelection:(BOOL)selection{
	if (selection == YES)
		[self setSearchSelection:YES];
	[statusBar setStringValue:@""];
	
    BibDocument *theDocument = [[NSDocumentController sharedDocumentController] currentDocument];
    if(!theDocument){
        NSBeep();
		[statusBar setStringValue:NSLocalizedString(@"No document selected", @"Status message")];
        return;
	}else if([theDocument hasExternalGroupsSelected]){
        NSBeep();
		[statusBar setStringValue:NSLocalizedString(@"Cannot replace in external items", @"Status message")];
        return;
    }else if([self commitEditing] == NO){
        NSBeep();
		[statusBar setStringValue:NSLocalizedString(@"There were invalid values", @"Status message")];
        return;
	}
	
	[statusBar startAnimation:nil];
	
    [self clearFrontDocumentQuickSearch];

    NSArray *publications;
    NSArray *shownPublications = [theDocument displayedPublications];
    
    if([self searchSelection]){
        // if we're only doing a find/replace in the selected publications
        publications = [theDocument selectedPublications];
    } else {
        // we're doing a find/replace in all the document pubs
        publications = shownPublications; // we're not changing it; the cast just shuts gcc up
    }
    
	[self findAndReplaceInItems:publications ofDocument:theDocument];
	
	[statusBar stopAnimation:nil];
}

- (AGRegex *)currentRegex{
	// current regex including string and/or node boundaries and case sensitivity
	
	if(!findAsMacro && replaceAsMacro)
		searchScope = FCWholeFieldSearch; // we can only reliably replace a complete string by a macro
    
	NSString *regexFormat = nil;
	
	// set string and/or node boundaries in the regex
	switch(searchScope){
		case FCContainsSearch:
			regexFormat = (findAsMacro) ? @"(?<=^|\\s#\\s)%@(?=$|\\s#\\s)" : @"%@";
			break;
		case FCStartsWithSearch:
			regexFormat = (findAsMacro) ? @"(?<=^)%@(?=$|\\s#\\s)" : @"(?<=^)%@";
			break;
		case FCWholeFieldSearch:
			regexFormat = @"(?<=^)%@(?=$)";
			break;
		case FCEndsWithSearch:
			regexFormat = (findAsMacro) ? @"(?<=^|\\s#\\s)%@(?=$)" : @"%@(?=$)";
			break;
	}
	
	return [AGRegex regexWithPattern:[NSString stringWithFormat:regexFormat, findString] 
							 options:(ignoreCase ? AGRegexCaseInsensitive : 0)];
}

- (NSArray *)currentStringFoundItemsInDocument:(BibDocument *)theDocument{
	// found items using BDSKComplexString methods
    NSString *findStr = [self findString];
	// get the current search option settings
    NSString *field = [self field];
    unsigned searchOpts = (ignoreCase ? NSCaseInsensitiveSearch : 0);
	
	switch(searchScope){
		case FCEndsWithSearch:
			searchOpts = searchOpts | NSBackwardsSearch;
		case FCStartsWithSearch:
			searchOpts = searchOpts | NSAnchoredSearch;
	}
	
	if(findAsMacro)
		findStr = [NSString stringWithBibTeXString:findStr macroResolver:[theDocument macroResolver]];
	
	// loop through the pubs to replace
    NSMutableArray *arrayOfItems = [NSMutableArray array];
    NSEnumerator *pubE; // an enumerator of BibItems
    BibItem *bibItem;
    NSString *origStr;
    
    // use all shown pubs; not just selection, since our caller is going to change the selection
    NSArray *publications = [theDocument displayedPublications];

    pubE = [publications objectEnumerator];
    
    while(bibItem = [pubE nextObject]){
        origStr = [bibItem valueOfField:field inherit:NO];
        
        if(origStr == nil || findAsMacro != [origStr isComplex])
            continue; // we don't want to add a field or set it to nil, or find expanded values of a complex string, or interpret an ordinary string as a macro
        
		if(searchScope == FCWholeFieldSearch){
			if([findStr compareAsComplexString:origStr options:searchOpts] == NSOrderedSame)
				[arrayOfItems addObject:bibItem];
		}else{
			if ([origStr hasSubstring:findStr options:searchOpts])
				[arrayOfItems addObject:bibItem];
		}
    }
    return ([arrayOfItems count] ? arrayOfItems : nil);
}

- (NSArray *)currentRegexFoundItemsInDocument:(BibDocument *)theDocument{
	// found items using AGRegex
	// get some search settings
    NSString *field = [self field];
    AGRegex *theRegex = [self currentRegex];
	
	// loop through the pubs to replace
    NSMutableArray *arrayOfItems = [NSMutableArray array];
    NSEnumerator *pubE; // an enumerator of BibItems
    BibItem *bibItem;
    NSString *origStr;
    
    // use all shown pubs; not just selection, since our caller is going to change the selection
    NSArray *publications = [theDocument displayedPublications];
    pubE = [publications objectEnumerator];
    
    while(bibItem = [pubE nextObject]){
        origStr = [bibItem valueOfField:field inherit:NO];
        
        if(origStr == nil || findAsMacro != [origStr isComplex])
            continue; // we don't want to add a field or set it to nil, or find expanded values of a complex string, or interpret an ordinary string as a macro
        
		if(findAsMacro)
			origStr = [origStr stringAsBibTeXString];
		if([theRegex findInString:origStr]){
			[arrayOfItems addObject:bibItem];
        }
    }
    return ([arrayOfItems count] ? arrayOfItems : nil);
}

- (NSArray *)currentFoundItemsInDocument:(BibDocument *)theDocument{
    [self clearFrontDocumentQuickSearch];
	
	if([self searchType] == FCTextualSearch)
		return [self currentStringFoundItemsInDocument:theDocument];
	else if([self regexIsValid:[self findString]])
		return [self currentRegexFoundItemsInDocument:theDocument];
	return nil;
}

- (void)setField:field ofItem:bibItem toValue:newValue withInfos:(NSMutableArray *)paperInfos{
	NSString *oldPath = nil;
	NSString *newPath = nil;
	if(shouldMove)
		oldPath = [bibItem localFilePathForField:field];
	[bibItem setField:field toValue:newValue];
	if(shouldMove){
		newPath = [bibItem localFilePathForField:field];
		if([NSString isEmptyString:oldPath] == NO)
			[paperInfos addObject:[NSDictionary dictionaryWithObjectsAndKeys:bibItem, @"paper", oldPath, @"oldPath", newPath, @"newPath", nil]];
	}
}

- (unsigned int)stringFindAndReplaceInItems:(NSArray *)arrayOfPubs ofDocument:(BibDocument *)theDocument{
	// find and replace using BDSKComplexString methods
    // first we setup all the search settings
    NSString *findStr = [self findString];
    NSString *replStr = [self replaceString];
	// get the current search option settings
    NSString *field = [self field];
    unsigned searchOpts = (ignoreCase ? NSCaseInsensitiveSearch : 0);
	
	if(!findAsMacro && replaceAsMacro)
		searchScope = FCWholeFieldSearch; // we can only reliably replace a complete string by a macro
	
	switch(searchScope){
		case FCEndsWithSearch:
			searchOpts = searchOpts | NSBackwardsSearch;
		case FCStartsWithSearch:
			searchOpts = searchOpts | NSAnchoredSearch;
	}
	
	if(findAsMacro)
		findStr = [NSString stringWithBibTeXString:findStr macroResolver:[theDocument macroResolver]];
	if(replaceAsMacro)
		replStr = [NSString stringWithBibTeXString:replStr macroResolver:[theDocument macroResolver]];
		
	// loop through the pubs to replace
    NSEnumerator *pubE = [arrayOfPubs objectEnumerator]; // an enumerator of BibItems
    BibItem *bibItem;
    NSString *origStr;
    NSString *newStr;
	unsigned int numRepl = 0;
	unsigned number = 0;
	NSMutableArray *paperInfos = nil;
	
	if(shouldMove)
		paperInfos = [NSMutableArray arrayWithCapacity:[arrayOfPubs count]];
    
    while(bibItem = [pubE nextObject]){
        // don't touch external items
        if ([bibItem owner] != theDocument) 
            continue;
        
        origStr = [bibItem valueOfField:field inherit:NO];
        
        if(origStr == nil || findAsMacro != [origStr isComplex])
            continue; // we don't want to add a field or set it to nil, or replace expanded values of a complex string, or interpret an ordinary string as a macro
		
		if(searchScope == FCWholeFieldSearch){
			if([findStr compareAsComplexString:origStr options:searchOpts] == NSOrderedSame){
				[self setField:field ofItem:bibItem toValue:replStr withInfos:paperInfos];
				number++;
			}
		}else{
			newStr = [origStr stringByReplacingOccurrencesOfString:findStr withString:replStr options:searchOpts replacements:&numRepl];
			if(numRepl > 0){
				[self setField:field ofItem:bibItem toValue:newStr withInfos:paperInfos];
				number++;
			}
		}
    }

	if([paperInfos count])
		[[BibFiler sharedFiler] movePapers:paperInfos forField:field fromDocument:theDocument options:0];
	
	return number;
}

- (unsigned int)regexFindAndReplaceInItems:(NSArray *)arrayOfPubs ofDocument:(BibDocument *)theDocument{
	// find and replace using AGRegex
    // first we setup all the search settings
    NSString *replStr = [self replaceString];
	// get some search settings
    NSString *field = [self field];
    AGRegex *theRegex = [self currentRegex];
	
	if(findAsMacro && !replaceAsMacro)
		replStr = [replStr stringAsBibTeXString];
	
	// loop through the pubs to replace
    NSEnumerator *pubE = [arrayOfPubs objectEnumerator]; // an enumerator of BibItems
    BibItem *bibItem;
    NSString *origStr;
	NSString *complexStr;
	unsigned number = 0;
	NSMutableArray *paperInfos = nil;
	
	if(shouldMove)
		paperInfos = [NSMutableArray arrayWithCapacity:[arrayOfPubs count]];
	
    while(bibItem = [pubE nextObject]){
        // don't touch external items
        if ([bibItem owner] != theDocument) 
            continue;
        
        origStr = [bibItem valueOfField:field inherit:NO];
        
        if(origStr == nil || findAsMacro != [origStr isComplex])
            continue; // we don't want to add a field or set it to nil, or replace expanded values of a complex string, or interpret an ordinary string as a macro
        
		if(findAsMacro)
			origStr = [origStr stringAsBibTeXString];
		if([theRegex findInString:origStr]){
			origStr = [theRegex replaceWithString:replStr inString:origStr];
			if(replaceAsMacro || findAsMacro){
				NS_DURING
					complexStr = [NSString stringWithBibTeXString:origStr macroResolver:[theDocument macroResolver]];
					[self setField:field ofItem:bibItem toValue:complexStr withInfos:paperInfos];
					number++;
				NS_HANDLER
					if(![[localException name] isEqualToString:BDSKComplexStringException])
						[localException raise];
				NS_ENDHANDLER
			} else {
				[self setField:field ofItem:bibItem toValue:origStr withInfos:paperInfos];
				number++;
			}            
        }
    }
	
	if([paperInfos count])
		[[BibFiler sharedFiler] movePapers:paperInfos forField:field fromDocument:theDocument options:0];
	    
	return number;
}

- (unsigned int)overwriteInItems:(NSArray *)arrayOfPubs ofDocument:(BibDocument *)theDocument{
	// overwrite using BDSKComplexString methods
    // first we setup all the search settings
    NSString *replStr = [self replaceString];
	// get the current search option settings
    NSString *field = [self field];
	
	if(replaceAsMacro)
		replStr = [NSString stringWithBibTeXString:replStr macroResolver:[theDocument macroResolver]];
		
	// loop through the pubs to replace
    NSEnumerator *pubE = [arrayOfPubs objectEnumerator]; // an enumerator of BibItems
    BibItem *bibItem;
    NSString *origStr;
	unsigned number = 0;
	NSMutableArray *paperInfos = nil;
	
	if(shouldMove)
		paperInfos = [NSMutableArray arrayWithCapacity:[arrayOfPubs count]];

    while(bibItem = [pubE nextObject]){
        // don't touch external items
        if ([bibItem owner] != theDocument) 
            continue;
        
        origStr = [bibItem valueOfField:field inherit:NO];
		if([replStr compareAsComplexString:origStr] != NSOrderedSame){
			[self setField:field ofItem:bibItem toValue:replStr withInfos:paperInfos];
			number++;
		}
    }
	
	if([paperInfos count])
		[[BibFiler sharedFiler] movePapers:paperInfos forField:field fromDocument:theDocument options:0];
	    
	return number;
}

- (unsigned int)prependInItems:(NSArray *)arrayOfPubs ofDocument:(BibDocument *)theDocument{
	// prepend using BDSKComplexString methods
    // first we setup all the search settings
    NSString *replStr = [self replaceString];
	// get the current search option settings
    NSString *field = [self field];
	
    if(replStr == nil || [replStr isEqualAsComplexString:@""])
        return 0;
    
	if(replaceAsMacro)
		replStr = [NSString stringWithBibTeXString:replStr macroResolver:[theDocument macroResolver]];
		
	// loop through the pubs to replace
    NSEnumerator *pubE = [arrayOfPubs objectEnumerator]; // an enumerator of BibItems
    BibItem *bibItem;
    NSString *origStr;
	unsigned number = 0;
	NSMutableArray *paperInfos = nil;
	
	if(shouldMove)
		paperInfos = [NSMutableArray arrayWithCapacity:[arrayOfPubs count]];

    while(bibItem = [pubE nextObject]){
        // don't touch external items
        if ([bibItem owner] != theDocument) 
            continue;
        
        origStr = [bibItem valueOfField:field inherit:NO];
        if(origStr == nil || [origStr isEqualAsComplexString:@""])
            continue;
        
        [self setField:field ofItem:bibItem toValue:[replStr stringByAppendingString:origStr] withInfos:paperInfos];
        number++;
    }
	
	if([paperInfos count])
		[[BibFiler sharedFiler] movePapers:paperInfos forField:field fromDocument:theDocument options:0];
	    
	return number;
}

- (unsigned int)appendInItems:(NSArray *)arrayOfPubs ofDocument:(BibDocument *)theDocument{
	// prepend using BDSKComplexString methods
    // first we setup all the search settings
    NSString *replStr = [self replaceString];
	// get the current search option settings
    NSString *field = [self field];
	
    if(replStr == nil || [replStr isEqualAsComplexString:@""])
        return 0;
    
	if(replaceAsMacro)
		replStr = [NSString stringWithBibTeXString:replStr macroResolver:[theDocument macroResolver]];
		
	// loop through the pubs to replace
    NSEnumerator *pubE = [arrayOfPubs objectEnumerator]; // an enumerator of BibItems
    BibItem *bibItem;
    NSString *origStr;
	unsigned number = 0;
	NSMutableArray *paperInfos = nil;
	
	if(shouldMove)
		paperInfos = [NSMutableArray arrayWithCapacity:[arrayOfPubs count]];

    while(bibItem = [pubE nextObject]){
        // don't touch external items
        if ([bibItem owner] != theDocument) 
            continue;
        
        origStr = [bibItem valueOfField:field inherit:NO];
        if(origStr == nil || [origStr isEqualAsComplexString:@""])
            continue;
        
        [self setField:field ofItem:bibItem toValue:[origStr stringByAppendingString:replStr] withInfos:paperInfos];
        number++;
    }
	
	if([paperInfos count])
		[[BibFiler sharedFiler] movePapers:paperInfos forField:field fromDocument:theDocument options:0];
	    
	return number;
}

- (unsigned int)findAndReplaceInItems:(NSArray *)arrayOfPubs ofDocument:(BibDocument *)theDocument{
    unsigned number;
	
	[self clearFrontDocumentQuickSearch];
	
	if(shouldMove == NSMixedState){
		BDSKAlert *alert = [BDSKAlert alertWithMessageText:NSLocalizedString(@"Move Linked Files?", @"Message in alert dialog when chnaging local file field")
											 defaultButton:NSLocalizedString(@"Move", @"Button title")
										   alternateButton:NSLocalizedString(@"Don't Move", @"Button title")
											   otherButton:nil
								 informativeTextWithFormat:NSLocalizedString(@"Do you want me to move the linked files to the new location?", @"Informative text in alert dialog")];
		int rv = [alert runSheetModalForWindow:[self window]];
		shouldMove = (rv == NSAlertDefaultReturn) ? NSOnState : NSOffState;
	}
	
	if(FCOperationOverwrite == [self operation])
		number = [self overwriteInItems:arrayOfPubs ofDocument:theDocument];
	else if(FCOperationPrepend == [self operation])
		number = [self prependInItems:arrayOfPubs ofDocument:theDocument];
	else if(FCOperationAppend == [self operation])
		number = [self appendInItems:arrayOfPubs ofDocument:theDocument];
	else if([self searchType] == FCTextualSearch)
		number = [self stringFindAndReplaceInItems:arrayOfPubs ofDocument:theDocument];
	else if([self regexIsValid:[self findString]])
		number = [self regexFindAndReplaceInItems:arrayOfPubs ofDocument:theDocument];
	else
		number = 0;
	
	NSString *fieldString = (number == 1)? NSLocalizedString(@"field",@"field") : NSLocalizedString(@"fields",@"fields");
	NSString *message = nil;
	if(shouldMove)
		message = NSLocalizedString(@"Replaced and moved for %i %@",@"Status message: Replaced and moved in [number] field(s)");
	else
		message = NSLocalizedString(@"Replaced in %i %@",@"Status message: Replaced in [number] field(s)");
	[statusBar setStringValue:[NSString stringWithFormat:message, number, fieldString]];
	
	return number;
}

- (id)windowWillReturnFieldEditor:(NSWindow *)sender toObject:(id)anObject {
	if (findFieldEditor == nil) {
		findFieldEditor = [[BDSKFindFieldEditor alloc] initWithFrame:NSZeroRect];
	}
	return findFieldEditor;
}

@end
