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
    NSFileManager *fm = [NSFileManager defaultManager];
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    
    NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    applicationSupportPath = [[libraryPath stringByAppendingPathComponent:@"/Application Support/BibDeskInputManager"] retain];
    inputManagerPath = [[libraryPath stringByAppendingPathComponent:@"/InputManagers/BibDeskInputManager"] retain];
    
    // Try to find TextEdit.app so the table isn't empty
    NSString *textEditPath = nil;
    if([ws respondsToSelector:@selector(absolutePathForAppBundleWithIdentifier:)]){
	    textEditPath = [ws absolutePathForAppBundleWithIdentifier:@"com.apple.textedit"];
    } else {
	    [enableButton setEnabled:NO];
        NSBeginAlertSheet(NSLocalizedString(@"Error!", @"Error!"),
                          nil, nil, nil, [controlBox window], nil, nil, nil, nil,
                          NSLocalizedString(@"You appear to be using a system version earlier than 10.3.  Autocompletion requires Mac OS X 10.3 or greater.",
                                            @"You appear to be using a system version earlier than 10.3.  Autocompletion requires Mac OS X 10.3 or greater.") );
    }
	
    if(![fm fileExistsAtPath:[applicationSupportPath stringByAppendingPathComponent:@"EnabledApplications.plist"]]){
	if([fm fileExistsAtPath:textEditPath]){
	    appListArray = [[NSMutableArray arrayWithObjects:[NSMutableDictionary dictionaryWithObject:textEditPath forKey:@"Path"], nil] retain];
	} else {
	    appListArray = [[NSMutableArray array] retain]; // create an empty one if we didn't find TextEdit.app
	}
	[fm createDirectoryAtPath:applicationSupportPath attributes:nil];
    } else { // if we found the plist, use that instead
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
//    NSLog(@"-[%@ %@] 0x%x", [self class], NSStringFromSelector(_cmd), self);
    if([[NSFileManager defaultManager] fileExistsAtPath:inputManagerPath]){
	[enableButton setTitle:NSLocalizedString(@"Reinstall",@"Reinstall input manager")];
	[enableButton sizeToFit];
    }    
    [self setBundleID];
    [appList reloadData];
}

- (NSString *)bundleIDForPath:(NSString *)path{
//    NSLog(@"-[%@ %@] 0x%x", [self class], NSStringFromSelector(_cmd), self);
    NSBundle *bundle = [NSBundle bundleWithPath:path];
    
    return [[bundle infoDictionary] objectForKey:@"CFBundleIdentifier"];
}

- (void)setBundleID{
//    NSLog(@"-[%@ %@] 0x%x", [self class], NSStringFromSelector(_cmd), self);
    NSEnumerator *e = [appListArray objectEnumerator];
    NSMutableDictionary *dict;
    BOOL err = NO;
    
    while(dict = [e nextObject]){
	if([[NSFileManager defaultManager] fileExistsAtPath:[dict objectForKey:@"Path"]]){
	    [dict setObject:[self bundleIDForPath:[dict objectForKey:@"Path"]] forKey:@"BundleID"];
	} else {
	    err = YES;
	    [dict setObject:[NSNull null] forKey:@"BundleID"];
	}
    }

    if(!err){
	[self cacheAppList];
    } else {
	// show an alert if an app wasn't found, otherwise we get a writeToFile: failure in cacheAppList
	NSAlert *anAlert = [NSAlert alertWithMessageText:@"Error!"
					   defaultButton:nil
					 alternateButton:nil
					     otherButton:nil
			       informativeTextWithFormat:@"The application(s) with a blank icon cannot be found and must be removed from the list."];
	[anAlert beginSheetModalForWindow:[controlBox window]
			    modalDelegate:nil
			   didEndSelector:nil
			      contextInfo:nil];
    }
	

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
    NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    if(![fm fileExistsAtPath:[libraryPath stringByAppendingPathComponent:@"/InputManagers"]]){
	if(![fm createDirectoryAtPath:[libraryPath stringByAppendingPathComponent:@"/InputManagers"] attributes:nil]){
	    NSLog(@"unable to create the InputManagers folder at path @%",[libraryPath stringByAppendingPathComponent:@"/InputManagers"]);
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
			       informativeTextWithFormat:@"Unable to install plugin at %@, please check file or directory permissions.", inputManagerPath];
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
