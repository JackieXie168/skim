//
//  BibPref_InputManager.m
//  BibDesk
//
//  Created by Adam Maxwell on Fri Aug 27 2004.
/*
 This software is Copyright (c) 2004,2005,2006,2007
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
#import "NSSet_BDSKExtensions.h"
#import "BibAppController.h"
#import "NSURL_BDSKExtensions.h"
#import "NSWorkspace_BDSKExtensions.h"

CFStringRef BDSKInputManagerID = CFSTR("net.sourceforge.bibdesk.inputmanager");
CFStringRef BDSKInputManagerLoadableApplications = CFSTR("Application bundles that we recognize");

static NSString *BDSKBundleIdentifierKey = @"bundleIdentifierKey";
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

    NSSortDescriptor *sort = [[[NSSortDescriptor alloc] initWithKey:OATextWithIconCellStringKey ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)] autorelease];
    [arrayController setSortDescriptors:[NSArray arrayWithObject:sort]];
    
    [self updateUI];
}

- (void)addApplicationsWithIdentifiers:(NSArray *)identifiers{
    NSParameterAssert(identifiers);
        
    NSString *bundleID;

    // use a set so we don't add duplicate items to the array (not that it's particularly harmful)
    NSMutableSet *currentBundleIdentifiers = [NSMutableSet caseInsensitiveStringSet];
    [currentBundleIdentifiers addObjectsFromArray:[[arrayController content] valueForKey:OATextWithIconCellStringKey]];
    
    NSEnumerator *identifierE = [identifiers objectEnumerator];
        
    while((bundleID = [identifierE nextObject]) && ([currentBundleIdentifiers containsObject:bundleID] == NO)){
    
        CFURLRef theURL = nil;
        NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] initWithCapacity:2];
        
        OSStatus err = LSFindApplicationForInfo( kLSUnknownCreator,
                                                 (CFStringRef)bundleID,
                                                 NULL,
                                                 NULL,
                                                 &theURL );
        
        if(err == noErr){
            [dictionary setValue:[[(NSURL *)theURL lastPathComponent] stringByDeletingPathExtension] forKey:OATextWithIconCellStringKey];
            [dictionary setValue:[[NSWorkspace sharedWorkspace] iconForFileURL:(NSURL *)theURL] forKey:OATextWithIconCellImageKey];
            [dictionary setValue:bundleID forKey:BDSKBundleIdentifierKey];
        } else {
            // if LS failed us (my cache was corrupt when I wrote this code, so it's been tested)
            [dictionary setValue:[NSString stringWithFormat:@"%@ \"%@\"", NSLocalizedString(@"Unable to find icon for",@"Message when unable to find app for plugin"), bundleID] forKey:OATextWithIconCellStringKey];
            [dictionary setValue:[NSImage iconWithSize:NSMakeSize(tableIconSize, tableIconSize) forToolboxCode:kGenericApplicationIcon] forKey:OATextWithIconCellImageKey];
            [dictionary setValue:bundleID forKey:BDSKBundleIdentifierKey];
        }
        
        [arrayController addObject:dictionary];
        [dictionary release];
    
    }
    [arrayController rearrangeObjects];
    [self synchronizePreferences];
}

// writes current displayed list to preferences
- (void)synchronizePreferences{
    
    // this should be a unique list of the identifiers that we previously had in prefs; bundles are compared case-insensitively
    NSMutableSet *applicationSet = [NSMutableSet caseInsensitiveStringSet];
    [applicationSet addObjectsFromArray:[[arrayController content] valueForKey:BDSKBundleIdentifierKey]];
    
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
    BOOL isCurrent;
    if([[NSApp delegate] isInputManagerInstalledAndCurrent:&isCurrent])
        [enableButton setTitle:isCurrent ? NSLocalizedString(@"Reinstall",@"Button title") : NSLocalizedString(@"Update", @"Button title")];
    
    // this is a hack to show the blue highlight for the tableview, since it keeps losing first responder status
    [[controlBox window] makeFirstResponder:tableView];
}

#pragma mark Citekey autocompletion

- (void)enableCompletionSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo{
    
    if(returnCode == NSAlertAlternateReturn){
        // set tableview as first responder
        [self updateUI];
        return; // do nothing; user chickened out
    }
    
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
        NSAlert *anAlert = [NSAlert alertWithMessageText:NSLocalizedString(@"Error!",@"Message in alert dialog when an error occurs")
					   defaultButton:nil
					 alternateButton:nil
					     otherButton:nil
			       informativeTextWithFormat:NSLocalizedString(@"Unable to install plugin at %@, please check file or directory permissions.", @"Informative text in alert dialog"), inputManagerPath];
	[anAlert beginSheetModalForWindow:[[BDSKPreferenceController sharedPreferenceController] window]
			    modalDelegate:nil
			   didEndSelector:nil
			      contextInfo:nil];    
    }
    [self updateUI]; // change button to "Reinstall"
    
}

- (IBAction)enableAutocompletion:(id)sender{
    
    NSBeginAlertSheet(NSLocalizedString(@"Warning!", @"Message in alert dialog"), NSLocalizedString(@"Proceed", @"Button title"), NSLocalizedString(@"Cancel", @"Button title"), nil, [[self controlBox] window], self, @selector(enableCompletionSheetDidEnd:returnCode:contextInfo:), NULL, NULL, NSLocalizedString(@"This will install a plugin bundle in ~/Library/InputManagers/BibDeskInputManager.  If you experience text input problems or strange application behavior after installing the plugin, try removing the \"BibDeskInputManager\" subfolder.", @"Informative text in alert dialog"));
    
}

- (IBAction)addApplication:(id)sender{
    
    NSOpenPanel *op = [NSOpenPanel openPanel];
    [op setCanChooseDirectories:NO];
    [op setAllowsMultipleSelection:NO];
    [op setPrompt:NSLocalizedString(@"Add", @"Prompt for dialog to add an app for plugin")];
    [op beginSheetForDirectory:nil
			  file:nil
			 types:[NSArray arrayWithObject:@"app"]
		modalForWindow:[[BDSKPreferenceController sharedPreferenceController] window]
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
            NSAlert *anAlert = [NSAlert alertWithMessageText:NSLocalizedString(@"Error!",@"Message in alert dialog when an error occurs")
                               defaultButton:nil
                             alternateButton:nil
                             otherButton:nil
                       informativeTextWithFormat:NSLocalizedString(@"%@ is not a Cocoa application.", @"Informative text in alert dialog"), [[sheet filenames] objectAtIndex:0]];
            [anAlert beginSheetModalForWindow:[[BDSKPreferenceController sharedPreferenceController] window]
                    modalDelegate:nil
                       didEndSelector:nil
                      contextInfo:nil];
            return;
        }
        
        // LaTeX Equation Editor is Cocoa, but doesn't have a CFBundleIdentifier!  Perhaps there are others...
        NSString *bundleID = [[NSBundle bundleWithPath:[[sheet filenames] objectAtIndex:0]] bundleIdentifier];
        if(bundleID == nil){
            [sheet orderOut:nil];
            NSAlert *anAlert = [NSAlert alertWithMessageText:NSLocalizedString(@"No Bundle Identifier!",@"Message in alert dialog when no bundle identifier could be found for application to set for plugin")
                               defaultButton:nil
                             alternateButton:nil
                             otherButton:nil
                       informativeTextWithFormat:NSLocalizedString(@"The selected application does not have a bundle identifier.  Please inform the author of %@.", @"Informative text in alert dialog"), [[sheet filenames] objectAtIndex:0]];
            [anAlert beginSheetModalForWindow:[[BDSKPreferenceController sharedPreferenceController] window]
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
    unsigned int selIndex = [arrayController selectionIndex];
    if (NSNotFound != selIndex)
        [arrayController removeObjectAtArrangedObjectIndex:selIndex];
    [self synchronizePreferences];
    [self updateUI];
}

@end
