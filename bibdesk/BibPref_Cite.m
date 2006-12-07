/*
This software is Copyright (c) 2002, Michael O. McCracken
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
-  Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
-  Neither the name of Michael O. McCracken nor the names of any contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "BibPref_Cite.h"

#define MAX_PREVIEW_WIDTH	465.0

@implementation BibPref_Cite
- (void)awakeFromNib{
    [super awakeFromNib];
    BDSKDragCopyCiteKeyFormatter *formatter = [[BDSKDragCopyCiteKeyFormatter alloc] init];
    [citeStringField setFormatter:formatter];
    [formatter release];
}


- (void)updateUI{
    NSString *citeString = [defaults stringForKey:BDSKCiteStringKey];
	NSString *startCiteBracket = [defaults stringForKey:BDSKCiteStartBracketKey]; 
	NSString *endCiteBracket = [defaults stringForKey:BDSKCiteEndBracketKey]; 
	
	if([startCiteBracket isEqualToString:@"{"]){
		
	}

    [dragCopyRadio selectCellWithTag:[defaults integerForKey:BDSKDragCopyKey]];
    [separateCiteCheckButton setState:[defaults boolForKey:BDSKSeparateCiteKey] ? NSOnState : NSOffState];
    [citeStringField setStringValue:[NSString stringWithFormat:@"\\%@", citeString]];
    if([separateCiteCheckButton state] == NSOnState){
        [citeBehaviorLine setStringValue:[NSString stringWithFormat:@"\\%@%@key1%@ \\%@%@key2%@",citeString, startCiteBracket, endCiteBracket,
			citeString, startCiteBracket,endCiteBracket]];
	}else{
		[citeBehaviorLine setStringValue:[NSString stringWithFormat:@"\\%@%@key1, key2%@" ,citeString, startCiteBracket, endCiteBracket]];
	}
	[citeBehaviorLine sizeToFit];
	NSRect frame = [citeBehaviorLine frame];
	if (frame.size.width > MAX_PREVIEW_WIDTH) {
		frame.size.width = MAX_PREVIEW_WIDTH;
		[citeBehaviorLine setFrame:frame];
	}
	[controlBox setNeedsDisplay:YES];
}

- (IBAction)changeCopyBehavior:(id)sender{
    [defaults setInteger:[[sender selectedCell] tag] forKey:BDSKDragCopyKey];
}

- (IBAction)changeSeparateCite:(id)sender{
    [defaults setBool:([sender state] == NSOnState) forKey:BDSKSeparateCiteKey];
	[self updateUI];
}

- (IBAction)citeStringFieldChanged:(id)sender{
    [defaults setObject:[[sender stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\\"]]
                 forKey:BDSKCiteStringKey];
    [self changeSeparateCite:separateCiteCheckButton];
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
	[self updateUI];
}

@end

@implementation BDSKDragCopyCiteKeyFormatter

- (BOOL)isPartialStringValid:(NSString **)partialStringPtr proposedSelectedRange:(NSRangePointer)proposedSelRangePtr originalString:(NSString *)origString originalSelectedRange:(NSRange)origSelRange errorDescription:(NSString **)error{
    if([*partialStringPtr isEqualToString:@""] || [origString characterAtIndex:0] != 0x005C){ // backslash
        *partialStringPtr = [NSString stringWithFormat:@"\\%@", *partialStringPtr];
        proposedSelRangePtr->location = [*partialStringPtr length];
        return NO;
    } else
        return YES;
}

- (BOOL)getObjectValue:(id *)obj forString:(NSString *)string errorDescription:(NSString **)error{
    *obj = string;
    return YES;
}

- (NSString *)stringForObjectValue:(id)anObject{
    if (![anObject isKindOfClass:[NSString class]]) {
        return nil;
    }
    return anObject;
}

@end