//
//  BibItem_CiteKey.m
//  
//
//  Created by Christiaan Hofman on 11/4/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "BibPref_CiteKey.h"
#import <Carbon/Carbon.h>


@implementation BibPref_CiteKey

- (void)awakeFromNib{
    [super awakeFromNib];
	
	[self setupCautionIcon];
}

- (void)dealloc{
	[cautionIconImage release]; 
    [super dealloc];
}

- (void)updateUI{
    NSString *citeKeyFormat = [defaults stringForKey:BDSKCiteKeyFormatKey];
    int citeKeyPresetChoice = [defaults integerForKey:BDSKCiteKeyFormatPresetKey];
	BOOL custom = (citeKeyPresetChoice == 0);
	
	// use a BibItem with some data to build the preview cite key
	BibItem *tmpBI = [[BibItem alloc] init];
	[tmpBI setField:@"Title" toValue:@"Bibdesk, a great application to manage your bibliographies"];
	[tmpBI setField:@"Author" toValue:@"McCracken, M. and Maxwell, A. and Howison, J. and Routley, M. and Spiegel, S.  and Porst, S. S. and Hofman, C. M."];
	[tmpBI setField:@"Year" toValue:@"2004"];
	[tmpBI setField:@"Month" toValue:@"11"];
	[tmpBI setField:@"Journal" toValue:@"SourceForge"];
	[tmpBI setField:@"Volume" toValue:@"1"];
	[tmpBI setField:@"Pages" toValue:@"96"];
	
	// update the UI elements
    [citeKeyAutogenerateCheckButton setState:[defaults integerForKey:BDSKCiteKeyAutogenerateKey]];
	[self setCiteKeyFormatInvalidWarning:NO message:NSLocalizedString(@"The cite key format is invalid.",@"")]; // the format in defaults is always valid, right?
	[formatPresetPopUp selectItemAtIndex:[formatPresetPopUp indexOfItemWithTag:citeKeyPresetChoice]];
	[formatField setStringValue:citeKeyFormat];
	[citeKeyLine setStringValue:[tmpBI suggestedCiteKey]];
	[formatField setEnabled:custom]; // or hidden?
        if([formatRepositoryPopUp respondsToSelector:@selector(setHidden:)])
	    [formatRepositoryPopUp setHidden:!custom];
	[tmpBI release];
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

- (IBAction)citeKeyFormatAdd:(id)sender{
	NSString *formatString = [formatField stringValue];
	NSArray *specifierStrings = [NSArray arrayWithObjects:@"", @"%a00", @"%A0", @"%t0", @"%T0", @"%Y", @"%y", @"%m", @"%k0", @"%f{}0", @"%c{}", @"%r2", @"%R2", @"%d2", @"%u0", @"%U0", @"%n0", @"%0", nil];
	NSString *newSpecifier = [specifierStrings objectAtIndex:[formatRepositoryPopUp indexOfSelectedItem]];
	NSRange selRange = NSMakeRange([formatString length] + 2, [newSpecifier length] - 2);
	
	if (!newSpecifier || [newSpecifier isEqualToString:@""])
		return;
	
	formatString = [formatString stringByAppendingString:newSpecifier];
	[formatField setStringValue:formatString];
	
	// this handles the new defaults and the UI update
	[self citeKeyFormatChanged:sender];
	
	// select the 'arbitrary' numbers
	if ([newSpecifier isEqualToString:@"%0"]) {
		selRange.location -= 1;
		selRange.length = 1;
	}
	else if ([newSpecifier isEqualToString:@"%f{}0"] || [newSpecifier isEqualToString:@"%c{}"]) {
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
		if ([[BDSKConverter sharedConverter] validateFormat:&formatString forField:@"Cite Key" inFileType:@"BibTeX" error:&error]) {
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

- (void)setupCautionIcon{
	IconRef cautionIconRef;
	OSErr err = GetIconRef(kOnSystemDisk,
						   kSystemIconsCreator,
						   kAlertCautionBadgeIcon,
						   &cautionIconRef);
	if(err){
		[NSException raise:@"BDSK No Icon Exception"  
					format:@"Error getting the caution badge icon. To decipher the error number (%d),\n see file:///Developer/Documentation/Carbon/Reference/IconServices/index.html#//apple_ref/doc/uid/TP30000239", err];
	}
	
	int size = 32;
	
	cautionIconImage = [[NSImage alloc] initWithSize:NSMakeSize(size,size)]; 
	CGRect iconCGRect = CGRectMake(0,0,size,size);
	
	[cautionIconImage lockFocus]; 
	
	PlotIconRefInContext((CGContextRef)[[NSGraphicsContext currentContext] 
		graphicsPort],
						 &iconCGRect,
						 kAlignAbsoluteCenter, //kAlignNone,
						 kTransformNone,
						 NULL /*inLabelColor*/,
						 kPlotIconRefNormalFlags,
						 cautionIconRef); 
	
	[cautionIconImage unlockFocus]; 
}

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
		[formatWarningButton setImage:cautionIconImage];
		[formatWarningButton setToolTip:message];
	}else{
		[formatWarningButton setImage:nil];
		[formatWarningButton setToolTip:NSLocalizedString(@"",@"")]; // @@ this should be nil?
	}
	[formatWarningButton setEnabled:set];
	[formatField setTextColor:(set ? [NSColor redColor] : [NSColor blackColor])]; // overdone?
}

@end
