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

NSString *BDSKFindControllerDefaultFindAndReplaceTypeKey = @"Default field for find and replace";
NSString *BDSKFindControllerCaseSensitiveFindAndReplaceKey = @"Use case sensitive search for find and replace";
NSString *BDSKFindControllerFindAndReplaceSelectedItemsKey = @"Search only selected items for find and replace";
NSString *BDSKFindControllerLastFindAndReplaceFieldKey = @"Last field for find and replace";
NSString *BDSKFindControllerFindAsMacroKey = @"Find text as macro for replacement";
NSString *BDSKFindControllerReplaceAsMacroKey = @"Replace found text as macro";

static BDSKFindController *sharedFC = nil;

enum {
    FCSubstringSearch = 0,
    FCRegexSearch = 1
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
    [defaults setInteger:FCSubstringSearch forKey:BDSKFindControllerDefaultFindAndReplaceTypeKey];  // disable regexes
    [defaults setBool:NO forKey:BDSKFindControllerCaseSensitiveFindAndReplaceKey];  // case insensitive
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
    [searchTypeMatrix selectCellWithTag:[defaults integerForKey:BDSKFindControllerDefaultFindAndReplaceTypeKey]];
    [caseSensitiveCheckbox setState:([defaults boolForKey:BDSKFindControllerCaseSensitiveFindAndReplaceKey] ? NSOnState : NSOffState)];
    [searchSelectionCheckbox setState:([defaults boolForKey:BDSKFindControllerFindAndReplaceSelectedItemsKey] ? NSOnState : NSOffState)];
    [findAsMacroCheckbox setState:([defaults boolForKey:BDSKFindControllerFindAsMacroKey] ? NSOnState : NSOffState)];
    [replaceAsMacroCheckbox setState:([defaults boolForKey:BDSKFindControllerReplaceAsMacroKey] ? NSOnState : NSOffState)];
    
    // get the current search text from the find pasteboard
    NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSFindPboard];
    NSString *availableType = [pboard availableTypeFromArray:[NSArray arrayWithObject:NSStringPboardType]];
    if(availableType)
        availableType = [pboard stringForType:NSStringPboardType];
    [findTextField setStringValue:(availableType != nil ? availableType : @"")];
    [self clearFrontDocumentQuickSearch];
}

#pragma mark Validation

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor{
    NSString *reason = nil;

    if(control == findTextField){
        if([defaults integerForKey:BDSKFindControllerDefaultFindAndReplaceTypeKey] == FCRegexSearch){ // check the regex
            if(![self currentRegexIsValid]){
                NSBeginAlertSheet(NSLocalizedString(@"Invalid Regular Expression.", @""),
                                  nil,nil,nil,[self window],nil,NULL,NULL,NULL,
                                  NSLocalizedString(@"The regular expression you entered is not valid.", @""));
                return NO;
            }
        }
        if([defaults boolForKey:BDSKFindControllerFindAsMacroKey]){ // check the "find" complex string
            if(![self stringIsValidAsComplexString:[control stringValue] errorMessage:&reason]){
                NSBeginAlertSheet(NSLocalizedString(@"Invalid BibTeX Macro", @""),
                                  nil,nil,nil,[self window],nil,NULL,NULL,NULL,
                                  reason);
                return NO;
            }
        }  
    }
    
    if(control == replaceTextField && [defaults boolForKey:BDSKFindControllerReplaceAsMacroKey]){ // check the "replace" complex string
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
        compStr = [BDSKComplexString complexStringWithBibTeXString:[findTextField stringValue] macroResolver:nil];
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

    int tag = [[sender selectedCell] tag];
    switch(tag){
        case FCSubstringSearch:
            [defaults setInteger:tag forKey:BDSKFindControllerDefaultFindAndReplaceTypeKey];
            break;
            
        case FCRegexSearch:
            if([self currentRegexIsValid]){
                [defaults setInteger:FCRegexSearch forKey:BDSKFindControllerDefaultFindAndReplaceTypeKey];
            } else {
                [defaults setInteger:FCSubstringSearch forKey:BDSKFindControllerDefaultFindAndReplaceTypeKey];
                NSBeginAlertSheet(NSLocalizedString(@"Invalid Regular Expression.", @""),
                                  nil,nil,nil,[self window],self,@selector(regexCheckSheetDidEnd:returnCode:contextInfo:),NULL,findTextField,
                                  NSLocalizedString(@"The entry \"%@\" is not a valid regular expression.", @""), [findTextField stringValue]);  
            }
            break;
            
        default:
            break;
    }
    // don't call updateUI here, or we can end up with characters trimmed from the find text field
    // if we were unable to switch to the regex type and the find text field was selected
}

- (void)regexCheckSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(NSTextField *)textField{
    // this is a weird hack; if I don't call setAllowsEmptySelection:, I can't change the selection (rather, it changes
    // so that the matrix knows the correct selected cell, but the change isn't visible)
    [searchTypeMatrix setAllowsEmptySelection:YES];
    [searchTypeMatrix deselectAllCells];
    [searchTypeMatrix selectCellWithTag:FCSubstringSearch];
    [searchTypeMatrix setAllowsEmptySelection:NO];
    
    if(![[self window] makeFirstResponder:textField])
        return;
    NSText *fe = [[self window] fieldEditor:YES forObject:textField];
    [fe setSelectedRange:NSMakeRange([[textField stringValue] length], 0)];
}

- (IBAction)toggleCaseSensitivity:(id)sender{
    [defaults setBool:([sender state] == NSOnState) forKey:BDSKFindControllerCaseSensitiveFindAndReplaceKey];
    [self updateUI];
}

- (IBAction)toggleSelection:(id)sender{
    [defaults setBool:([sender state] == NSOnState) forKey:BDSKFindControllerFindAndReplaceSelectedItemsKey];
    [self updateUI];
}

- (IBAction)toggleFindAsMacro:(id)sender{
    int state = [sender state];
    NSString *reason = nil;
    if(state == NSOnState && ![self stringIsValidAsComplexString:[findTextField stringValue] errorMessage:&reason]){
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
    if(state == NSOnState && ![self stringIsValidAsComplexString:[replaceTextField stringValue] errorMessage:&reason]){
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

#pragma mark Find and Replace methods

- (IBAction)findAndHighlight:(id)sender{
    [self findAndHighlightWithReplace:NO];
}

- (IBAction)replaceAndHighlightNext:(id)sender{
    [self findAndHighlightWithReplace:YES];
}

- (void)findAndHighlightWithReplace:(BOOL)replace{
    
    BibDocument *theDocument = [[NSDocumentController sharedDocumentController] currentDocument];
    if(!theDocument)
        return;
    [self clearFrontDocumentQuickSearch];
   
    // this can change between clicks of the Find button, so we can't cache it
    NSArray *currItems = [self currentFoundItemsInDocument:theDocument];
    //NSLog(@"currItems has %@", currItems);
    if(currItems == nil){
        NSBeep();
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
        if(replace)
            [self findAndReplaceInItems:[NSArray arrayWithObject:bibItem] ofDocument:theDocument];
        
        // see if current search results have an item identical to the selected one
        indexOfSelectedItem = [currItems indexOfObjectIdenticalTo:bibItem];
        if(indexOfSelectedItem != NSNotFound){ // we've already selected an item from the search results...so select the next one
            indexOfSelectedItem++;
            if(indexOfSelectedItem >= [currItems count])
                indexOfSelectedItem = 0; // wrap around
        } else {
            // the selected pub was some item we don't care about, so select item 0
            indexOfSelectedItem = 0;
        }
    }
    
    [theDocument highlightBib:[currItems objectAtIndex:indexOfSelectedItem]];
}

- (IBAction)replaceAll:(id)sender{

    BibDocument *theDocument = [[NSDocumentController sharedDocumentController] currentDocument];
    if(!theDocument)
        return;
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
    [self findAndReplaceInItems:publications ofDocument:theDocument];
}

- (NSArray *)currentFoundItemsInDocument:(BibDocument *)theDocument{
    [self clearFrontDocumentQuickSearch];
    
    NSEnumerator *pubE;
    
    // use all shown pubs; not just selection, since our caller is going to change the selection
    NSArray *publications = [theDocument displayedPublications];
    
    // we want to start with the uppermost one, so check the document's sort order
    if([theDocument isSortDescending]){
        //NSLog(@"sort is descending");
        pubE = [publications reverseObjectEnumerator];
    } else {
        //NSLog(@"sort is ascending");
        pubE = [publications objectEnumerator]; // an enumerator of BibItems
    }
    BibItem *bibItem;
    
    // get the current values from the find panel
    NSString *findStr = [findTextField stringValue];
    NSString *field = [defaults objectForKey:BDSKFindControllerLastFindAndReplaceFieldKey];
    
    BOOL isRegex = ([defaults integerForKey:BDSKFindControllerDefaultFindAndReplaceTypeKey] == FCRegexSearch);
    BOOL isCaseSensitive = [defaults boolForKey:BDSKFindControllerCaseSensitiveFindAndReplaceKey];
    
    // search options; currently only case insensitive is supported
    unsigned searchOpts = 0;
    if(!isCaseSensitive)
        searchOpts = searchOpts | NSCaseInsensitiveSearch;
    
    NSString *origStr;
    NSMutableArray *arrayOfItems = [NSMutableArray array];
    
    // set up the regular expression if necessary
    AGRegex *theRegex = nil;
    if(isRegex && [self currentRegexIsValid]){
        theRegex = [AGRegex regexWithPattern:findStr options:(isCaseSensitive ? 0 : AGRegexCaseInsensitive)];
    }
    
    // macro settings
    BOOL findAsMacro = [defaults boolForKey:BDSKFindControllerFindAsMacroKey];
    
    while(bibItem = [pubE nextObject]){
        origStr = [bibItem valueOfField:field inherit:NO];
        
        if(origStr == nil)
            continue; // we don't want to add a field or set it to nil
        
        if(findAsMacro)
            origStr = [origStr stringAsBibTeXString];
        
        if(!isRegex){
            // find and add using NSMutableString methods
            if([origStr rangeOfString:findStr options:searchOpts].location != NSNotFound)
                [arrayOfItems addObject:bibItem];
        } else {
            // use AGRegex for find and replace
            if([[theRegex findInString:origStr] range].location != NSNotFound)
                [arrayOfItems addObject:bibItem];
        }
    }
    return ([arrayOfItems count] ? arrayOfItems : nil);
}


- (void)findAndReplaceInItems:(NSArray *)arrayOfPubs ofDocument:(BibDocument *)theDocument{
    [self clearFrontDocumentQuickSearch];

    NSEnumerator *pubE = [arrayOfPubs objectEnumerator]; // an enumerator of BibItems
    BibItem *bibItem;
    
    // get the current values from the find panel
    NSString *findStr = [findTextField stringValue];
    NSString *replStr = [replaceTextField stringValue];
    NSString *field = [defaults objectForKey:BDSKFindControllerLastFindAndReplaceFieldKey];
    
    BOOL isRegex = ([defaults integerForKey:BDSKFindControllerDefaultFindAndReplaceTypeKey] == FCRegexSearch);
    BOOL isCaseSensitive = [defaults boolForKey:BDSKFindControllerCaseSensitiveFindAndReplaceKey];
    
    // search options; currently only case insensitive is supported
    unsigned searchOpts = 0;
    if(!isCaseSensitive)
        searchOpts = searchOpts | NSCaseInsensitiveSearch;

    NSString *origStr;
    NSMutableString *newStr;

    // set up the regular expression if necessary
    AGRegex *theRegex = nil;
    if(isRegex && [self currentRegexIsValid]){
        theRegex = [AGRegex regexWithPattern:findStr options:(isCaseSensitive ? 0 : AGRegexCaseInsensitive)];
    }
    
    // macro settings
    BOOL findAsMacro = [defaults boolForKey:BDSKFindControllerFindAsMacroKey];
    BOOL replaceAsMacro = [defaults boolForKey:BDSKFindControllerReplaceAsMacroKey];

    while(bibItem = [pubE nextObject]){
        origStr = [bibItem valueOfField:field inherit:NO];
        
        if(origStr == nil)
            continue; // we don't want to add a field or set it to nil
        
        if(findAsMacro)
            origStr = [origStr stringAsBibTeXString];
        
        if(!isRegex){
            // find and replace using NSMutableString methods
            if([origStr rangeOfString:findStr options:searchOpts].location != NSNotFound){
                newStr = [origStr mutableCopy];
                [newStr replaceOccurrencesOfString:findStr withString:replStr options:searchOpts range:NSMakeRange(0, [newStr length])];
                if(replaceAsMacro){
                    BDSKComplexString *complexStr = [BDSKComplexString complexStringWithBibTeXString:newStr macroResolver:theDocument];
                    [bibItem setField:field toValue:complexStr];
                } else {
                    [bibItem setField:field toValue:newStr];
                }
                [newStr release];
            }
        } else {
            // use AGRegex for find and replace
            origStr = [theRegex replaceWithString:replStr inString:origStr];
            if(replaceAsMacro){
                BDSKComplexString *complexStr = [BDSKComplexString complexStringWithBibTeXString:origStr macroResolver:theDocument];
                [bibItem setField:field toValue:complexStr];
            } else {
                [bibItem setField:field toValue:origStr];
            }            
        }
    }
}

@end
