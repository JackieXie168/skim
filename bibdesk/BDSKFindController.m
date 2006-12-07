//
//  BDSKFindController.m
//  Bibdesk
//
//  Created by Adam Maxwell on 06/21/05.
//
/*
 This software is Copyright (c) 2005
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
#import <Carbon/Carbon.h>

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

@implementation BDSKFindController

+ (BDSKFindController *)sharedFindController{
    if(sharedFC == nil)
        sharedFC = [[BDSKFindController alloc] init];
    return sharedFC;
}

- (id)init{
    if(self = [super initWithWindowNibName:@"BDSKFindPanel"]){
        defaults = [OFPreferenceWrapper sharedPreferenceWrapper];
    }
    return self;
}

- (void)dealloc{
    [super dealloc];
}

- (void)awakeFromNib{
	BibTypeManager *typeMan = [BibTypeManager sharedManager];
	NSMutableSet *fieldNameSet = [NSMutableSet setWithSet:[typeMan allFieldNames]];
	[fieldNameSet unionSet:[NSSet setWithObjects:BDSKLocalUrlString, BDSKUrlString, BDSKCiteKeyString, BDSKDateString, nil]];
	NSMutableArray *fieldNames = [[fieldNameSet allObjects] mutableCopy];
	[fieldNames sortUsingSelector:@selector(caseInsensitiveCompare:)];
	[fieldToSearchComboBox removeAllItems];
	[fieldToSearchComboBox addItemsWithObjectValues:fieldNames];
    [fieldNames release];

    // make sure we enter valid field names
    BDSKFieldNameFormatter *formatter = [[BDSKFieldNameFormatter alloc] init];
    [fieldToSearchComboBox setFormatter:formatter];
    [formatter release];
    
    [self resetDefaults];
    [self updateUI];
}

- (void)resetDefaults{
    // set to reasonable defaults for most users after quit/relaunch
    [defaults setInteger:FCTextualSearch forKey:BDSKFindControllerDefaultFindAndReplaceTypeKey];  // disable regexes
    [defaults setInteger:FCContainsSearch forKey:BDSKFindControllerSearchScopeKey];  // Find substrings
    [defaults setBool:YES forKey:BDSKFindControllerCaseInsensitiveFindAndReplaceKey];    // case insensitive
    [defaults setBool:YES forKey:BDSKFindControllerFindAndReplaceSelectedItemsKey]; // only operate on selection
    [defaults setBool:NO forKey:BDSKFindControllerFindAsMacroKey];                  // don't find macros
    [defaults setBool:NO forKey:BDSKFindControllerReplaceAsMacroKey];               // don't replace with a macro
}

// no surprises from replacing unseen items!
- (void)clearFrontDocumentQuickSearch{
    BibDocument *doc = [[NSDocumentController sharedDocumentController] currentDocument];
    [doc setFilterField:@""];
}

- (void)updateUI{
    [fieldToSearchComboBox selectItemWithObjectValue:[defaults objectForKey:BDSKFindControllerLastFindAndReplaceFieldKey]];
    [searchTypePopUpButton selectItemAtIndex:[defaults integerForKey:BDSKFindControllerDefaultFindAndReplaceTypeKey]];
    [searchScopePopUpButton selectItemAtIndex:[defaults integerForKey:BDSKFindControllerSearchScopeKey]];
    [ignoreCaseCheckbox setState:([defaults boolForKey:BDSKFindControllerCaseInsensitiveFindAndReplaceKey] ? NSOnState : NSOffState)];
    [searchSelectionCheckbox setState:([defaults boolForKey:BDSKFindControllerFindAndReplaceSelectedItemsKey] ? NSOnState : NSOffState)];
    [findAsMacroCheckbox setState:([defaults boolForKey:BDSKFindControllerFindAsMacroKey] ? NSOnState : NSOffState)];
    [replaceAsMacroCheckbox setState:([defaults boolForKey:BDSKFindControllerReplaceAsMacroKey] ? NSOnState : NSOffState)];
    
	if(![defaults boolForKey:BDSKFindControllerFindAsMacroKey] &&
	   [defaults boolForKey:BDSKFindControllerReplaceAsMacroKey])
		[statusLine setStringValue:NSLocalizedString(@"With these settings, only full strings will be replaced",@"")];
	else
		[statusLine setStringValue:@""];
}

- (void)windowDidBecomeKey:(NSNotification *)aNotification{
    // get the current search text from the find pasteboard
    NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSFindPboard];
    NSString *availableType = [pboard availableTypeFromArray:[NSArray arrayWithObject:NSStringPboardType]];
    if(availableType)
        availableType = [pboard stringForType:NSStringPboardType];
    [findTextField setStringValue:(availableType != nil ? availableType : @"")];
	[statusLine setStringValue:@""];
}

#pragma mark Validation

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor{
    NSString *reason = nil;
	BOOL isRegex = ([defaults integerForKey:BDSKFindControllerDefaultFindAndReplaceTypeKey] == FCRegexSearch);

    if(control == findTextField){
        if(isRegex){ // check the regex
            if(![self currentRegexIsValid]){
                NSBeginAlertSheet(NSLocalizedString(@"Invalid Regular Expression.", @""),
                                  nil,nil,nil,[self window],nil,NULL,NULL,NULL,
                                  NSLocalizedString(@"The regular expression you entered is not valid.", @""));
                return NO;
            }
        }
        if([defaults boolForKey:BDSKFindControllerFindAsMacroKey] && !isRegex){ // check the "find" complex string
            if(![self stringIsValidAsComplexString:[control stringValue] errorMessage:&reason]){
                NSBeginAlertSheet(NSLocalizedString(@"Invalid BibTeX Macro", @""),
                                  nil,nil,nil,[self window],nil,NULL,NULL,NULL,
                                  reason);
                return NO;
            }
        }  
    }
    
    if(control == replaceTextField && [defaults boolForKey:BDSKFindControllerReplaceAsMacroKey] && !isRegex){ // check the "replace" complex string
        if(![self stringIsValidAsComplexString:[control stringValue] errorMessage:&reason]){
            NSBeginAlertSheet(NSLocalizedString(@"Invalid BibTeX Macro", @""),
                              nil,nil,nil,[self window],nil,NULL,NULL,NULL,
                              reason);
            return NO;
        }
    }
    // other controls and cases are always valid
    return YES;
}

- (BOOL)currentRegexIsValid{
    AGRegex *testRegex = [AGRegex regexWithPattern:[findTextField stringValue]];
    if(testRegex == nil)
        return NO;
    
    return YES;
}

- (BOOL)stringIsValidAsComplexString:(NSString *)btstring errorMessage:(NSString **)errString{
    BOOL valid = YES;
    volatile BDSKComplexString *compStr;
    NSString *reason = nil;    
    
    NS_DURING
        compStr = [BDSKComplexString complexStringWithBibTeXString:btstring macroResolver:nil];
    NS_HANDLER
        if([[localException name] isEqualToString:BDSKComplexStringException]){
            valid = NO;
            reason = [localException reason];
        } else {
            [localException raise];
        }
    NS_ENDHANDLER
    
    if(!valid){
        if(reason == nil)
            reason = @"Complex string is invalid for unknown reason"; // shouldn't happen
        
        *errString = reason;
    }
    return valid;
}


#pragma mark Action methods

- (IBAction)openHelp:(id)sender{
	OSStatus err = AHLookupAnchor(NULL, CFSTR("Find-and-Replace"));
    if (err != noErr)
        NSLog(@"Help Book: error looking up anchor \"Find-and-Replace\"");
}

- (IBAction)changeFieldName:(id)sender{
    [defaults setObject:[sender objectValue] forKey:BDSKFindControllerLastFindAndReplaceFieldKey];
    [self updateUI];
}

- (IBAction)toggleSearchType:(id)sender{

    int tag = [sender indexOfSelectedItem];
    switch(tag){
        case FCTextualSearch:
            [defaults setInteger:tag forKey:BDSKFindControllerDefaultFindAndReplaceTypeKey];
            break;
            
        case FCRegexSearch:
            if([self currentRegexIsValid]){
                [defaults setInteger:FCRegexSearch forKey:BDSKFindControllerDefaultFindAndReplaceTypeKey];
            } else {
                [defaults setInteger:FCTextualSearch forKey:BDSKFindControllerDefaultFindAndReplaceTypeKey];
                NSBeginAlertSheet(NSLocalizedString(@"Invalid Regular Expression.", @""),
                                  nil,nil,nil,[self window],self,@selector(regexCheckSheetDidEnd:returnCode:contextInfo:),NULL,findTextField,
                                  NSLocalizedString(@"The entry \"%@\" is not a valid regular expression.", @""), [findTextField stringValue]);  
            }
            break;
            
        default:
            break;
    }
    [self updateUI];
}

- (IBAction)toggleSearchScope:(id)sender{
    int tag = [sender indexOfSelectedItem];
	[defaults setInteger:tag forKey:BDSKFindControllerSearchScopeKey];
    [self updateUI];
}

- (void)regexCheckSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(NSTextField *)textField{
    [searchTypePopUpButton selectItemAtIndex:FCTextualSearch];
    
    if(![[self window] makeFirstResponder:textField])
        return;
    NSText *fe = [[self window] fieldEditor:YES forObject:textField];
    [fe setSelectedRange:NSMakeRange([[textField stringValue] length], 0)];
}

- (IBAction)toggleCaseSensitivity:(id)sender{
    [defaults setBool:([sender state] == NSOnState) forKey:BDSKFindControllerCaseInsensitiveFindAndReplaceKey];
    [self updateUI];
}

- (IBAction)toggleSelection:(id)sender{
    [defaults setBool:([sender state] == NSOnState) forKey:BDSKFindControllerFindAndReplaceSelectedItemsKey];
    [self updateUI];
}

- (IBAction)toggleFindAsMacro:(id)sender{
    int state = [sender state];
    NSString *reason = nil;
    if(state == NSOnState && [defaults integerForKey:BDSKFindControllerDefaultFindAndReplaceTypeKey] == FCTextualSearch &&
	   ![self stringIsValidAsComplexString:[findTextField stringValue] errorMessage:&reason]){
        NSBeginAlertSheet(NSLocalizedString(@"Invalid BibTeX Macro", @""),
                          nil,nil,nil,[self window],self,@selector(macroCheckSheetDidEnd:returnCode:contextInfo:),NULL,findTextField,
                          reason);
        [sender setState:NSOffState];
    }
            
    [defaults setBool:([sender state] == NSOnState) forKey:BDSKFindControllerFindAsMacroKey];
    [self updateUI];
}

- (IBAction)toggleReplaceAsMacro:(id)sender{
    int state = [sender state];
    NSString *reason = nil;
    if(state == NSOnState && [defaults integerForKey:BDSKFindControllerDefaultFindAndReplaceTypeKey] == FCTextualSearch &&
	   ![self stringIsValidAsComplexString:[replaceTextField stringValue] errorMessage:&reason]){
        NSBeginAlertSheet(NSLocalizedString(@"Invalid BibTeX Macro", @""),
                          nil,nil,nil,[self window],self,@selector(macroCheckSheetDidEnd:returnCode:contextInfo:),NULL,replaceTextField,
                          reason);
        [sender setState:NSOffState];
    }
    [defaults setBool:([sender state] == NSOnState) forKey:BDSKFindControllerReplaceAsMacroKey];
    [self updateUI];
}

- (void)macroCheckSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(NSTextField *)textField{    
    if(![[self window] makeFirstResponder:textField])
        return;
    NSText *fe = [[self window] fieldEditor:YES forObject:textField];
    [fe setSelectedRange:NSMakeRange([[textField stringValue] length], 0)];
}

- (IBAction)changeFindExpression:(id)sender{
    // put the current search text on the find pasteboard for other apps
    NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSFindPboard];
    [pboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
    [pboard setString:[sender stringValue] forType:NSStringPboardType];
    [self updateUI];
}

- (IBAction)changeReplaceExpression:(id)sender{
    [self updateUI]; // for error checking
}

#pragma mark Find and Replace Action methods

- (IBAction)findAndHighlightNext:(id)sender{
    [self findAndHighlightWithReplace:NO next:YES];
}

- (IBAction)findAndHighlightPrevious:(id)sender{
    [self findAndHighlightWithReplace:NO next:NO];
}

- (IBAction)replaceAndHighlightNext:(id)sender{
    [self findAndHighlightWithReplace:YES next:YES];
}

- (void)findAndHighlightWithReplace:(BOOL)replace next:(BOOL)next{
	[statusLine setStringValue:@""];
    
    BibDocument *theDocument = [[NSDocumentController sharedDocumentController] currentDocument];
    if(!theDocument){
        NSBeep();
		[statusLine setStringValue:NSLocalizedString(@"No document selected",@"")];
        return;
	}
    [self clearFrontDocumentQuickSearch];
   
    // this can change between clicks of the Find button, so we can't cache it
    NSArray *currItems = [self currentFoundItemsInDocument:theDocument];
    //NSLog(@"currItems has %@", currItems);
    if(currItems == nil){
        NSBeep();
		[statusLine setStringValue:NSLocalizedString(@"Nothing found",@"")];
        return;
    }

    NSEnumerator *selPubE = [theDocument selectedPubEnumerator];
    NSNumber *selIndex = [selPubE nextObject];
    unsigned int indexOfSelectedItem;
    if(selIndex == nil){ // no selection, so select the first one
        indexOfSelectedItem = 0;
    } else {
        indexOfSelectedItem = [selIndex intValue];
        
        // see if the selected pub is one of the current found items, or just some random item
        NSArray *shownPubs = [theDocument displayedPublications];
        BibItem *bibItem = [shownPubs objectAtIndex:indexOfSelectedItem];
        
        // if we're doing a replace & find, we need to replace in this item before we change the selection
        if(replace){
            unsigned number = [self findAndReplaceInItems:[NSArray arrayWithObject:bibItem] ofDocument:theDocument];
			NSString *fieldString = (number == 1)? NSLocalizedString(@"field",@"field") : NSLocalizedString(@"fields",@"fields");
			[statusLine setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Replaced in %i %@",@"Replaced in (number) field(s)"), number, fieldString]];
		}
        
        // see if current search results have an item identical to the selected one
        indexOfSelectedItem = [currItems indexOfObjectIdenticalTo:bibItem];
        if(indexOfSelectedItem != NSNotFound){ // we've already selected an item from the search results...so select the next one
            if(next){
				if(++indexOfSelectedItem >= [currItems count])
					indexOfSelectedItem = 0; // wrap around
			}else{
				if(--indexOfSelectedItem < 0)
					indexOfSelectedItem = [currItems count] - 1; // wrap around
			}
        } else {
            // the selected pub was some item we don't care about, so select item 0
            indexOfSelectedItem = 0;
        }
    }
    
    [theDocument highlightBib:[currItems objectAtIndex:indexOfSelectedItem]];
}

- (IBAction)replaceAll:(id)sender{
	[statusLine setStringValue:@""];
	
    BibDocument *theDocument = [[NSDocumentController sharedDocumentController] currentDocument];
    if(!theDocument){
        NSBeep();
		[statusLine setStringValue:NSLocalizedString(@"No document selected",@"")];
        return;
	}
    [self clearFrontDocumentQuickSearch];

    NSEnumerator *pubE;
    NSMutableArray *publications;
    NSArray *shownPublications = [theDocument displayedPublications];

    NSNumber *index = nil;
    BOOL isSelected = [defaults boolForKey:BDSKFindControllerFindAndReplaceSelectedItemsKey];
    
    if(isSelected){
        // if we're only doing a find/replace in the selected publications
        pubE = [theDocument selectedPubEnumerator];
        publications = [NSMutableArray array];
        
        while(index = [pubE nextObject])
            [publications addObject:[shownPublications objectAtIndex:[index intValue]]];
    } else {
        // we're doing a find/replace in all the document pubs
        publications = (NSMutableArray *)shownPublications; // we're not changing it; the cast just shuts gcc up
    }
    
	unsigned number = [self findAndReplaceInItems:publications ofDocument:theDocument];
	
	NSString *fieldString = (number == 1)? NSLocalizedString(@"field",@"field") : NSLocalizedString(@"fields",@"fields");
	[statusLine setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Replaced in %i %@",@"Replaced in (number) field(s)"), number, fieldString]];
}

#pragma mark Find and Replace implementation

- (AGRegex *)currentRegex{
	// current regex including string and/or node boundaries and case sensitivity
    NSString *findStr = [findTextField stringValue];
    BOOL isCaseInsensitive = [defaults boolForKey:BDSKFindControllerCaseInsensitiveFindAndReplaceKey];
    unsigned searchScope = [defaults integerForKey:BDSKFindControllerSearchScopeKey];
    BOOL findAsMacro = [defaults boolForKey:BDSKFindControllerFindAsMacroKey];
    BOOL replaceAsMacro = [defaults boolForKey:BDSKFindControllerReplaceAsMacroKey];
	
	if(!findAsMacro && replaceAsMacro)
		searchScope = FCWholeFieldSearch; // we can only reliably replace a complete string by a macro
    
	NSString *regexFormat = nil;
	
	// set string and/or node boundaries in the regex
	switch(searchScope){
		case FCContainsSearch:
			regexFormat = (findAsMacro) ? @"(?<=^|\\s#\\s)%@(?=$|\\s#\\s)" : @"%@";
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
	findStr = [NSString stringWithFormat:regexFormat, findStr];
	
	return [AGRegex regexWithPattern:findStr options:(isCaseInsensitive ? AGRegexCaseInsensitive : 0)];
}

- (NSArray *)currentStringFoundItemsInDocument:(BibDocument *)theDocument{
	// found items using BDSKComplexString methods
	// get the current values from the find panel
    NSString *findStr = [findTextField stringValue];
	// get the current search option settings
    NSString *field = [defaults objectForKey:BDSKFindControllerLastFindAndReplaceFieldKey];
    BOOL findAsMacro = [defaults boolForKey:BDSKFindControllerFindAsMacroKey];
    unsigned searchScope = [defaults integerForKey:BDSKFindControllerSearchScopeKey];
    unsigned searchOpts = ([defaults boolForKey:BDSKFindControllerCaseInsensitiveFindAndReplaceKey] ? NSCaseInsensitiveSearch : 0);
	
	switch(searchScope){
		case FCEndsWithSearch:
			searchOpts = searchOpts | NSBackwardsSearch;
		case FCStartsWithSearch:
			searchOpts = searchOpts | NSAnchoredSearch;
	}
	
	if(findAsMacro)
		findStr = [NSString complexStringWithBibTeXString:findStr macroResolver:theDocument];
	
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
    NSString *field = [defaults objectForKey:BDSKFindControllerLastFindAndReplaceFieldKey];
    BOOL findAsMacro = [defaults boolForKey:BDSKFindControllerFindAsMacroKey];
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
	
	if([defaults integerForKey:BDSKFindControllerDefaultFindAndReplaceTypeKey] == FCTextualSearch)
		return [self currentStringFoundItemsInDocument:theDocument];
	else if([self currentRegexIsValid])
		return [self currentRegexFoundItemsInDocument:theDocument];
	return nil;
}

- (unsigned int)stringFindAndReplaceInItems:(NSArray *)arrayOfPubs ofDocument:(BibDocument *)theDocument{
	// find and replace using BDSKComplexString methods
    // first we setup all the search settings
    NSString *findStr = [findTextField stringValue];
    NSString *replStr = [replaceTextField stringValue];
	// get the current search option settings
    NSString *field = [defaults objectForKey:BDSKFindControllerLastFindAndReplaceFieldKey];
    BOOL findAsMacro = [defaults boolForKey:BDSKFindControllerFindAsMacroKey];
    BOOL replaceAsMacro = [defaults boolForKey:BDSKFindControllerReplaceAsMacroKey];
    unsigned searchScope = [defaults integerForKey:BDSKFindControllerSearchScopeKey];
    unsigned searchOpts = ([defaults boolForKey:BDSKFindControllerCaseInsensitiveFindAndReplaceKey] ? NSCaseInsensitiveSearch : 0);
	
	if(!findAsMacro && replaceAsMacro)
		searchScope = FCWholeFieldSearch; // we can only reliably replace a complete string by a macro
	
	switch(searchScope){
		case FCEndsWithSearch:
			searchOpts = searchOpts | NSBackwardsSearch;
		case FCStartsWithSearch:
			searchOpts = searchOpts | NSAnchoredSearch;
	}
	
	if(findAsMacro)
		findStr = [NSString complexStringWithBibTeXString:findStr macroResolver:theDocument];
	if(replaceAsMacro)
		replStr = [NSString complexStringWithBibTeXString:replStr macroResolver:theDocument];
		
	// loop through the pubs to replace
    NSEnumerator *pubE = [arrayOfPubs objectEnumerator]; // an enumerator of BibItems
    BibItem *bibItem;
    NSString *origStr;
    NSString *newStr;
	unsigned int numRepl = 0;
	unsigned number = 0;

    while(bibItem = [pubE nextObject]){
        origStr = [bibItem valueOfField:field inherit:NO];
        
        if(origStr == nil || findAsMacro != [origStr isComplex])
            continue; // we don't want to add a field or set it to nil, or replace expanded values of a complex string, or interpret an ordinary string as a macro
        
		if(searchScope == FCWholeFieldSearch){
			if([findStr compareAsComplexString:origStr options:searchOpts] == NSOrderedSame){
				[bibItem setField:field toValue:replStr];
				number++;
			}
		}else{
			newStr = [origStr stringByReplacingOccurrencesOfString:findStr withString:replStr options:searchOpts replacements:&numRepl];
			if(numRepl > 0){
				[bibItem setField:field toValue:newStr];
				number++;
			}
		}
    }
	return number;
}

- (unsigned int)regexFindAndReplaceInItems:(NSArray *)arrayOfPubs ofDocument:(BibDocument *)theDocument{
	// find and replace using AGRegex
    // first we setup all the search settings
    NSString *replStr = [replaceTextField stringValue];
	// get some search settings
    NSString *field = [defaults objectForKey:BDSKFindControllerLastFindAndReplaceFieldKey];
    BOOL findAsMacro = [defaults boolForKey:BDSKFindControllerFindAsMacroKey];
    BOOL replaceAsMacro = [defaults boolForKey:BDSKFindControllerReplaceAsMacroKey];
    AGRegex *theRegex = [self currentRegex];
	
	if(findAsMacro && !replaceAsMacro)
		replStr = [replStr stringAsBibTeXString];
	
	// loop through the pubs to replace
    NSEnumerator *pubE = [arrayOfPubs objectEnumerator]; // an enumerator of BibItems
    BibItem *bibItem;
    NSString *origStr;
	NSString *complexStr;
	unsigned number = 0;
	
    while(bibItem = [pubE nextObject]){
        origStr = [bibItem valueOfField:field inherit:NO];
        
        if(origStr == nil || findAsMacro != [origStr isComplex])
            continue; // we don't want to add a field or set it to nil, or replace expanded values of a complex string, or interpret an ordinary string as a macro
        
		if(findAsMacro)
			origStr = [origStr stringAsBibTeXString];
		if([theRegex findInString:origStr]){
			origStr = [theRegex replaceWithString:replStr inString:origStr];
			if(replaceAsMacro || findAsMacro){
				NS_DURING
					complexStr = [NSString complexStringWithBibTeXString:origStr macroResolver:theDocument];
					[bibItem setField:field toValue:complexStr];
					number++;
				NS_HANDLER
					if(![[localException name] isEqualToString:BDSKComplexStringException])
						[localException raise];
				NS_ENDHANDLER
			} else {
				[bibItem setField:field toValue:origStr];
				number++;
			}            
        }
    }
	return number;
}

- (unsigned int)findAndReplaceInItems:(NSArray *)arrayOfPubs ofDocument:(BibDocument *)theDocument{
    [self clearFrontDocumentQuickSearch];
	
	if([defaults integerForKey:BDSKFindControllerDefaultFindAndReplaceTypeKey] == FCTextualSearch)
		return [self stringFindAndReplaceInItems:arrayOfPubs ofDocument:theDocument];
	else if([self currentRegexIsValid])
		return [self regexFindAndReplaceInItems:arrayOfPubs ofDocument:theDocument];
	return 0;
}

@end
