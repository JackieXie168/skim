//  BDSKCharacterConversion.m
//  BibDesk
//
//  Created by Christiaan Hofman on 5/4/05.
/*
 This software is Copyright (c) 2005,2006,2007
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

#import "BDSKCharacterConversion.h"
#import "BibAppController.h"
#import "BDSKConverter.h"
#import "NSFileManager_BDSKExtensions.h"
#import "BDSKAlert.h"

static BDSKCharacterConversion *sharedConversionEditor;

@implementation BDSKCharacterConversion

+ (BDSKCharacterConversion *)sharedConversionEditor{
    if (!sharedConversionEditor) {
        sharedConversionEditor = [[BDSKCharacterConversion alloc] init];
    }
    return sharedConversionEditor;
}

- (id)init
{
    if (self = [super initWithWindowNibName:@"BDSKCharacterConversion"]) {    
		
		oneWayDict = [[NSMutableDictionary alloc] initWithCapacity:1];
		twoWayDict = [[NSMutableDictionary alloc] initWithCapacity:1];
		romanSet = [[NSMutableSet alloc] initWithCapacity:1];
		texSet = [[NSMutableSet alloc] initWithCapacity:1];
		currentDict = twoWayDict;
		
		ignoreEdit = NO;
		
		[self updateDicts];
		
	}
    return self;
}

- (void)dealloc
{
    [oneWayDict release];
    [twoWayDict release];
	[currentArray release];
	[texFormatter release];
	[romanSet release];
	[texSet release];
    [super dealloc];
}

- (void)awakeFromNib {
	texFormatter = [[BDSKTeXFormatter alloc] init];
    NSTableColumn *tc = [tableView tableColumnWithIdentifier:@"roman"];
    [[tc dataCell] setFormatter:[[[BDSKRomanCharacterFormatter alloc] init] autorelease]];
	tc = [tableView tableColumnWithIdentifier:@"tex"];
	[[tc dataCell] setFormatter:texFormatter];
	[self updateButtons];
}

- (void)updateDicts {
	// try to read the user file in the Application Support directory
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *applicationSupportPath = [fm currentApplicationSupportPathForCurrentUser];
	NSString *charConvPath = [applicationSupportPath stringByAppendingPathComponent:CHARACTER_CONVERSION_FILENAME];
	NSDictionary *tmpDict = [NSDictionary dictionaryWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:CHARACTER_CONVERSION_FILENAME]];
	
	[oneWayDict removeAllObjects];
	[twoWayDict removeAllObjects];
	[romanSet removeAllObjects];
	[texSet removeAllObjects];
	
	[romanSet addObjectsFromArray:[[tmpDict objectForKey:ONE_WAY_CONVERSION_KEY] allKeys]];
	[romanSet addObjectsFromArray:[[tmpDict objectForKey:ROMAN_TO_TEX_KEY] allKeys]];
	[texSet addObjectsFromArray:[[tmpDict objectForKey:TEX_TO_ROMAN_KEY] allKeys]];
	
	if ([fm fileExistsAtPath:charConvPath]) {
		tmpDict = [NSDictionary dictionaryWithContentsOfFile:charConvPath];
		
		[oneWayDict addEntriesFromDictionary:[tmpDict objectForKey:ONE_WAY_CONVERSION_KEY]];
		[twoWayDict addEntriesFromDictionary:[tmpDict objectForKey:ROMAN_TO_TEX_KEY]];
		
		[romanSet addObjectsFromArray:[oneWayDict allKeys]];
		[romanSet addObjectsFromArray:[twoWayDict allKeys]];
		[texSet addObjectsFromArray:[twoWayDict allValues]];
	}
	
	[currentArray autorelease];
	currentArray = [[currentDict allKeys] mutableCopy];
	
	validRoman = YES;
	validTex = YES;
	
	[self setDocumentEdited:NO];
}

#pragma mark Acessors

- (int)listType {
    return (currentDict == oneWayDict)? 1 : 2;
}

- (void)setListType:(int)listType {
	if ([self listType] == listType)
		return;
	if (!validRoman || !validTex) {
        // NSAlert does not work here for some reason
        BDSKAlert *alert = [BDSKAlert alertWithMessageText:NSLocalizedString(@"Invalid Conversion", @"Message in alert dialog when entering invalid TeX conversion")
                                             defaultButton:NSLocalizedString(@"OK", @"Button title")
                                           alternateButton:nil
                                               otherButton:nil
                                 informativeTextWithFormat:NSLocalizedString(@"The last item you entered is invalid or a duplicate. Please first edit it.", @"Informative text in alert dialog")];
        [alert beginSheetModalForWindow:[self window]];
		[listButton selectItemAtIndex:[listButton indexOfItemWithTag:[self listType]]];
		return;
	}
	
	currentDict = (listType == 1)? oneWayDict : twoWayDict;
	[currentArray autorelease];
	currentArray = [[currentDict allKeys] mutableCopy];
	
	validRoman = YES;
	validTex = YES;
	
	NSTableColumn *tc = [tableView tableColumnWithIdentifier:@"tex"];
	if (listType == 2) {
		[[tc dataCell] setFormatter:texFormatter];
	} else {
		[[tc dataCell] setFormatter:nil];
	}
	[tableView reloadData];
}

- (NSDictionary *)oneWayDict {
    return [[oneWayDict copy] autorelease];
}

- (void)setOneWayDict:(NSDictionary *)newOneWayDict {
    if (oneWayDict != newOneWayDict) {
        [oneWayDict release];
        oneWayDict = [newOneWayDict mutableCopy];
    }
}

- (NSDictionary *)twoWayDict {
    return [[twoWayDict copy] autorelease];
}

- (void)setTwoWayDict:(NSDictionary *)newTwoWayDict {
    if (twoWayDict != newTwoWayDict) {
        [twoWayDict release];
        twoWayDict = [newTwoWayDict mutableCopy];
    }
}

#pragma mark Actions

- (IBAction)dismiss:(id)sender {
    [self finalizeChangesIgnoringEdit:NO]; // commit edit before saving
	
    if ([sender tag] == NSOKButton) {
        if (!validRoman || !validTex) {
            BDSKAlert *alert = [BDSKAlert alertWithMessageText:NSLocalizedString(@"Invalid Conversion", @"Message in alert dialog when entering invalid TeX conversion")
                                                 defaultButton:NSLocalizedString(@"OK", @"Button title")
                                               alternateButton:nil
                                                   otherButton:nil
                                     informativeTextWithFormat:NSLocalizedString(@"The last item you entered is invalid or a duplicate. Please first edit it.", @"Informative text in alert dialog")];
            [alert beginSheetModalForWindow:[self window]];
            return;
        }
        
        NSString *error = nil;
        NSPropertyListFormat format = NSPropertyListXMLFormat_v1_0;
        
        NSMutableDictionary *reverseDict = [NSMutableDictionary dictionaryWithCapacity:[twoWayDict count]];
        NSEnumerator *rEnum = [twoWayDict keyEnumerator];
        NSString *roman;
        while (roman = [rEnum nextObject]) {
            [reverseDict setObject:roman forKey:[twoWayDict objectForKey:roman]];
        }
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:oneWayDict, ONE_WAY_CONVERSION_KEY, 
                                                                        twoWayDict, ROMAN_TO_TEX_KEY,
                                                                        reverseDict, TEX_TO_ROMAN_KEY, nil];
        
        NSData *data = [NSPropertyListSerialization dataFromPropertyList:dict
                                                                  format:format 
                                                        errorDescription:&error];
        if (error) {
            NSLog(@"Error writing: %@", error);
            [error release];
        } else {
            NSString *applicationSupportPath = [[NSFileManager defaultManager] currentApplicationSupportPathForCurrentUser]; 
            NSString *charConvPath = [applicationSupportPath stringByAppendingPathComponent:CHARACTER_CONVERSION_FILENAME];
            [data writeToFile:charConvPath atomically:YES];
        }
        
        // tell the converter to reload its dictionaries
        [[BDSKConverter sharedConverter] loadDict];
        
        [self setDocumentEdited:NO];
	} else {
        [self updateDicts];
        [tableView reloadData];
    }
    
    [super dismiss:sender];
}

- (IBAction)changeList:(id)sender {
    [self finalizeChangesIgnoringEdit:NO]; // commit edit before switching
	[self setListType:[[sender selectedItem] tag]];
}

- (IBAction)add:(id)sender {
    [self finalizeChangesIgnoringEdit:NO]; // make sure we are not editing
	
	NSString *newRoman = [NSString stringWithFormat:@"%C",0x00E4];
    NSString *newTex = [NSString stringWithString:@"{\\\"a}"];
	
	[currentArray addObject:newRoman];
	[currentDict setObject:newTex forKey:newRoman];
	[romanSet addObject:newRoman];
	if ([self listType] == 2)
		[texSet addObject:newTex];
	
	validRoman = NO;
	validTex = ([self listType] == 1);
	
    [tableView reloadData];
	
    int row = [currentArray indexOfObject:newRoman];
    [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    [tableView editColumn:0 row:row withEvent:nil select:YES];
	
	[self setDocumentEdited:YES];
}

- (IBAction)remove:(id)sender {
    [self finalizeChangesIgnoringEdit:YES]; // make sure we are not editing
	
	int row = [tableView selectedRow];
	if (row == -1) return;
	NSString *oldRoman = [currentArray objectAtIndex:row];
	NSString *oldTex = [currentDict objectForKey:oldRoman];
	[currentArray removeObject:oldRoman];
	[currentDict removeObjectForKey:oldRoman];
	[romanSet removeObject:oldRoman];
	if ([self listType] == 2)
		[texSet removeObject:oldTex];
	
	validRoman = YES;
	validTex = YES;
	
    [tableView reloadData];
	
    [tableView deselectAll:nil];
	
	[self setDocumentEdited:YES];
}

#pragma mark UI methods

- (void)updateButtons {
	[addButton setEnabled:(validRoman && validTex)];
	[removeButton setEnabled:[tableView selectedRow] != -1];
}

- (void)finalizeChangesIgnoringEdit:(BOOL)flag {
	ignoreEdit = flag;
	[[self window] makeFirstResponder:nil];
	ignoreEdit = NO;
}

#pragma mark NSTableview Datasource

- (int)numberOfRowsInTableView:(NSTableView *)tv {
	return [currentArray count];
}

- (id)tableView:(NSTableView *)tv objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row{
	NSString *roman = [currentArray objectAtIndex:row];
	if ([[tableColumn identifier] isEqualToString:@"roman"]) {
		return roman;
	}
	else {
		return [currentDict objectForKey:roman];
	}
}

- (void)tableView:(NSTableView *)tv setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row {
	if (ignoreEdit) return;
	
	NSString *roman = [currentArray objectAtIndex:row];
	NSString *tex = [currentDict objectForKey:roman];
	
	if ([[tableColumn identifier] isEqualToString:@"roman"]) {
		if (!validRoman || ![object isEqualToString:roman]) {
			if ([romanSet containsObject:object]) {
                NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Duplicate Unicode Character", @"Message in alert dialog when trying to add duplicate character for TeX conversion")
                                                 defaultButton:NSLocalizedString(@"OK", @"Button title")
                                               alternateButton:nil
                                                   otherButton:nil
                                     informativeTextWithFormat:NSLocalizedString(@"The character %@ you entered already has a TeX equivalent, possibly defined internally by BibDesk.", @"Informative text in alert dialog"), object];
                [alert beginSheetModalForWindow:[self window] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
				
				[tableView reloadData];
			} else {
				[currentArray replaceObjectAtIndex:row withObject:object];
				[currentDict setObject:tex forKey:object];
				[currentDict removeObjectForKey:roman];
				[romanSet removeObject:roman];
				[romanSet addObject:object];
				
				validRoman = YES;
				
				[self setDocumentEdited:YES];
				[self updateButtons];
			}
		}
	}
	else {
		if (!validTex || ![object isEqualToString:tex]) {
			if ([self listType] == 2 && [texSet containsObject:object]) {
                NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Duplicate TeX Conversion", @"Message in alert dialog when entering duplicate TeX conversion")
                                                 defaultButton:NSLocalizedString(@"OK", @"Button title")
                                               alternateButton:nil
                                                   otherButton:nil
                                     informativeTextWithFormat:NSLocalizedString(@"The TeX conversion %@ you entered already has a Unicode character, possibly defined internally by BibDesk.", @"Informative text in alert dialog"), object];
                [alert beginSheetModalForWindow:[self window] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
				
				[tableView reloadData];
			} else {
				[currentDict setObject:object forKey:roman];
				if ([self listType] == 2) {
					[texSet removeObject:tex];
					[texSet addObject:object];
				}
				
				validTex = YES;
				
				[self setDocumentEdited:YES];
				[self updateButtons];
			}
		}
	}
}

#pragma mark NSTableView delegate methods

- (BOOL)selectionShouldChangeInTableView:(NSTableView *)tv {
	if (!validRoman || !validTex) { // we force selection of an invalid row
		return NO;
	}
	return YES;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
	[self updateButtons];
}

- (void)control:(NSControl *)control didFailToValidatePartialString:(NSString *)string errorDescription:(NSString *)error{
    if(error != nil){
        NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Invalid Entry", @"Message in alert dialog when entering invalid entry")
                                         defaultButton:nil
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:@"%@", error];
        [alert beginSheetModalForWindow:[self window] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
    }
}

@end


@implementation BDSKRomanCharacterFormatter

- (NSString *)stringForObjectValue:(id)obj{
    return obj;
}

- (NSAttributedString *)attributedStringForObjectValue:(id)obj withDefaultAttributes:(NSDictionary *)attrs{
    // NSLog(@"attributed string for obj");
    return [[[NSAttributedString alloc] initWithString:[self stringForObjectValue:obj]] autorelease];
}

- (BOOL)getObjectValue:(id *)obj forString:(NSString *)string errorDescription:(NSString **)error{
    *obj = string;
    return YES;
}

- (BOOL)isPartialStringValid:(NSString **)partialStringPtr proposedSelectedRange:(NSRangePointer)proposedSelRangePtr originalString:(NSString *)origString originalSelectedRange:(NSRange)origSelRange errorDescription:(NSString **)error{
	NSString *partialString = *partialStringPtr;
	
    partialString = [partialString precomposedStringWithCanonicalMapping];
    if([partialString length] > 1){
        if([partialString length] > 1)
            if(error) *error = NSLocalizedString(@"Only single characters are allowed", @"Error description");
        else
            *partialStringPtr = partialString;
        return NO;
    }
    return YES;
}

@end


@implementation BDSKTeXFormatter

- (NSString *)stringForObjectValue:(id)obj{
    return obj;
}

- (NSAttributedString *)attributedStringForObjectValue:(id)obj withDefaultAttributes:(NSDictionary *)attrs{
    // NSLog(@"attributed string for obj");
    return [[[NSAttributedString alloc] initWithString:[self stringForObjectValue:obj]] autorelease];
}

- (BOOL)getObjectValue:(id *)obj forString:(NSString *)string errorDescription:(NSString **)error{
    *obj = string;
    return YES;
}

- (BOOL)isPartialStringValid:(NSString **)partialStringPtr proposedSelectedRange:(NSRangePointer)proposedSelRangePtr originalString:(NSString *)origString originalSelectedRange:(NSRange)origSelRange errorDescription:(NSString **)error{
	NSString *partialString = *partialStringPtr;
	
	if ([partialString length] >= 3 &&
		[[partialString substringToIndex:2] isEqualToString:@"{\\"] &&
		[partialString characterAtIndex:[partialString length] - 1] == '}') {
		
		return YES;
	}
	
	if ([origString length] >= 3 &&
		[[origString substringToIndex:2] isEqualToString:@"{\\"] &&
		[origString characterAtIndex:[origString length] - 1] == '}') {
		
		*partialStringPtr = [[origString copy] autorelease]; // don't know why I need to do this, seems a bug
	} else {
		*partialStringPtr = @"{\\}";
	}
	
	*proposedSelRangePtr = NSMakeRange(2, [*partialStringPtr length] - 3);
	return NO;
}

@end
