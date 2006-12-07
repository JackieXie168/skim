//
//  BibPref_AutoFile.m
//  Bibdesk
//
//  Created by Michael McCracken on Wed Oct 08 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "BibPref_AutoFile.h"
#import <Carbon/Carbon.h>

@implementation BibPref_AutoFile

- (void)awakeFromNib{
    [super awakeFromNib];
	
	[self setupCautionIcon];
}

- (void)dealloc{
	[cautionIconImage release]; 
    [super dealloc];
}

- (void)updateUI{
    BibItem *tmpBI = [[BibItem alloc] init];
    [tmpBI setField:@"Title" toValue:@"Bibdesk, a great application to manage your bibliographies"];
    [tmpBI setField:@"Author" toValue:@"McCracken, M. and Maxwell, A. and Howison, J. and Routley, M. and Spiegel, S.  and Porst, S. S. and Hofman, C. M."];
    [tmpBI setField:@"Year" toValue:@"2004"];
    [tmpBI setField:@"Month" toValue:@"11"];
    [tmpBI setField:@"Journal" toValue:@"SourceForge"];
    [tmpBI setField:@"Volume" toValue:@"1"];
    [tmpBI setField:@"Pages" toValue:@"96"];
    
    NSString *formatString = [defaults stringForKey:BDSKLocalUrlFormatKey];
	
    [filePapersAutomaticallyCheckButton setState:[defaults integerForKey:BDSKFilePapersAutomaticallyKey]];
    [keepPapersFolderOrganizedCheckButton setState:[defaults integerForKey:BDSKKeepPapersFolderOrganizedKey]];

    [papersFolderLocationTextField setStringValue:[[defaults objectForKey:BDSKPapersFolderPathKey] stringByAbbreviatingWithTildeInPath]];

    [self setLocalUrlFormatInvalidWarning:NO message:NSLocalizedString(@"The local-url format is invalid.",@"")]; // the format in defaults is always valid, right?
    [formatField setStringValue:formatString];
    [previewTextField setStringValue:[[tmpBI suggestedLocalUrl] stringByAbbreviatingWithTildeInPath]];
    [tmpBI release];
}

- (IBAction)choosePapersFolderLocationAction:(id)sender{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setCanChooseFiles:NO];
	[openPanel setCanChooseDirectories:YES];
        if([openPanel respondsToSelector:@selector(setCanCreateDirectories:)]){
            [openPanel setCanCreateDirectories:YES];
        }

	if ([openPanel runModalForTypes:nil] != NSOKButton)
	{
		return;
	}
	NSString *path = [[openPanel filenames] objectAtIndex: 0];
	[papersFolderLocationTextField setStringValue:[path stringByAbbreviatingWithTildeInPath]];
	[defaults setObject:path forKey:BDSKPapersFolderPathKey];
}

- (IBAction)toggleFilePapersAutomaticallyAction:(id)sender{
	[defaults setBool:[filePapersAutomaticallyCheckButton state]
			   forKey:BDSKFilePapersAutomaticallyKey];
}

- (IBAction)toggleKeepPapersFolderOrganizedAction:(id)sender{
	[defaults setBool:[keepPapersFolderOrganizedCheckButton state]
			   forKey:BDSKKeepPapersFolderOrganizedKey];
}

#pragma mark Local-Url format stuff

- (IBAction)formatHelp:(id)sender{
	// Panther only
	//[[NSHelpManager sharedHelpManager] openHelpAnchor:@"citekeyFormat" inBook:@"BibDesk Help"];
	// ..or we need Carbon/AppleHelp.h
	AHLookupAnchor((CFStringRef)@"BibDesk Help",(CFStringRef)@"citekeyFormat"); // name of page should change
}

- (IBAction)localUrlFormatAdd:(id)sender{
	NSString *formatString = [formatField stringValue];
	NSArray *specifierStrings = [NSArray arrayWithObjects:@"", @"%a00", @"%A0", @"%t0", @"%Y", @"%y", @"%m", @"%k0", @"%r2", @"%R2", @"%d2", @"%u0", @"%U0", @"%n0", @"%0", @"%%", @"%{}0", nil];
	NSString *newSpecifier = [specifierStrings objectAtIndex:[formatRepositoryPopUp indexOfSelectedItem]];
	NSRange selRange = NSMakeRange([formatString length] + 2, [newSpecifier length] - 2);
	
	if (!newSpecifier || [newSpecifier isEqualToString:@""])
		return;
	
	formatString = [formatString stringByAppendingString:newSpecifier];
	[formatField setStringValue:formatString];
	
	// this handles the new defaults and the UI update
	[self localUrlFormatChanged:sender];
	
	// select the 'arbitrary' numbers
	if (newSpecifier == @"%0") {
		selRange.location -= 1;
		selRange.length = 1;
	}
	else if (newSpecifier == @"%{}0") {
		selRange.length = 0;
	}
	[formatField selectText:self];
	[[formatField currentEditor] setSelectedRange:selRange];
}

- (IBAction)localUrlFormatChanged:(id)sender{
	NSString *formatString = [formatField stringValue];
	NSString *error;
	
	//if ([formatString isEqualToString:[defaults stringForKey:BDSKLocalUrlFormatKey]]) return; // nothing changed
	if ([[BDSKConverter sharedConverter] validateFormat:&formatString forField:@"Local-Url" inFileType:@"BibTeX" error:&error]) {
		[defaults setObject:formatString forKey:BDSKLocalUrlFormatKey];
	}
	else {
		[self setLocalUrlFormatInvalidWarning:YES message:error];
		return;
	}
	
	[[NSApp delegate] setRequiredFieldsForLocalUrl: [[BDSKConverter sharedConverter] requiredFieldsForFormat:formatString]];
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

- (IBAction)showLocalUrlFormatWarning:(id)sender{
	int rv;
	// do we want to be more informative, i.e. name of offending specifier?
	rv = NSRunCriticalAlertPanel(NSLocalizedString(@"",@""), 
								 NSLocalizedString(@"The format string you entered contains invalid format specifiers.",@""),
								 NSLocalizedString(@"OK",@"OK"), nil, nil, nil);
}

- (void)setLocalUrlFormatInvalidWarning:(BOOL)set message:message{
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
