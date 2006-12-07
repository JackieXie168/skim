//
//  BibPref_InputManager.m
//  Bibdesk
//
//  Created by Adam Maxwell on Fri Aug 27 2004.
//  Copyright (c) 2004 Adam R. Maxwell. All rights reserved.
//


#import "BibPref_InputManager.h"

NSString *BDSKInputManagerID = @"net.sourceforge.bibdesk.inputmanager";

@implementation BibPref_InputManager

- (void)awakeFromNib{
    [super awakeFromNib];
    applicationSupportPath = [[NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Application Support/BibDeskInputManager"] retain];
    inputManagerPath = [[NSHomeDirectory() stringByAppendingPathComponent:@"/Library/InputManagers/BibDeskInputManager"] retain];
    if(![[NSFileManager defaultManager] fileExistsAtPath:[applicationSupportPath stringByAppendingPathComponent:@"EnabledApplications.plist"]]){
	appListArray = [[NSMutableArray arrayWithObjects:[NSMutableDictionary dictionaryWithObject:[@"/Applications/TextEdit.app" stringByStandardizingPath] forKey:@"Path"], 
							 [NSMutableDictionary dictionaryWithObject:[@"/Developer/Applications/Xcode.app" stringByStandardizingPath] forKey:@"Path"], nil] retain];
	[[NSFileManager defaultManager] createDirectoryAtPath:applicationSupportPath attributes:nil];
    } else {
	appListArray = [[NSArray arrayWithContentsOfFile:[applicationSupportPath stringByAppendingPathComponent:@"EnabledApplications.plist"]] mutableCopy];
    }
    [[appList tableColumnWithIdentifier:@"AppList"] setDataCell:[[[NSBrowserCell alloc] init] autorelease]];
}

- (void)dealloc{
    [applicationSupportPath release];
    [inputManagerPath release];
    [appListArray release];
    [super dealloc];
}

- (void)updateUI{
    if([[NSFileManager defaultManager] fileExistsAtPath:inputManagerPath]){
	[enableButton setTitle:NSLocalizedString(@"Reinstall",@"Reinstall input manager")];
	[enableButton sizeToFit];
    }    
    [self setBundleID];
    [appList reloadData];
}

- (NSString *)bundleIDForPath:(NSString *)path{
    NSBundle *bundle = [NSBundle bundleWithPath:path];
    
    return [[bundle infoDictionary] objectForKey:@"CFBundleIdentifier"];
}

- (void)setBundleID{
    NSEnumerator *e = [appListArray objectEnumerator];
    NSMutableDictionary *dict;
    
    while(dict = [e nextObject]){
	[dict setObject:[self bundleIDForPath:[dict objectForKey:@"Path"]] forKey:@"BundleID"];
    }

    [self cacheAppList];

}

- (int)numberOfRowsInTableView:(NSTableView *)tableView{
    return [appListArray count];
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex{

    [aCell setStringValue:[[[[appListArray objectAtIndex:rowIndex] objectForKey:@"Path"] lastPathComponent] stringByDeletingPathExtension]];

    NSImage *image = [[NSWorkspace sharedWorkspace] iconForFile:[[appListArray objectAtIndex:rowIndex] objectForKey:@"Path"]];

    [image setSize:NSMakeSize(16, 16)];
    [aCell setImage:image];
    [aCell setLeaf:YES];
}

- (IBAction)enableAutocompletion:(id)sender{
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL err = NO;
    
    if(![fm fileExistsAtPath:[NSHomeDirectory() stringByAppendingPathComponent:@"/Library/InputManagers"]]){
	if(![fm createDirectoryAtPath:[NSHomeDirectory() stringByAppendingPathComponent:@"/Library/InputManagers"] attributes:nil]){
	    NSLog(@"unable to create the InputManagers folder in home directory");
	    err = YES;
	}
    }
    
    if([fm fileExistsAtPath:inputManagerPath]){
	if([fm isDeletableFileAtPath:inputManagerPath]){
	    if(![fm removeFileAtPath:inputManagerPath handler:nil]){
		NSLog(@"error occurred while removing file");
		err = YES;
	    }
	} else {
	    err = YES;
	    NSLog(@"unable to remove file, check permissions");
	}
    }
	
    if(!err){
	[fm copyPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"BibDeskInputManager"]
	      toPath:inputManagerPath
	     handler:nil];
    } else {
	NSAlert *anAlert = [NSAlert alertWithMessageText:@"Error!"
					   defaultButton:nil
					 alternateButton:nil
					     otherButton:nil
			       informativeTextWithFormat:@"Unable to remove file at %@, please check file or directory permissions.", inputManagerPath];
	[anAlert beginSheetModalForWindow:[controlBox window]
			    modalDelegate:nil
			   didEndSelector:nil
			      contextInfo:nil];    
    }
    [self updateUI]; // change button to "Reinstall"
    
}

- (IBAction)addApplication:(id)sender{
    NSOpenPanel *op = [NSOpenPanel openPanel];
    [op setCanChooseDirectories:NO];
    [op setAllowsMultipleSelection:NO];
    [op beginSheetForDirectory:nil
			  file:nil
			 types:[NSArray arrayWithObject:@"app"]
		modalForWindow:[controlBox window]
		 modalDelegate:self
		didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)
		   contextInfo:nil];
}

- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo{
    if(returnCode == NSOKButton){
	
	// check to see if it's a Cocoa application (returns no for BBEdit Lite and MS Word, but yes for Carbon Emacs and Aqua LyX, so it's not foolproof)
	NSString *fileType = nil;
	[[NSWorkspace sharedWorkspace] getInfoForFile:[[sheet filenames] objectAtIndex:0]
					  application:nil
						 type:&fileType];
	if(![fileType isEqualToString:NSApplicationFileType]){
	    [sheet orderOut:nil];
	    NSAlert *anAlert = [NSAlert alertWithMessageText:@"Error!"
					       defaultButton:nil
					     alternateButton:nil
						 otherButton:nil
				   informativeTextWithFormat:@"%@ is not a Cocoa application.", [[sheet filenames] objectAtIndex:0]];
	    [anAlert beginSheetModalForWindow:[controlBox window]
				modalDelegate:nil
			       didEndSelector:nil
				  contextInfo:nil];
	    return;
	}
	
	// LaTeX Equation Editor is Cocoa, but doesn't have a CFBundleIdentifier!  Perhaps there are others...
	if([self bundleIDForPath:[[sheet filenames] objectAtIndex:0]] == nil){
	    [sheet orderOut:nil];
	    NSAlert *anAlert = [NSAlert alertWithMessageText:@"No Bundle Identifier!"
					       defaultButton:nil
					     alternateButton:nil
						 otherButton:nil
				   informativeTextWithFormat:@"The selected application does not have a bundle identifier.  Please inform the author of %@.", [[sheet filenames] objectAtIndex:0]];
	    [anAlert beginSheetModalForWindow:[controlBox window]
				modalDelegate:nil
			       didEndSelector:nil
				  contextInfo:nil];
	    return;
	} else {
	    [appListArray addObject:[NSMutableDictionary dictionaryWithObject:[[sheet filenames] objectAtIndex:0] forKey:@"Path"]];
	    [self updateUI];
	}
    } else {
	if(returnCode == NSCancelButton){
	    // do nothing
	}
    }
}

- (void)cacheAppList{
    if(![[[appListArray copy] autorelease] writeToFile:[applicationSupportPath stringByAppendingPathComponent:@"EnabledApplications.plist"] atomically:YES]){
	NSAlert *anAlert = [NSAlert alertWithMessageText:@"Error!"
					   defaultButton:nil
					 alternateButton:nil
					     otherButton:nil
			       informativeTextWithFormat:@"Unable to write file at %@, please check file or directory permissions.", [applicationSupportPath stringByAppendingPathComponent:@"EnabledApplications.plist"]];
	[anAlert beginSheetModalForWindow:[controlBox window]
			    modalDelegate:nil
			   didEndSelector:nil
			      contextInfo:nil];
    }
}

- (IBAction)removeApplication:(id)sender{
    [appListArray removeObjectAtIndex:[appList selectedRow]];
    [self updateUI];
}

@end
