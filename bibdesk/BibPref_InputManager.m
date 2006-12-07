//
//  BibPref_InputManager.m
//  BibDesk
//
//  Created by Adam Maxwell on Fri Aug 27 2004.
/*
 This software is Copyright (c) 2004,2005,2006
 Adam Maxwell. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Adam Maxwell nor the names of any
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



#import "BibPref_InputManager.h"
#import "BibTypeManager.h"
#import "NSImage+Toolbox.h"
#import "BDSKTextWithIconCell.h"
#import "BDSKSearchResult.h"

CFStringRef BDSKInputManagerID = CFSTR("net.sourceforge.bibdesk.inputmanager");
CFStringRef BDSKInputManagerLoadableApplications = CFSTR("Application bundles that we recognize");

static int tableIconSize = 24;

@implementation BibPref_InputManager

- (void)awakeFromNib{
    [super awakeFromNib];
    
    NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    inputManagerPath = [[libraryPath stringByAppendingPathComponent:@"/InputManagers/BibDeskInputManager"] retain];

    applications = [[NSMutableArray alloc] initWithCapacity:3];

    CFPropertyListRef prefs = CFPreferencesCopyAppValue(BDSKInputManagerLoadableApplications, BDSKInputManagerID );
                                                      
    if(prefs != nil){
        [self addApplicationsWithIdentifiers:(NSArray *)prefs];
        CFRelease(prefs);
    }
    	
    BDSKTextWithIconCell *cell = [[[BDSKTextWithIconCell alloc] init] autorelease];
    [cell setDrawsHighlight:NO];
    [[tableView tableColumnWithIdentifier:@"AppList"] setDataCell:cell];
    [tableView setRowHeight:(tableIconSize + 2)];

    if(![self isInstalledVersionCurrent]){
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
    
}

- (void)addApplicationsWithIdentifiers:(NSArray *)identifiers{
    NSParameterAssert(identifiers);
        
    NSString *bundleID;
    NSEnumerator *identifierE = [identifiers objectEnumerator];
    
    // use a set so we don't add duplicate items to the array (not that it's particularly harmful)
    NSMutableSet *applicationSet = [NSMutableSet set];
    
    while(bundleID = [identifierE nextObject]){
    
        CFURLRef theURL = nil;
        BDSKSearchResult *dictionary = [[BDSKSearchResult alloc] initWithKey:bundleID caseInsensitive:YES];
        
        OSStatus err = LSFindApplicationForInfo( kLSUnknownCreator,
                                                 (CFStringRef)bundleID,
                                                 NULL,
                                                 NULL,
                                                 &theURL );
        
        if(err == noErr){
            [dictionary setValue:[[[(NSURL *)theURL path] lastPathComponent] stringByDeletingPathExtension] forKey:OATextWithIconCellStringKey];
            [dictionary setValue:[[NSWorkspace sharedWorkspace] iconForFile:[(NSURL *)theURL path]] forKey:OATextWithIconCellImageKey];
        } else {
            // if LS failed us (my cache was corrupt when I wrote this code, so it's been tested)
            [dictionary setValue:[NSString stringWithFormat:@"%@ \"%@\"", NSLocalizedString(@"Unable to find icon for",@""), bundleID] forKey:OATextWithIconCellStringKey];
            [dictionary setValue:[NSImage iconWithSize:NSMakeSize(tableIconSize, tableIconSize) forToolboxCode:kGenericApplicationIcon] forKey:OATextWithIconCellImageKey];
        }
        
        [applicationSet addObject:dictionary];
        [dictionary release];
    
    }
    NSSortDescriptor *sort = [[[NSSortDescriptor alloc] initWithKey:@"dictionary.string" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)] autorelease];
    [self willChangeValueForKey:@"applications"];
    [applications addObjectsFromSet:applicationSet];
    [applications sortUsingDescriptors:[NSArray arrayWithObject:sort]];
    [self didChangeValueForKey:@"applications"];
    
    [self synchronizePreferences];
}

// writes current displayed list to preferences
- (void)synchronizePreferences{
    
    // this should be a unique list of the identifiers that we previously had in prefs; bundles are compared case-insensitively
    NSMutableSet *applicationSet = (NSMutableSet *)CFSetCreateMutable(CFAllocatorGetDefault(), 0, &OFCaseInsensitiveStringSetCallbacks);
    [applicationSet autorelease];
    
    NSEnumerator *enumerator = [applications objectEnumerator];
    BDSKSearchResult *dictionary;
    
    while(dictionary = [enumerator nextObject])
        [applicationSet addObject:[dictionary valueForKey:@"comparisonKey"]];
    
    CFPreferencesSetAppValue(BDSKInputManagerLoadableApplications, (CFArrayRef)[applicationSet allObjects], BDSKInputManagerID);
    BOOL success = CFPreferencesAppSynchronize( (CFStringRef)BDSKInputManagerID );
    if(success == NO)
        NSLog(@"Failed to synchronize preferences for %@", BDSKInputManagerID);
    
}

- (void)dealloc{
    [inputManagerPath release];
    [applications release];
	[arrayController release];
    [super dealloc];
}

- (void)updateUI{
    if([[NSFileManager defaultManager] fileExistsAtPath:inputManagerPath])
        [enableButton setTitle:NSLocalizedString(@"Reinstall",@"Reinstall input manager")];

    [tableView reloadData];
}

- (void)updateAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo{
    if(returnCode == 1) // AppKit bug: NSAlertFirstButtonReturn doesn't work
        [self enableAutocompletion:nil];
}

 
#pragma mark Citekey autocompletion

- (void)enableCompletionSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo{
    
    if(returnCode == NSAlertAlternateReturn)
        return; // do nothing; user chickened out
    
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL err = NO;
    NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    if(![fm fileExistsAtPath:[libraryPath stringByAppendingPathComponent:@"InputManagers"]]){
        if(![fm createDirectoryAtPath:[libraryPath stringByAppendingPathComponent:@"InputManagers"] attributes:nil]){
            NSLog(@"Unable to create the InputManagers folder at path @%",[libraryPath stringByAppendingPathComponent:@"InputManagers"]);
            err = YES;
        }
    }
    
    if(err == NO && [fm fileExistsAtPath:inputManagerPath] && ([fm isDeletableFileAtPath:inputManagerPath] == NO || [fm removeFileAtPath:inputManagerPath handler:nil] == NO)){
        NSLog(@"Error occurred while removing file %@", inputManagerPath);
        err = YES;
    }
	
    if(err == NO){
        [fm copyPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"BibDeskInputManager"] toPath:inputManagerPath handler:nil];
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

- (IBAction)enableAutocompletion:(id)sender{
    
    NSBeginAlertSheet(NSLocalizedString(@"Warning!", @""), NSLocalizedString(@"Proceed",@""), NSLocalizedString(@"Cancel",@""), nil, [[self controlBox] window], self, @selector(enableCompletionSheetDidEnd:returnCode:contextInfo:), NULL, NULL, NSLocalizedString(@"This will install a plugin bundle in ~/Library/InputManagers/BibDeskInputManager.  If you experience text input problems or strange application behavior after installing the plugin, try removing the \"BibDeskInputManager\" subfolder.", @""));
    
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
    [op setPrompt:NSLocalizedString(@"Add", @"")];
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
        NSString *bundleID = [[NSBundle bundleWithPath:[[sheet filenames] objectAtIndex:0]] bundleIdentifier];
        if(bundleID == nil){
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
            [self addApplicationsWithIdentifiers:[NSArray arrayWithObject:bundleID]];
            [self updateUI];
        }
    } else if(returnCode == NSCancelButton){
	    // do nothing
    }
}

- (IBAction)removeApplication:(id)sender{
    if([tableView selectedRow] != -1){
        [self willChangeValueForKey:@"applications"];
        [applications removeObjectAtIndex:[tableView selectedRow]];
        [self didChangeValueForKey:@"applications"];
        [self synchronizePreferences];
    }
    [self updateUI];
}

@end
