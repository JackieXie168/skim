//
//  BibPref_AutoFile.m
//  Bibdesk
//
//  Created by Michael McCracken on Wed Oct 08 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "BibPref_AutoFile.h"


@implementation BibPref_AutoFile

- (void)updateUI{
    [filePapersAutomaticallyCheckButton setState:[defaults integerForKey:BDSKFilePapersAutomaticallyKey]];
	[keepPapersFolderOrganizedCheckButton setState:[defaults integerForKey:BDSKKeepPapersFolderOrganizedKey]];

    [papersFolderLocationTextField setStringValue:[[defaults objectForKey:BDSKPapersFolderPathKey] stringByAbbreviatingWithTildeInPath]];
}

- (IBAction)choosePapersFolderLocationAction:(id)sender{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setCanChooseFiles:NO];
	[openPanel setCanChooseDirectories:YES];

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

@end
