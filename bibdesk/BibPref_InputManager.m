//
//  BibPref_InputManager.m
//  Bibdesk
//
//  Created by Adam Maxwell on Fri Aug 27 2004.
//  Copyright (c) 2004 Adam R. Maxwell. All rights reserved.
//


#import "BibPref_InputManager.h"

NSString *BDSKInputManagerID = @"net.sourceforge.bibdesk.inputmanager";
NSString *BDSKInputManagerLoadableApplications = @"Application bundles that we recognize";

@implementation BibPref_InputManager

- (void)awakeFromNib{
    [super awakeFromNib];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    
    NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    inputManagerPath = [[libraryPath stringByAppendingPathComponent:@"/InputManagers/BibDeskInputManager"] retain];
    
    if(![ws respondsToSelector:@selector(absolutePathForAppBundleWithIdentifier:)]){ // check the OS version
        [enableButton setEnabled:NO];
        NSBeginAlertSheet(NSLocalizedString(@"Error!", @"Error!"),
                          nil, nil, nil, [[OAPreferenceController sharedPreferenceController] window], nil, nil, nil, nil,
                          NSLocalizedString(@"You appear to be using a system version earlier than 10.3.  Autocompletion requires Mac OS X 10.3 or greater.",
                                            @"You appear to be using a system version earlier than 10.3.  Autocompletion requires Mac OS X 10.3 or greater.") );
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
                               informativeTextWithFormat:@"You can install a newer version of the autocompletion plugin by clicking the \"Update\" button below."];
        [anAlert beginSheetModalForWindow:[[OAPreferenceController sharedPreferenceController] window]
                            modalDelegate:self
                           didEndSelector:@selector(updateAlertDidEnd:returnCode:contextInfo:)
                              contextInfo:nil];
    }
}

- (void)dealloc{
    [inputManagerPath release];
    [appListArray release];
    [super dealloc];
}

- (void)updateUI{
    // NSLog(@"-[%@ %@] 0x%x", [self class], NSStringFromSelector(_cmd), self);
    if([[NSFileManager defaultManager] fileExistsAtPath:inputManagerPath]){
	[enableButton setTitle:NSLocalizedString(@"Reinstall",@"Reinstall input manager")];
	[enableButton sizeToFit];
    }

    CFPreferencesSetAppValue( (CFStringRef)BDSKInputManagerLoadableApplications,
                              appListArray,
                              (CFStringRef)BDSKInputManagerID );
    BOOL success = CFPreferencesAppSynchronize( (CFStringRef)BDSKInputManagerID );
    NSAssert1( success, @"Failed to synchronize preferences for %@", BDSKInputManagerID);

    [appList reloadData];
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

- (int)numberOfRowsInTableView:(NSTableView *)tableView{
    return [appListArray count];
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex{
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
        [aCell setStringValue:[NSString stringWithFormat:@"Error %d, LaunchServices can't find %@", err, inBundleID]];
    }

    [image setSize:NSMakeSize(size, size)];
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
	    NSAlert *anAlert = [NSAlert alertWithMessageText:@"Error!"
					       defaultButton:nil
					     alternateButton:nil
						 otherButton:nil
				   informativeTextWithFormat:@"%@ is not a Cocoa application.", [[sheet filenames] objectAtIndex:0]];
	    [anAlert beginSheetModalForWindow:[[OAPreferenceController sharedPreferenceController] window]
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
    [appListArray removeObjectAtIndex:[appList selectedRow]];
    [self updateUI];
}

@end
