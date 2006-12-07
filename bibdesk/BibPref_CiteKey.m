//
//  BibItem_CiteKey.m
//  
//
//  Created by Christiaan Hofman on 11/4/04.
/*
 This software is Copyright (c) 2004,2005
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

#import "BibPref_CiteKey.h"
#import "NSImage+Toolbox.h"
#import <Carbon/Carbon.h>

#define MAX_PREVIEW_WIDTH	475.0

@implementation BibPref_CiteKey

- (void)awakeFromNib{
    [super awakeFromNib];
}

- (void)dealloc{
    [super dealloc];
}

- (void)updateUI{
    NSString *citeKeyFormat = [defaults stringForKey:BDSKCiteKeyFormatKey];
    int citeKeyPresetChoice = [defaults integerForKey:BDSKCiteKeyFormatPresetKey];
	BOOL custom = (citeKeyPresetChoice == 0);
	NSString *error;
	
	// update the UI elements
    [citeKeyAutogenerateCheckButton setState:[defaults boolForKey:BDSKCiteKeyAutogenerateKey] ? NSOnState : NSOffState];
    [citeKeyLowercaseCheckButton setState:[defaults boolForKey:BDSKCiteKeyLowercaseKey] ? NSOnState : NSOffState];
	if ([[BDSKFormatParser sharedParser] validateFormat:&citeKeyFormat forField:BDSKCiteKeyString inFileType:BDSKBibtexString error:&error]) {
		[self setCiteKeyFormatInvalidWarning:NO message:nil];
		
		// use a BibItem with some data to build the preview cite key
		BibItem *tmpBI = [[BibItem alloc] init];
		[tmpBI setField:BDSKTitleString toValue:@"BibDesk, a great application to manage your bibliographies"];
		[tmpBI setField:BDSKAuthorString toValue:@"McCracken, M. and Maxwell, A. and Howison, J. and Routley, M. and Spiegel, S.  and Porst, S. S. and Hofman, C. M."];
		[tmpBI setField:BDSKYearString toValue:@"2004"];
		[tmpBI setField:BDSKMonthString toValue:@"11"];
		[tmpBI setField:BDSKJournalString toValue:@"SourceForge"];
		[tmpBI setField:BDSKVolumeString toValue:@"1"];
		[tmpBI setField:BDSKPagesString toValue:@"96"];
		[tmpBI setField:BDSKKeywordsString toValue:@"Keyword1,Keyword2"];
		[citeKeyLine setStringValue:[tmpBI suggestedCiteKey]];
		[citeKeyLine sizeToFit];
		NSRect frame = [citeKeyLine frame];
		if (frame.size.width > MAX_PREVIEW_WIDTH) {
			frame.size.width = MAX_PREVIEW_WIDTH;
			[citeKeyLine setFrame:frame];
		}
		[controlBox setNeedsDisplay:YES];
		[tmpBI release];
	} else {
		[self setCiteKeyFormatInvalidWarning:YES message:error];
		[citeKeyLine setStringValue:NSLocalizedString(@"Invalid Format", @"Cite key preview for invalid format")];
	}
	[formatPresetPopUp selectItemAtIndex:[formatPresetPopUp indexOfItemWithTag:citeKeyPresetChoice]];
	[formatField setStringValue:citeKeyFormat];
	[formatField setEnabled:custom];
	if([formatRepositoryPopUp respondsToSelector:@selector(setHidden:)])
	    [formatRepositoryPopUp setHidden:!custom];
	[formatRepositoryPopUp setEnabled:custom];
}

- (void)resignCurrentPreferenceClient{
	NSString *formatString = [formatField stringValue];
	NSString *error;
	NSString *alternateButton = nil;
	int rv;
	
	if (![[BDSKFormatParser sharedParser] validateFormat:&formatString forField:BDSKCiteKeyString inFileType:BDSKBibtexString error:&error]) {
		formatString = [defaults stringForKey:BDSKCiteKeyFormatKey];
		if ([[BDSKFormatParser sharedParser] validateFormat:&formatString forField:BDSKCiteKeyString inFileType:BDSKBibtexString error:NULL]) {
			// The currently set cite-key format is valid, so we can keep it 
			alternateButton = NSLocalizedString(@"Revert to Last", @"Revert to Last Valid Cite Key Format");
		}
		rv = NSRunCriticalAlertPanel(NSLocalizedString(@"Invalid Cite Key Format",@""), 
									 @"%@",
									 NSLocalizedString(@"Revert to Default", @"Revert to Default Cite Key Format"), 
									 alternateButton, 
									 nil,
									 error, nil);
		if (rv == NSAlertDefaultReturn){
			formatString = [[[OFPreferenceWrapper sharedPreferenceWrapper] preferenceForKey:BDSKCiteKeyFormatKey] defaultObjectValue];
			[[OFPreferenceWrapper sharedPreferenceWrapper] setObject:formatString forKey:BDSKCiteKeyFormatKey];
			[[NSApp delegate] setRequiredFieldsForCiteKey: [[BDSKFormatParser sharedParser] requiredFieldsForFormat:formatString]];
		}
	}
}

- (IBAction)formatHelp:(id)sender{
	// Panther only
	//[[NSHelpManager sharedHelpManager] openHelpAnchor:@"Autogeneration-Format-Syntax" inBook:@"BibDesk Help"];
	// ..or we need Carbon/AppleHelp.h
	OSErr err = AHLookupAnchor((CFStringRef)@"BibDesk Help",(CFStringRef)@"Autogeneration-Format-Syntax");
    if (err == kAHInternalErr || err == kAHInternalErr){
        NSLog(@"Help Book: error looking up anchor \"Autogeneration-Format-Syntax\"");
    }
}

- (IBAction)changeCiteKeyAutogenerate:(id)sender{
    [defaults setBool:([sender state] == NSOnState) forKey:BDSKCiteKeyAutogenerateKey];
	[self updateUI];
}

- (IBAction)changeCiteKeyLowercase:(id)sender{
    [defaults setBool:([sender state] == NSOnState) forKey:BDSKCiteKeyLowercaseKey];
	[self updateUI];
}

- (IBAction)citeKeyFormatAdd:(id)sender{
	NSArray *specifierStrings = [NSArray arrayWithObjects:@"", @"%a00", @"%A0", @"%t0", @"%T0", @"%Y", @"%y", @"%m", @"%k0", @"%f{}0", @"%c{}", @"%r2", @"%R2", @"%d2", @"%u0", @"%U0", @"%n0", @"%0", nil];
	NSString *newSpecifier = [specifierStrings objectAtIndex:[formatRepositoryPopUp indexOfSelectedItem]];
    NSText *fieldEditor = [formatField currentEditor];
	NSRange selRange;
	
	if (!newSpecifier || [newSpecifier isEqualToString:@""])
		return;
	
    if (fieldEditor) {
		selRange = NSMakeRange([fieldEditor selectedRange].location + 2, [newSpecifier length] - 2);
		[fieldEditor insertText:newSpecifier];
	} else {
		NSString *formatString = [formatField stringValue];
		selRange = NSMakeRange([formatString length] + 2, [newSpecifier length] - 2);
		[formatField setStringValue:[formatString stringByAppendingString:newSpecifier]];
	}
	
	// this handles the new defaults and the UI update
	[self citeKeyFormatChanged:sender];
	
	// select the 'arbitrary' numbers
	if ([newSpecifier isEqualToString:@"%0"]) {
		selRange.location -= 1;
		selRange.length = 1;
	}
	else if ([newSpecifier isEqualToString:@"%f{}0"] || [newSpecifier isEqualToString:@"%c{}"]) {
        selRange.location += 1;
		selRange.length = 0;
	}
	[formatField selectText:self];
	[[formatField currentEditor] setSelectedRange:selRange];
}

- (IBAction)citeKeyFormatChanged:(id)sender{
	int presetChoice = 0;
	NSString *formatString;
	
	if (sender == formatPresetPopUp) {
		presetChoice = [[formatPresetPopUp selectedItem] tag];
		if (presetChoice == [defaults integerForKey:BDSKCiteKeyFormatPresetKey]) 
			return; // nothing changed
		[defaults setInteger:presetChoice forKey:BDSKCiteKeyFormatPresetKey];
		switch (presetChoice) {
			case 1:
				formatString = @"%a1:%Y%r2";
				break;
			case 2:
				formatString = @"%a1:%Y%u0";
				break;
			case 3:
				formatString = @"%a33%y%m";
				break;
			case 4:
				formatString = @"%a1%Y%t15";
				break;
			default:
				formatString = [formatField stringValue];
		}
		// this one is always valid
		[defaults setObject:formatString forKey:BDSKCiteKeyFormatKey];
	}
	else { //changed the text field or added from the repository
		NSString *error;
		formatString = [formatField stringValue];
		//if ([formatString isEqualToString:[defaults stringForKey:BDSKCiteKeyFormatKey]]) return; // nothing changed
		if ([[BDSKFormatParser sharedParser] validateFormat:&formatString forField:BDSKCiteKeyString inFileType:BDSKBibtexString error:&error]) {
			[defaults setObject:formatString forKey:BDSKCiteKeyFormatKey];
		}
		else {
			[self setCiteKeyFormatInvalidWarning:YES message:error];
			return;
		}
	}
	[[NSApp delegate] setRequiredFieldsForCiteKey: [[BDSKFormatParser sharedParser] requiredFieldsForFormat:formatString]];
	[self updateUI];
}

#pragma mark Invalid format warning stuff

- (IBAction)showCiteKeyFormatWarning:(id)sender{
	NSString *msg = [sender toolTip];
	int rv;
	
	if (msg == nil || [msg isEqualToString:@""]) {
		msg = NSLocalizedString(@"The format string you entered contains invalid format specifiers.",@"");
	}
	rv = NSRunCriticalAlertPanel(NSLocalizedString(@"",@""), 
								 @"%@",
								 NSLocalizedString(@"OK",@"OK"), nil, nil, 
								 msg, nil);
}

- (void)setCiteKeyFormatInvalidWarning:(BOOL)set message:message{
	if(set){
		[formatWarningButton setImage:[NSImage cautionIconImage]];
		[formatWarningButton setToolTip:message];
	}else{
		[formatWarningButton setImage:nil];
		[formatWarningButton setToolTip:NSLocalizedString(@"",@"")]; // @@ this should be nil?
	}
	[formatWarningButton setEnabled:set];
	[formatField setTextColor:(set ? [NSColor redColor] : [NSColor blackColor])]; // overdone?
}

@end
