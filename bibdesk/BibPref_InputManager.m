//
//  BibPref_InputManager.m
//  Bibdesk
//
//  Created by Adam Maxwell on Fri Aug 27 2004.
//  Copyright (c) 2004 Adam R. Maxwell. All rights reserved.
//


#import "BibPref_InputManager.h"
#import "BibTypeManager.h"

NSString *BDSKInputManagerID = @"net.sourceforge.bibdesk.inputmanager";
NSString *BDSKInputManagerLoadableApplications = @"Application bundles that we recognize";

@implementation BibPref_InputManager

- (void)awakeFromNib{
    [super awakeFromNib];
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    
    NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    inputManagerPath = [[libraryPath stringByAppendingPathComponent:@"/InputManagers/BibDeskInputManager"] retain];
    
    if(![ws respondsToSelector:@selector(absolutePathForAppBundleWithIdentifier:)]){ // check the OS version
        [enableButton setEnabled:NO];
    }
        
    CFPropertyListRef prefs = CFPreferencesCopyAppValue( (CFStringRef)BDSKInputManagerLoadableApplications,
                                                      (CFStringRef)BDSKInputManagerID );
                                                      
    if(prefs != nil){
        appListArray = [(NSArray *)prefs mutableCopy];
    } else {
        appListArray = [[NSMutableArray array] retain];
        [appListArray addObject:@"com.apple.textedit"];
    }
    	
    [[appList tableColumnWithIdentifier:@"AppList"] setDataCell:[[[NSBrowserCell alloc] init] autorelease]];

    if(![self isInstalledVersionCurrent] && 
       [ws respondsToSelector:@selector(absolutePathForAppBundleWithIdentifier:)] ){ // make sure we're on 10.3, also
        [enableButton setTitle:@"Update"];
        NSAlert *anAlert = [NSAlert alertWithMessageText:@"Update Available!"
                                           defaultButton:NSLocalizedString(@"Update", @"Update")
                                         alternateButton:NSLocalizedString(@"Cancel", @"Cancel the update")
                                             otherButton:nil
                               informativeTextWithFormat:NSLocalizedString(@"You can install a newer version of the autocompletion plugin by clicking the \"Update\" button below.",@"")];
        [anAlert beginSheetModalForWindow:[[OAPreferenceController sharedPreferenceController] window]
                            modalDelegate:self
                           didEndSelector:@selector(updateAlertDidEnd:returnCode:contextInfo:)
                              contextInfo:nil];
    }
    
    if([defaults objectForKey:BDSKBibEditorAutocompletionFields]){
        enabledEditorAutocompletionStrings = [[defaults objectForKey:BDSKBibEditorAutocompletionFields] mutableCopy];
    } else {
        enabledEditorAutocompletionStrings = [[NSMutableArray array] retain];
    }
    [[editorAutocompletionStringsTableView tableColumnWithIdentifier:@"CompList"] setDataCell:[[[NSTextFieldCell alloc] init] autorelease]];
}

- (void)dealloc{
    [inputManagerPath release];
    [appListArray release];
    [enabledEditorAutocompletionStrings release];
    [super dealloc];
}

- (void)restoreDefaultsNoPrompt{
    [super restoreDefaultsNoPrompt];
    // after resetting the preferences, the array is no longer valid, but the table is still using an old copy (needed for add/remove, since we set the whole array in the prefs)
    [enabledEditorAutocompletionStrings release];
    enabledEditorAutocompletionStrings = [[defaults objectForKey:BDSKBibEditorAutocompletionFields] mutableCopy];
    [self updateUI];
}

- (void)updateUI{
    // NSLog(@"-[%@ %@] 0x%x", [self class], NSStringFromSelector(_cmd), self);
    if([[NSFileManager defaultManager] fileExistsAtPath:inputManagerPath]){
	[enableButton setTitle:NSLocalizedString(@"Reinstall",@"Reinstall input manager")];
    }

    CFPreferencesSetAppValue( (CFStringRef)BDSKInputManagerLoadableApplications,
                              appListArray,
                              (CFStringRef)BDSKInputManagerID );
    BOOL success = CFPreferencesAppSynchronize( (CFStringRef)BDSKInputManagerID );
    NSAssert1( success, @"Failed to synchronize preferences for %@", BDSKInputManagerID);

    [appList reloadData];
    [editorAutocompletionStringsTableView reloadData];
}

- (void)updateAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo{
    if(returnCode == 1) // AppKit bug: NSAlertFirstButtonReturn doesn't work
        [self enableAutocompletion:nil];
}

- (NSString *)bundleIDForPath:(NSString *)path{
//    NSLog(@"-[%@ %@] 0x%x", [self class], NSStringFromSelector(_cmd), self);
    NSBundle *bundle = [NSBundle bundleWithPath:path];
    
    return [[bundle infoDictionary] objectForKey:@"CFBundleIdentifier"];
}

// We use a common datasource for both tableviews.  Using objectValueForTableColumn:row: in conjunction with tableView:willDisplayCell:forTableColumn:row:
// causes a crash, so we set up a cell for both types and just use the willDisplayCell method for both (required for the tv that uses an NSBrowserCell).

- (int)numberOfRowsInTableView:(NSTableView *)tableView{
    return (tableView == appList) ? [appListArray count] : [enabledEditorAutocompletionStrings count];
}
    
- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex{
    
    if(aTableView != appList){ // we have two tables, and this isn't the right one
        [aCell setStringValue:[enabledEditorAutocompletionStrings objectAtIndex:rowIndex]];
        return;
    }
    
    NSString *inBundleID = [appListArray objectAtIndex:rowIndex];
    CFURLRef outAppURL = nil;
    NSImage *image = nil;
    int size = 16;
    
    OSStatus err = LSFindApplicationForInfo( kLSUnknownCreator,
                                             (CFStringRef)inBundleID,
                                             NULL,
                                             NULL,
                                             &outAppURL );
    
    // NSAssert1( (!err), @"Couldn't find icon for application %@", inBundleID);
    if(!err){
        NSString *path = [(NSURL *)outAppURL path];
        CFRelease(outAppURL);
        [aCell setStringValue:[[path lastPathComponent] stringByDeletingPathExtension]];

        image = [[NSWorkspace sharedWorkspace] iconForFile:path];
    } else {
        // if LS failed us (my cache was corrupt when I wrote this code, so it's been tested)
        IconRef genericIconRef;
        OSStatus getIconErr = GetIconRef( kOnSystemDisk,
                                          kSystemIconsCreator,
                                          kAlertCautionIcon,
                                          &genericIconRef );
        NSAssert1( (!getIconErr), @"Couldn't get kAlertCautionIcon, error %d.", getIconErr); // now you're really out of luck
        image = [[[NSImage alloc] initWithSize:NSMakeSize(size, size)] autorelease];
        CGRect iconCGRect = CGRectMake(0, 0, size, size);
        [image lockFocus];
        PlotIconRefInContext( (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort], // borrowed from BibEditor code
                              &iconCGRect,
                              kAlignAbsoluteCenter,
                              kTransformNone,
                              NULL,
                              kPlotIconRefNormalFlags,
                              genericIconRef);
        [image unlockFocus];
        [aCell setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Error %d, LaunchServices can't find %@",@""), err, inBundleID]];
    }

    [image setSize:NSMakeSize(size, size)];
    [aCell setImage:image];
    [aCell setLeaf:YES];
}

#pragma mark Citekey autocompletion

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
	NSAlert *anAlert = [NSAlert alertWithMessageText:NSLocalizedString(@"Error!",@"Error!")
					   defaultButton:nil
					 alternateButton:nil
					     otherButton:nil
			       informativeTextWithFormat:NSLocalizedString(@"Unable to install plugin at %@, please check file or directory permissions.",@""), inputManagerPath];
	[anAlert beginSheetModalForWindow:[[OAPreferenceController sharedPreferenceController] window]
			    modalDelegate:nil
			   didEndSelector:nil
			      contextInfo:nil];    
    }
    [self updateUI]; // change button to "Reinstall"
    
}

- (BOOL)isInstalledVersionCurrent{
    NSString *bundlePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"BibDeskInputManager/BibDeskInputManager.bundle"];
    NSString *bundledVersion = [[[NSBundle bundleWithPath:bundlePath] infoDictionary] objectForKey:@"CFBundleVersion"];
    NSString *installedVersion = [[[NSBundle bundleWithPath:[inputManagerPath stringByAppendingPathComponent:@"BibDeskInputManager.bundle"]] infoDictionary] objectForKey:@"CFBundleVersion"];
    // if it's not installed, return YES so the user doesn't get confused.
    return ( (installedVersion == nil) ? YES : [bundledVersion isEqualToString:installedVersion] );
}

- (IBAction)addApplication:(id)sender{
    if(![[NSWorkspace sharedWorkspace] respondsToSelector:@selector(absolutePathForAppBundleWithIdentifier:)]){ // check the OS version
        [sender setEnabled:NO];
        NSBeginAlertSheet(NSLocalizedString(@"Error!", @"Error!"),
                          nil, nil, nil, [[OAPreferenceController sharedPreferenceController] window], nil, nil, nil, nil,
                          NSLocalizedString(@"You appear to be using a system version earlier than 10.3.  Cite-key autocompletion requires Mac OS X 10.3 or greater.",
                                            @"You appear to be using a system version earlier than 10.3.  Cite-key autocompletion requires Mac OS X 10.3 or greater.") );
        return;
    }
    
    NSOpenPanel *op = [NSOpenPanel openPanel];
    [op setCanChooseDirectories:NO];
    [op setAllowsMultipleSelection:NO];
    [op beginSheetForDirectory:nil
			  file:nil
			 types:[NSArray arrayWithObject:@"app"]
		modalForWindow:[[OAPreferenceController sharedPreferenceController] window]
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
	    NSAlert *anAlert = [NSAlert alertWithMessageText:NSLocalizedString(@"Error!",@"Error!")
					       defaultButton:nil
					     alternateButton:nil
						 otherButton:nil
				   informativeTextWithFormat:NSLocalizedString(@"%@ is not a Cocoa application.",@""), [[sheet filenames] objectAtIndex:0]];
	    [anAlert beginSheetModalForWindow:[[OAPreferenceController sharedPreferenceController] window]
				modalDelegate:nil
			       didEndSelector:nil
				  contextInfo:nil];
	    return;
	}
	
	// LaTeX Equation Editor is Cocoa, but doesn't have a CFBundleIdentifier!  Perhaps there are others...
	if([self bundleIDForPath:[[sheet filenames] objectAtIndex:0]] == nil){
	    [sheet orderOut:nil];
	    NSAlert *anAlert = [NSAlert alertWithMessageText:NSLocalizedString(@"No Bundle Identifier!",@"No Bundle Identifier!")
					       defaultButton:nil
					     alternateButton:nil
						 otherButton:nil
				   informativeTextWithFormat:NSLocalizedString(@"The selected application does not have a bundle identifier.  Please inform the author of %@.",@""), [[sheet filenames] objectAtIndex:0]];
	    [anAlert beginSheetModalForWindow:[[OAPreferenceController sharedPreferenceController] window]
				modalDelegate:nil
			       didEndSelector:nil
				  contextInfo:nil];
	    return;
	} else {
	    [appListArray addObject:[self bundleIDForPath:[[sheet filenames] objectAtIndex:0]]];
	    [self updateUI];
	}
    } else {
	if(returnCode == NSCancelButton){
	    // do nothing
	}
    }
}

- (IBAction)removeApplication:(id)sender{
    if([appList selectedRow] != -1)
        [appListArray removeObjectAtIndex:[appList selectedRow]];
    [self updateUI];
}

#pragma mark Methods for BibEditor autocomplete

- (IBAction)addAutocompleteString:(id)sender{
    // first we fill the popup
	NSMutableArray *fieldNames = [[[[BibTypeManager sharedManager] allRemovableFieldNames] mutableCopy] autorelease];
	[fieldNames addObjectsFromArray:[NSArray arrayWithObjects:BDSKUrlString, BDSKLocalUrlString, BDSKKeywordsString, nil]];
	[fieldNames removeObjectsInArray:enabledEditorAutocompletionStrings];
	[fieldNames sortUsingSelector:@selector(caseInsensitiveCompare:)];
	[fieldNames insertObject:NSLocalizedString(@"Choose a Field Name:",@"") atIndex:0];
	[addFieldPopupButton removeAllItems];
	[addFieldPopupButton addItemsWithTitles:fieldNames];
	
    [NSApp beginSheet:addFieldSheet
       modalForWindow:[[OAPreferenceController sharedPreferenceController] window]
        modalDelegate:self
       didEndSelector:@selector(addFieldSheetDidEnd:returnCode:contextInfo:)
          contextInfo:nil];
}

- (void)addFieldSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo{
    if(returnCode == 1){
        [enabledEditorAutocompletionStrings addObject:[[addField stringValue] capitalizedString]];
        [defaults setObject:enabledEditorAutocompletionStrings forKey:BDSKBibEditorAutocompletionFields];
    }
    [self updateUI];
}

- (IBAction)dismissAddFieldSheet:(id)sender{
    [addFieldSheet orderOut:sender];
    [NSApp endSheet:addFieldSheet returnCode:[sender tag]];
}

- (IBAction)selectFieldToAutocomplete:(id)sender{
	if([sender indexOfSelectedItem] > 0){
		[addField setStringValue:[sender titleOfSelectedItem]];
	}
}

- (IBAction)removeAutocompleteString:(id)sender{
    if([editorAutocompletionStringsTableView selectedRow] != -1){
        [enabledEditorAutocompletionStrings removeObjectAtIndex:[editorAutocompletionStringsTableView selectedRow]];
        [defaults setObject:enabledEditorAutocompletionStrings forKey:BDSKBibEditorAutocompletionFields];
    }
    [self updateUI];    
}

@end
