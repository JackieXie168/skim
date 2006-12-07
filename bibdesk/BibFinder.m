//  BibFinder.m

//  Created by Michael McCracken on Tue Jan 22 2002.
//  Copyright (c) 2001 Michael McCracken. All rights reserved.
/*
This software is Copyright (c) 2002, Michael O. McCracken
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
-  Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
-  Neither the name of Michael O. McCracken nor the names of any contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "BibFinder.h"
#import "BDSKPreviewer.h"
#import "BibDocument.h"
#import "BibItem.h"

static BibFinder *sharedFinder = nil;

@implementation BibFinder

+ (BibFinder *)sharedFinder{
    if(!sharedFinder){
        sharedFinder = [[BibFinder alloc] init];
    }
    return sharedFinder;
}

- (id)init
{
//    NSLog(@"initing finder.");
    self = [super initWithWindowNibName:@"BibFinder"];
    foundBibs = [[NSMutableArray arrayWithCapacity:1] retain];
    foundBibDocs = [[NSMutableArray arrayWithCapacity:1] retain];
    bibKeys = [[[NSMutableArray arrayWithObjects: @"Address", @"Author", @"Booktitle", @"Chapter", @"Edition", @"Editor", @"Howpublished", @"Institution", @"Journal", @"Month", @"Number", @"Organization", @"Pages", @"Publisher", @"School", @"Series", @"Title", @"Type", @"Volume", @"Year", @"Note", @"Code", @"Url", @"Crossref", @"Annote", @"Abstract", @"Keywords", nil] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]retain];
    PDFpreviewer = [BDSKPreviewer sharedPreviewer];
    return self;
}

- (void)addKey:(NSString *)key{
    [bibKeys addObject:key];
}

- (void)windowDidLoad{
    
    [keySelectButton selectItemAtIndex:0];
    [tableView setDoubleAction:@selector(editPub:)];
}

- (IBAction)editPub:(id)sender{
    int idx = [tableView selectedRow];
    // first bring the window of that document to the front
    [[foundBibDocs objectAtIndex:idx] showWindows];
        // then tell it to edit the pub.
    [[foundBibDocs objectAtIndex:idx] editPub: [foundBibs objectAtIndex:idx]];
}

// search is kind of broken...
// i ended up having to just add Keywords to bibkeys for that to work
// i should be able to search in keys that aren't in bibkeys.
- (IBAction)search:(id)sender{
    NSString *key = [keySelectButton stringValue];
    if([bibKeys containsObject:key]){
        [keySelectButton selectItemAtIndex:[bibKeys indexOfObject:key]]; //why do i have to do this? this sucks.
    }
    if ([keySelectButton indexOfSelectedItem] != -1) {
        [self searchForText:[searchTextField stringValue] inKey:[bibKeys objectAtIndex:[keySelectButton indexOfSelectedItem]]];
    }else{
        [self searchForText:[searchTextField stringValue] inKey:key];
        //have to search for some key. what to do?
    }
}


- (NSMutableArray *)itemsMatchingConstraints:(NSDictionary *)constraints{
    NSDocumentController *dc = [NSDocumentController sharedDocumentController];
    NSEnumerator *docEnum = [[dc documents] objectEnumerator];
    NSEnumerator *bibEnum;
    NSEnumerator *constraintKeyEnum = [constraints keyEnumerator];
    BibDocument *doc;
    BibItem *bib;
    NSRange r;
    NSString *constraintKey;
    NSString *val;
    NSMutableArray *returnArray = [NSMutableArray array];
    NSMutableArray *totalArray = [NSMutableArray array];
    
    
    while (doc = [docEnum nextObject]) {
        bibEnum = [[doc publications] objectEnumerator];
        [totalArray addObjectsFromArray:[doc publications]];
    }

    [returnArray setArray:totalArray];// start out with everything matching.
    while(constraintKey = [constraintKeyEnum nextObject]){

        bibEnum = [totalArray objectEnumerator]; // reset the enumerator
        
        while(bib = [bibEnum nextObject]){
            val = [bib valueOfField:constraintKey];
            if(val && (![@"" isEqualToString:val])){
                r = [val rangeOfString:[constraints objectForKey:constraintKey]
                               options:NSCaseInsensitiveSearch];
                if(r.location == NSNotFound){
                    [returnArray removeObjectIdenticalTo:bib];
                }
            }else{
                [returnArray removeObjectIdenticalTo:bib];
            }
        } // for each BI.
        
        // now we've checked all bibs against the constraint specified in constraintKey.
        // to optimize, set totalArray to returnArray so we don't search through ones we've already ruled out:
        [totalArray setArray:returnArray];
    } // for each constraint
    return returnArray;
}

- (NSMutableArray *)itemsMatchingText:(NSString *)s inKey:(NSString *)key{
    NSDocumentController *dc = [NSDocumentController sharedDocumentController];
    NSEnumerator *docEnum = [[dc documents] objectEnumerator];
    NSEnumerator *bibEnum;
    BibDocument *doc;
    BibItem *bib;
    NSRange r;
    NSString *val;
    NSMutableArray *returnArray = [NSMutableArray arrayWithCapacity:1];

    while (doc = [docEnum nextObject]) {
        bibEnum = [[doc publications] objectEnumerator];
        
        while(bib = [bibEnum nextObject]){
            val = [bib valueOfField:key];
            if((val != nil) && (![@"" isEqualToString:val])) {
                r = [val rangeOfString:s options:NSCaseInsensitiveSearch];
                if(r.location != NSNotFound){
                    [returnArray addObject:bib];
                }
            }
        }
    }
    return returnArray;
}

- (NSMutableArray *)itemsMatchingCiteKey:(NSString *)key{
    NSDocumentController *dc = [NSDocumentController sharedDocumentController];
    NSEnumerator *docEnum = [[dc documents] objectEnumerator];
    NSEnumerator *bibEnum;
    BibDocument *doc;
    BibItem *bib;
    NSRange r;
    NSString *val;
    NSMutableArray *returnArray = [NSMutableArray arrayWithCapacity:1];
	NSDictionary *itemDict = nil;

    while (doc = [docEnum nextObject]) {
        bibEnum = [[doc publications] objectEnumerator];

        while(bib = [bibEnum nextObject]){
            val = [bib citeKey];
            if((val != nil) && (![@"" isEqualToString:val])) {
                r = [val rangeOfString:key options:NSCaseInsensitiveSearch];
                if(r.location != NSNotFound){
					itemDict = [NSDictionary dictionaryWithObjectsAndKeys:bib,@"BibItem",
						doc,@"BibDocument",nil];
                    [returnArray addObject:itemDict];
                }
            }
        }
    }
    return returnArray;
}

- (BOOL)searchForText:(NSString *)s inKey:(NSString *)key{
    NSDocumentController *dc = [NSDocumentController sharedDocumentController];
    NSEnumerator *docEnum = [[dc documents] objectEnumerator];
    NSEnumerator *bibEnum;
    BibDocument *doc;
    BibItem *bib;
    NSRange r;
    NSString *val;

    [foundBibs removeAllObjects];
    [foundBibDocs removeAllObjects];
    
    while (doc = [docEnum nextObject]) {
        bibEnum = [[doc publications] objectEnumerator];

        while(bib = [bibEnum nextObject]){
            val = [bib valueOfField:key];
            if((val != nil) && (![@"" isEqualToString:val])) {
                r = [val rangeOfString:s options:NSCaseInsensitiveSearch];
                if(r.location != NSNotFound){
                    [foundBibs addObject:bib];
                    [foundBibDocs addObject:doc];
                }
            }
        }
    }
    [tableView reloadData];
    if ([foundBibs count] == 0) {
        [resultsField setStringValue: [NSString stringWithString:@"No Matching Publications."]];
        return NO;
    }
    if ([foundBibs count] == 1) {
        [resultsField setStringValue: [NSString stringWithFormat:@"%d Publication found.",
            [foundBibs count], nil]];
    }else{
        [resultsField setStringValue: [NSString stringWithFormat:@"%d Publications found.",
            [foundBibs count], nil]];
    }

    return YES;
}

- (IBAction)copy:(id)sender{
    OFPreferenceWrapper *sud = [OFPreferenceWrapper sharedPreferenceWrapper];
    if([[sud objectForKey:BDSKDragCopyKey] intValue] == 0){
        [self copyAsBibTex:self];
    }else if([[sud objectForKey:BDSKDragCopyKey] intValue] == 1){
        [self copyAsTex:self];
    }else if([[sud objectForKey:BDSKDragCopyKey] intValue] == 2){
        [self copyAsPDF:self];
    }else if([[sud objectForKey:BDSKDragCopyKey] intValue] == 3){
        [self copyAsRTF:self];
    }
}

- (IBAction)copyAsBibTex:(id)sender{
    NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSGeneralPboard];
    NSEnumerator *e = [self selectedPubEnumerator];
    NSMutableString *s = [[NSMutableString string] retain];
    NSNumber *i;
    [pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
    while(i=[e nextObject]){
        [s appendString:[[foundBibs objectAtIndex:[i intValue]] bibTeXString]];
    }
    [pasteboard setString:s forType:NSStringPboardType];
}

- (IBAction)copyAsTex:(id)sender{
    NSEnumerator *e = [self selectedPubEnumerator];
	OFPreferenceWrapper *sud = [OFPreferenceWrapper sharedPreferenceWrapper];
    NSString *citeString = [sud stringForKey:BDSKCiteStringKey];
	NSString *startCiteBracket = [sud stringForKey:BDSKCiteStartBracketKey]; 
	NSString *endCiteBracket = [sud stringForKey:BDSKCiteEndBracketKey]; 
    NSMutableString *s = [NSMutableString stringWithFormat:@"\\%@%@", citeString, startCiteBracket];
    NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSGeneralPboard];
    NSNumber *i;
    BOOL sep = ([[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKSeparateCiteKey] == NSOnState);
    
    [pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
    while(i=[e nextObject]){
        [s appendString:[[foundBibs objectAtIndex:[i intValue]] citeKey]];
        if(sep)
            [s appendFormat:@"%@ \\%@%@", startCiteBracket, citeString, endCiteBracket];
        else
            [s appendString:@", "];
    }
    if(sep)
        [s replaceCharactersInRange:[s rangeOfString:[NSString stringWithFormat:@"%@ \\%@%@", startCiteBracket, citeString, endCiteBracket] options:NSBackwardsSearch] withString:@"}"];
    else
        [s replaceCharactersInRange:[s rangeOfString:@", " options:NSBackwardsSearch] withString:endCiteBracket];
    
    [pasteboard setString:s forType:NSStringPboardType];
}

- (IBAction)copyAsPDF:(id)sender{
    NSPasteboard *pb = [NSPasteboard pasteboardWithName:NSGeneralPboard];
    NSData *d;
    NSNumber *i;
    NSEnumerator *e = [self selectedPubEnumerator];
    NSMutableString *bibString = [NSMutableString string];

    [pb declareTypes:[NSArray arrayWithObject:NSPDFPboardType] owner:nil];
    while(i = [e nextObject]){
        [bibString appendString:[[foundBibs objectAtIndex:[i intValue]] bibTeXString]];
    }
    d = [PDFpreviewer PDFDataFromString:bibString];
    [pb setData:d forType:NSPDFPboardType];
    
}

- (IBAction)copyAsRTF:(id)sender{
    NSPasteboard *pb = [NSPasteboard pasteboardWithName:NSGeneralPboard];
    NSData *d;
    NSNumber *i;
    NSEnumerator *e = [self selectedPubEnumerator];
    NSMutableString *bibString = [NSMutableString string];
    
    [pb declareTypes:[NSArray arrayWithObject:NSRTFPboardType] owner:nil];
    while(i = [e nextObject]){
        [bibString appendString:[[foundBibs objectAtIndex:[i intValue]] bibTeXString]];
    }
    [PDFpreviewer PDFFromString:bibString];
    d = [PDFpreviewer rtfDataPreview];
    [pb setData:d forType:NSRTFPboardType];
    
}


- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem{
    if(menuItem == ctxCopyBibTex || menuItem == ctxCopyTex || menuItem == ctxCopyPDF){
        if([tableView selectedRow] != -1)
            return YES;
        else
            return NO;
    }else{
        // validate other menu items:
        return YES;
    }
}

- (int)numberOfSelectedPubs{
    return [tableView numberOfSelectedRows];
}

- (NSEnumerator *)selectedPubEnumerator{
    return [tableView selectedRowEnumerator];
}


// ----------------------------------------------------------------------------------------
// Combobox  delegate methods
// ----------------------------------------------------------------------------------------

//    An NSComboBox uses this method to perform incremental-or "smart"-searches when the user types into the text field with the pop-up list displayed. Your  implementation of this method should return the index for the item that matches aString, or NSNotFound if no item matches. This method is optional; if you don't provide an implementation for this method, no searches occur.


- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(int)index{
    return [bibKeys objectAtIndex:index];
}

// Implement this method to return the object that corresponds to the item at index in aComboBox. Your data source must implement this method.

// this returns the number of items in the combobox
- (int)numberOfItemsInComboBox:(NSComboBox *)aComboBox{
    return [bibKeys count];
}


// ----------------------------------------------------------------------------------------
// BDSKTableView delegate methods:
// ----------------------------------------------------------------------------------------
- (int)numberOfRowsInTableView:(NSTableView *)tView{
    return [foundBibs count];
}

- (id)tableView:(NSTableView *)tView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row{
    BibItem *aBib = (BibItem *)[foundBibs objectAtIndex:row];
    NSArray *auths = [aBib pubAuthors];

    if([[tableColumn identifier] isEqualToString: BDSKCiteKeyString] ){
        return [aBib citeKey];
    }else if([[tableColumn identifier] isEqualToString: BDSKTitleString] ){
        return [aBib title];
    }else if([[tableColumn identifier] isEqualToString: BDSKDateString] ){
        if([aBib date] == nil)
            return @"No date";
        else if([[aBib valueOfField:BDSKMonthString] isEqualToString:@""])
            return [[aBib date] descriptionWithCalendarFormat:@"%Y"];
        else return [[aBib date] descriptionWithCalendarFormat:@"%b %Y"];
    }else if([[tableColumn identifier] isEqualToString: @"1st Author"] ){
        if([auths count] > 0)
            return [[aBib authorAtIndex:0] name];
        else
            return @"-";
    }else if([[tableColumn identifier] isEqualToString: @"2nd Author"] ){
        if([auths count] > 1)
            return [[aBib authorAtIndex:1] name];
        else
            return @"-";
    }else if([[tableColumn identifier] isEqualToString: @"3rd Author"] ){
        if([auths count] > 2)
            return [[aBib authorAtIndex:2] name];
        else
            return @"-";
    }else{
        return nil; // This really shouldn't happen. Maybe I should abort here, but I won't
    }
    
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification{
    //nobody cares... do we need this?
}

- (BOOL)tableView:(NSTableView *)tv writeRows:(NSArray*)rows toPasteboard:(NSPasteboard*)pboard{
    OFPreferenceWrapper *sud = [OFPreferenceWrapper sharedPreferenceWrapper];
    BOOL yn;
    NSString *citeString = [sud stringForKey:BDSKCiteStringKey];
	NSString *startCiteBracket = [sud stringForKey:BDSKCiteStartBracketKey]; 
    NSString *startCite = [NSString stringWithFormat:@"\\%@%@", citeString, startCiteBracket];
	NSString *endCiteBracket = [sud stringForKey:BDSKCiteEndBracketKey]; 
	
    NSMutableString *s = [[NSMutableString string] retain];
    NSEnumerator *enumerator = [rows objectEnumerator];
    NSNumber *i;
    BOOL sep = ([[OFPreferenceWrapper sharedPreferenceWrapper] integerForKey:BDSKSeparateCiteKey] == NSOnState);


    if(([[sud objectForKey:BDSKDragCopyKey] intValue] == 1) && !sep)
        [s appendString:startCite];
    
    while (i = [enumerator nextObject]) {
        if(([[sud objectForKey:BDSKDragCopyKey] intValue] == 0) ||
           ([[sud objectForKey:BDSKDragCopyKey] intValue] == 2)){
            [s appendString:[[foundBibs objectAtIndex:[i intValue]] bibTeXString]];
        }
        if([[sud objectForKey:BDSKDragCopyKey] intValue] == 1){
            if(sep) [s appendString:startCite];
            [s appendString:[[foundBibs objectAtIndex:[i intValue]] citeKey]];
            if(sep) [s appendString:endCiteBracket];
            else [s appendString:@","];
        }
    }
    if([[sud objectForKey:BDSKDragCopyKey] intValue] == 1){
        if(!sep)[s replaceCharactersInRange:[s rangeOfString:@"," options:NSBackwardsSearch] withString:endCiteBracket];
    }
    if(([[sud objectForKey:BDSKDragCopyKey] intValue] == 0) ||
       ([[sud objectForKey:BDSKDragCopyKey] intValue] == 1)){
        [pboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
        yn = [pboard setString:s forType:NSStringPboardType];
    }else{
        [pboard declareTypes:[NSArray arrayWithObject:NSPDFPboardType] owner:nil];
        yn = [pboard setData:[PDFpreviewer PDFDataFromString:s] forType:NSPDFPboardType];
    }
    return yn;
    
}

@end
