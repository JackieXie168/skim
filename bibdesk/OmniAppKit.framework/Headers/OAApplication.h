// Copyright 1997-2002 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header$

#import <AppKit/NSApplication.h>

@class NSDate, NSException;
@class OFSoftwareUpdateChecker;

#import <Foundation/NSDate.h> // For NSTimeInterval
#import <AppKit/NSNibDeclarations.h> // For IBAction

@interface OAApplication : NSApplication
{
    NSDate *exceptionCheckpointDate;
    unsigned int exceptionCount;
    NSTimeInterval lastEventTimeInterval;
    unsigned int mouseButtonState;
    
    OFSoftwareUpdateChecker *softwareUpdate;
}

- (void)handleInitException:(NSException *)anException;
- (void)handleRunException:(NSException *)anException;

- (NSTimeInterval)lastEventTimeInterval;
- (BOOL)mouseButtonIsDownAtIndex:(unsigned int)mouseButtonIndex;
- (BOOL)scrollWheelButtonIsDown;

// Show a specific Help page in an appropriate viewer.
- (void)showHelpURL:(NSString *)helpURL;
    // - If invoked in OmniWeb, opens the URL in OmniWeb. helpURL should be an omniweb: URL.
    // - If invoked in an application that has Apple Help content (determined by the presence
    // of the CFBundleHelpBookName key in the app's Info.plist), the URL will display in 
    // Help Viewer. helpURL *must* be a path relative to the help book folder.
    // - Otherwise, we hand the URL off to NSWorkspace. This should generally be avoided.

// Actions
- (IBAction)closeAllMainWindows:(id)sender;
- (IBAction)miniaturizeAll:(id)sender;
- (IBAction)cycleToNextMainWindow:(id)sender;
- (IBAction)cycleToPreviousMainWindow:(id)sender;
- (IBAction)showInspectorPanel:(id)sender;
- (IBAction)showPreferencesPanel:(id)sender;

// Check for new version of this application on Omni's web site.
- (IBAction)checkForNewVersion:(id)sender;
// Check for a new version, and present result/error messages as sheets attached to aWindow.
- (void)checkForNewVersionFromWindow:(NSWindow *)aWindow;

@end
