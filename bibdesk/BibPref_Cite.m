// BibPref_Cite.m
// BibDesk
// Created by Michael McCracken, 2002
/*
 This software is Copyright (c) 2002,2003,2004,2005,2006
 Michael O. McCracken. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Michael O. McCracken nor the names of any
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

#import "BibPref_Cite.h"

#define MAX_PREVIEW_WIDTH	465.0

@implementation BibPref_Cite
- (void)awakeFromNib{
    [super awakeFromNib];
    BDSKDragCopyCiteKeyFormatter *formatter = [[BDSKDragCopyCiteKeyFormatter alloc] init];
    [citeStringField setFormatter:formatter];
    [citeStringField setDelegate:self];
    [formatter release];
}


- (void)updateUI{
    NSString *citeString = [defaults stringForKey:BDSKCiteStringKey];
	NSString *startCiteBracket = [defaults stringForKey:BDSKCiteStartBracketKey]; 
	NSString *endCiteBracket = [defaults stringForKey:BDSKCiteEndBracketKey]; 
	BOOL prependTilde = [defaults boolForKey:BDSKCitePrependTildeKey];
	NSString *startCite = [NSString stringWithFormat:@"%@\\%@%@", (prependTilde? @"~" : @""), citeString, startCiteBracket];
	
    [defaultDragCopyPopup selectItemWithTag:[[[defaults arrayForKey:BDSKDragCopyTypesKey] objectAtIndex:0] intValue]];
    [alternateDragCopyPopup selectItemWithTag:[[[defaults arrayForKey:BDSKDragCopyTypesKey] objectAtIndex:1] intValue]];
    [separateCiteCheckButton setState:[defaults boolForKey:BDSKSeparateCiteKey] ? NSOnState : NSOffState];
    [prependTildeCheckButton setState:[defaults boolForKey:BDSKCitePrependTildeKey] ? NSOnState : NSOffState];
    [citeBracketRadio selectCellWithTag:[[defaults objectForKey:BDSKCiteStartBracketKey] isEqualToString:@"{"] ? 0 : 1];
    [citeStringField setStringValue:[NSString stringWithFormat:@"\\%@", citeString]];
    if([separateCiteCheckButton state] == NSOnState){
        [citeBehaviorLine setStringValue:[NSString stringWithFormat:@"%@key1%@%@key2%@", startCite, endCiteBracket, startCite, endCiteBracket]];
	}else{
		[citeBehaviorLine setStringValue:[NSString stringWithFormat:@"%@key1,key2%@", startCite, endCiteBracket]];
	}
	[citeBehaviorLine sizeToFit];
	NSRect frame = [citeBehaviorLine frame];
	if (frame.size.width > MAX_PREVIEW_WIDTH) {
		frame.size.width = MAX_PREVIEW_WIDTH;
		[citeBehaviorLine setFrame:frame];
	}
	[controlBox setNeedsDisplay:YES];
}

- (IBAction)changeDefaultDragCopyFormat:(id)sender{
    NSMutableArray *dragCopyTypes = [[defaults arrayForKey:BDSKDragCopyTypesKey] mutableCopy];
    NSNumber *number = [NSNumber numberWithInt:[[sender selectedItem] tag]];
    [dragCopyTypes replaceObjectAtIndex:0 withObject:number];
    [defaults setObject:dragCopyTypes forKey:BDSKDragCopyTypesKey];
    [dragCopyTypes release];
    [defaults autoSynchronize];
}

- (IBAction)changeAlternateDragCopyFormat:(id)sender{
    NSMutableArray *dragCopyTypes = [[defaults arrayForKey:BDSKDragCopyTypesKey] mutableCopy];
    NSNumber *number = [NSNumber numberWithInt:[[sender selectedItem] tag]];
    [dragCopyTypes replaceObjectAtIndex:1 withObject:number];
    [defaults setObject:dragCopyTypes forKey:BDSKDragCopyTypesKey];
    [dragCopyTypes release];
    [defaults autoSynchronize];
}

- (IBAction)changeSeparateCite:(id)sender{
    [defaults setBool:([sender state] == NSOnState) forKey:BDSKSeparateCiteKey];
	[self valuesHaveChanged];
}

- (IBAction)changePrependTilde:(id)sender{
    [defaults setBool:([sender state] == NSOnState) forKey:BDSKCitePrependTildeKey];
	[self valuesHaveChanged];
}

- (IBAction)citeStringFieldChanged:(id)sender{
    [defaults setObject:[[sender stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\\"]]
                 forKey:BDSKCiteStringKey];
    [self changeSeparateCite:separateCiteCheckButton];
    [defaults autoSynchronize];
}

- (IBAction)setCitationBracketStyle:(id)sender{
	// 1 - tex 2 - context
	int tag = [[sender selectedCell] tag];
	if(tag == 1){
		[defaults setObject:@"{" forKey:BDSKCiteStartBracketKey];
		[defaults setObject:@"}" forKey:BDSKCiteEndBracketKey];
	}else if(tag == 2){
		[defaults setObject:@"[" forKey:BDSKCiteStartBracketKey];
		[defaults setObject:@"]" forKey:BDSKCiteEndBracketKey];
	}
	[self valuesHaveChanged];
}

- (BOOL)control:(NSControl *)control didFailToFormatString:(NSString *)string errorDescription:(NSString *)error{
    if(error != nil)
        NSBeginAlertSheet(NSLocalizedString(@"Invalid Entry", @"Message in alert dialog when entering invalid entry"), nil, nil, nil, [controlBox window], nil, NULL, NULL, NULL, error);
    return NO;
}

@end

#pragma mark -

@implementation BDSKDragCopyCiteKeyFormatter

- (BOOL)getObjectValue:(id *)obj forString:(NSString *)string errorDescription:(NSString **)error{
    if([string containsString:@"~"]){
        // some people apparently can't see the checkbox for adding a tilde (bug #1422451)
        if(error) *error = NSLocalizedString(@"Use the checkbox below to prepend a tilde.", @"Error description");
        return NO;
    } else if([string isEqualToString:@""] || [string characterAtIndex:0] != 0x005C){ // backslash
        if(error) *error = NSLocalizedString(@"The key must begin with a backslash.", @"Error description");
        return NO;
    }
    if(obj) *obj = string;
    return YES;
}

- (NSString *)stringForObjectValue:(id)anObject{
    return anObject;
}

@end
