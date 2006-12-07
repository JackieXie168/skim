//
//  BibPref_AutoFile.m
//  BibDesk
//
//  Created by Michael McCracken on Wed Oct 08 2003.
/*
 This software is Copyright (c) 2003,2004,2005
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

#import "BibPref_AutoFile.h"
#import "NSImage+Toolbox.h"
#import <Carbon/Carbon.h>

#define MAX_PREVIEW_WIDTH	501.0

@implementation BibPref_AutoFile

- (void)updateUI{
    NSString *formatString = [defaults stringForKey:BDSKLocalUrlFormatKey];
    int formatPresetChoice = [defaults integerForKey:BDSKLocalUrlFormatPresetKey];
	BOOL custom = (formatPresetChoice == 0);
    NSString * error;
	
    [filePapersAutomaticallyCheckButton setState:[defaults boolForKey:BDSKFilePapersAutomaticallyKey] ? NSOnState : NSOffState];

    [papersFolderLocationTextField setStringValue:[[defaults objectForKey:BDSKPapersFolderPathKey] stringByAbbreviatingWithTildeInPath]];

    [formatLowercaseCheckButton setState:[defaults boolForKey:BDSKLocalUrlLowercaseKey] ? NSOnState : NSOffState];
    [formatCleanRadio selectCellWithTag:[defaults integerForKey:BDSKLocalUrlCleanOptionKey]];
	
	if ([[BDSKFormatParser sharedParser] validateFormat:&formatString forField:BDSKLocalUrlString inFileType:BDSKBibtexString error:&error]) {
		[self setLocalUrlFormatInvalidWarning:NO message:nil];
		
		// use a BibItem with some data to build the preview local-url
		BibItem *tmpBI = [[BibItem alloc] init];
		[tmpBI setField:BDSKTitleString toValue:@"BibDesk, a great application to manage your bibliographies"];
		[tmpBI setField:BDSKAuthorString toValue:@"McCracken, M. and Maxwell, A. and Howison, J. and Routley, M. and Spiegel, S.  and Porst, S. S. and Hofman, C. M."];
		[tmpBI setField:BDSKYearString toValue:@"2004"];
		[tmpBI setField:BDSKMonthString toValue:@"11"];
		[tmpBI setField:BDSKJournalString toValue:@"SourceForge"];
		[tmpBI setField:BDSKVolumeString toValue:@"1"];
		[tmpBI setField:BDSKPagesString toValue:@"96"];
		[tmpBI setField:BDSKKeywordsString toValue:@"Keyword1,Keyword2"];
		[tmpBI setField:BDSKLocalUrlString toValue:@"Local File Name.pdf"];
		[previewTextField setStringValue:[[[NSURL URLWithString:[tmpBI suggestedLocalUrl]] path] stringByAbbreviatingWithTildeInPath]];
		[previewTextField sizeToFit];
		NSRect frame = [previewTextField frame];
		if (frame.size.width > MAX_PREVIEW_WIDTH) {
			frame.size.width = MAX_PREVIEW_WIDTH;
			[previewTextField setFrame:frame];
		}
		[controlBox setNeedsDisplay:YES];
		[tmpBI release];
	} else {
		[self setLocalUrlFormatInvalidWarning:YES message:error];
		[previewTextField setStringValue:NSLocalizedString(@"Invalid Format", @"Local-url preview for invalid format")];
	}
	[formatPresetPopUp selectItemAtIndex:[formatPresetPopUp indexOfItemWithTag:formatPresetChoice]];
    [formatField setStringValue:formatString];
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
	
	if (![[BDSKFormatParser sharedParser] validateFormat:&formatString forField:BDSKLocalUrlString inFileType:BDSKBibtexString error:&error]) {
		formatString = [defaults stringForKey:BDSKLocalUrlFormatKey];
		if ([[BDSKFormatParser sharedParser] validateFormat:&formatString forField:BDSKLocalUrlString inFileType:BDSKBibtexString error:NULL]) {
			// The currently set local-url format is valid, so we can keep it 
			alternateButton = NSLocalizedString(@"Revert to Last", @"Revert to Last Valid Local-Url Format");
		}
		rv = NSRunCriticalAlertPanel(NSLocalizedString(@"Invalid Local-Url Format",@""), 
									 @"%@",
									 NSLocalizedString(@"Revert to Default", @"Revert to Default Local-Url Format"), 
									 alternateButton, 
									 nil,
									 error, nil);
		if (rv == NSAlertDefaultReturn){
			formatString = [[[OFPreferenceWrapper sharedPreferenceWrapper] preferenceForKey:BDSKLocalUrlFormatKey] defaultObjectValue];
			[[OFPreferenceWrapper sharedPreferenceWrapper] setObject:formatString forKey:BDSKLocalUrlFormatKey];
			[[NSApp delegate] setRequiredFieldsForLocalUrl: [[BDSKFormatParser sharedParser] requiredFieldsForFormat:formatString]];
		}
	}
}

- (IBAction)choosePapersFolderLocationAction:(id)sender{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setCanChooseFiles:NO];
	[openPanel setCanChooseDirectories:YES];
	if([openPanel respondsToSelector:@selector(setCanCreateDirectories:)]){
		[openPanel setCanCreateDirectories:YES];
	}
    [openPanel setPrompt:NSLocalizedString(@"Choose", @"Choose directory")];

	if ([openPanel runModalForTypes:nil] != NSOKButton)
	{
		return;
	}
	NSString *path = [[openPanel filenames] objectAtIndex: 0];
	[papersFolderLocationTextField setStringValue:[path stringByAbbreviatingWithTildeInPath]];
	[defaults setObject:path forKey:BDSKPapersFolderPathKey];
}

- (IBAction)toggleFilePapersAutomaticallyAction:(id)sender{
	[defaults setBool:([filePapersAutomaticallyCheckButton state] == NSOnState)
			   forKey:BDSKFilePapersAutomaticallyKey];
}

#pragma mark Local-Url format stuff

- (IBAction)formatHelp:(id)sender{
	// Panther only
	//[[NSHelpManager sharedHelpManager] openHelpAnchor:@"Autogeneration-Format-Syntax" inBook:@"BibDesk Help"];
	// ..or we need Carbon/AppleHelp.h
	OSStatus err = AHLookupAnchor((CFStringRef)@"BibDesk Help",(CFStringRef)@"Autogeneration-Format-Syntax");
    if (err == kAHInternalErr || err == kAHInternalErr){
        NSLog(@"Help Book: error looking up anchor \"Autogeneration-Format-Syntax\"");
    }
}

- (IBAction)changeLocalUrlLowercase:(id)sender{
    [defaults setBool:([sender state] == NSOnState) forKey:BDSKLocalUrlLowercaseKey];
	[self updateUI];
}

- (IBAction)setFormatCleanOption:(id)sender{
	[defaults setInteger:[[sender selectedCell] tag] forKey:BDSKLocalUrlCleanOptionKey];
}

- (IBAction)localUrlFormatAdd:(id)sender{
	NSArray *specifierStrings = [NSArray arrayWithObjects:@"", @"%a00", @"%A0", @"%t0", @"%T0", @"%Y", @"%y", @"%m", @"%k0", @"%L", @"%l", @"%e", @"%f{}0", @"%c{}", @"%r2", @"%R2", @"%d2", @"%u0", @"%U0", @"%n0", @"%0", @"%%", nil];
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
	[self localUrlFormatChanged:sender];
	
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

- (IBAction)localUrlFormatChanged:(id)sender{
	int presetChoice = 0;
	NSString *formatString;
	
	if (sender == formatPresetPopUp) {
		presetChoice = [[formatPresetPopUp selectedItem] tag];
		if (presetChoice == [defaults integerForKey:BDSKLocalUrlFormatPresetKey]) 
			return; // nothing changed
		[defaults setInteger:presetChoice forKey:BDSKLocalUrlFormatPresetKey];
		switch (presetChoice) {
			case 1:
				formatString = @"%L";
				break;
			case 2:
				formatString = @"%l%n0%e";
				break;
			case 3:
				formatString = @"%a1/%Y%u0.pdf";
				break;
			case 4:
				formatString = @"%a1/%T5.pdf";
				break;
			default:
				formatString = [formatField stringValue];
		}
		// this one is always valid
		[defaults setObject:formatString forKey:BDSKLocalUrlFormatKey];
	}
	else { //changed the text field or added from the repository
		NSString *error;
		formatString = [formatField stringValue];
		//if ([formatString isEqualToString:[defaults stringForKey:BDSKLocalUrlFormatKey]]) return; // nothing changed
		if ([[BDSKFormatParser sharedParser] validateFormat:&formatString forField:BDSKLocalUrlString inFileType:BDSKBibtexString error:&error]) {
			[defaults setObject:formatString forKey:BDSKLocalUrlFormatKey];
		}
		else {
			[self setLocalUrlFormatInvalidWarning:YES message:error];
			return;
		}
	}
	[[NSApp delegate] setRequiredFieldsForLocalUrl: [[BDSKFormatParser sharedParser] requiredFieldsForFormat:formatString]];
	[self updateUI];
}

#pragma mark Invalid format warning stuff

- (IBAction)showLocalUrlFormatWarning:(id)sender{
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

- (void)setLocalUrlFormatInvalidWarning:(BOOL)set message:message{
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
