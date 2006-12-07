//
//  BibItem_CiteKey.m
//  
//
//  Created by Christiaan Hofman on 11/4/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "BibPref_CiteKey.h"
#import "NSImage+Toolbox.h"
#import <Carbon/Carbon.h>


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
    [citeKeyAutogenerateCheckButton setState:[defaults integerForKey:BDSKCiteKeyAutogenerateKey]];
    [citeKeyLowercaseCheckButton setState:[defaults integerForKey:BDSKCiteKeyLowercaseKey]];
	if ([[BDSKConverter sharedConverter] validateFormat:&citeKeyFormat forField:BDSKCiteKeyString inFileType:BDSKBibtexString error:&error]) {
		[self setCiteKeyFormatInvalidWarning:NO message:nil];
		
		// use a BibItem with some data to build the preview cite key
		BibItem *tmpBI = [[BibItem alloc] init];
		[tmpBI setField:BDSKTitleString toValue:@"Bibdesk, a great application to manage your bibliographies"];
		[tmpBI setField:BDSKAuthorString toValue:@"McCracken, M. and Maxwell, A. and Howison, J. and Routley, M. and Spiegel, S.  and Porst, S. S. and Hofman, C. M."];
		[tmpBI setField:BDSKYearString toValue:@"2004"];
		[tmpBI setField:BDSKMonthString toValue:@"11"];
		[tmpBI setField:BDSKJournalString toValue:@"SourceForge"];
		[tmpBI setField:BDSKVolumeString toValue:@"1"];
		[tmpBI setField:BDSKPagesString toValue:@"96"];
		[tmpBI setField:BDSKKeywordsString toValue:@"Keyword1,Keyword2"];
		[citeKeyLine setStringValue:[tmpBI suggestedCiteKey]];
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
	
	if (![[BDSKConverter sharedConverter] validateFormat:&formatString forField:BDSKCiteKeyString inFileType:BDSKBibtexString error:&error]) {
		formatString = [defaults stringForKey:BDSKCiteKeyFormatKey];
		if ([[BDSKConverter sharedConverter] validateFormat:&formatString forField:BDSKCiteKeyString inFileType:BDSKBibtexString error:NULL]) {
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
			[[NSApp delegate] setRequiredFieldsForCiteKey: [[BDSKConverter sharedConverter] requiredFieldsForFormat:formatString]];
		}
	}
}

- (IBAction)formatHelp:(id)sender{
	// Panther only
	//[[NSHelpManager sharedHelpManager] openHelpAnchor:@"citekeyFormat" inBook:@"BibDesk Help"];
	// ..or we need Carbon/AppleHelp.h
	AHLookupAnchor((CFStringRef)@"BibDesk Help",(CFStringRef)@"format");
}

- (IBAction)changeCiteKeyAutogenerate:(id)sender{
    [defaults setInteger:[sender state] forKey:BDSKCiteKeyAutogenerateKey];
	[self updateUI];
}

- (IBAction)changeCiteKeyLowercase:(id)sender{
    [defaults setInteger:[sender state] forKey:BDSKCiteKeyLowercaseKey];
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
		if ([[BDSKConverter sharedConverter] validateFormat:&formatString forField:BDSKCiteKeyString inFileType:BDSKBibtexString error:&error]) {
			[defaults setObject:formatString forKey:BDSKCiteKeyFormatKey];
		}
		else {
			[self setCiteKeyFormatInvalidWarning:YES message:error];
			return;
		}
	}
	[[NSApp delegate] setRequiredFieldsForCiteKey: [[BDSKConverter sharedConverter] requiredFieldsForFormat:formatString]];
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
