// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OAApplication.h,v 1.33 2004/02/10 04:07:30 kc Exp $

#import <AppKit/NSApplication.h>

@class NSDate, NSException, NSMutableArray, NSMutableDictionary;
@class OFSoftwareUpdateChecker;

#import <Foundation/NSDate.h> // For NSTimeInterval
#import <AppKit/NSNibDeclarations.h> // For IBAction

@interface OAApplication : NSApplication
{
    NSDate *exceptionCheckpointDate;
    unsigned int exceptionCount;
    NSTimeInterval lastEventTimeInterval;
    unsigned int mouseButtonState;
    NSMutableDictionary *windowsForSheets;
    NSMutableArray *sheetQueue;
}

- (void)handleInitException:(NSException *)anException;
- (void)handleRunException:(NSException *)anException;

- (NSTimeInterval)lastEventTimeInterval;
- (BOOL)mouseButtonIsDownAtIndex:(unsigned int)mouseButtonIndex;
- (BOOL)scrollWheelButtonIsDown;
- (BOOL)checkForModifierFlags:(unsigned int)flags;
    // can't check for Shift key -- need better implementation for that.

// Show a specific Help page in an appropriate viewer.
- (void)showHelpURL:(NSString *)helpURL;
    // - If invoked in OmniWeb, opens the URL in OmniWeb. helpURL should be a path relative to omniweb:/Help/.
    // - If invoked in an application that has Apple Help content (determined by the presence of the CFBundleHelpBookName key in the app's Info.plist), the URL will display in  Help Viewer. helpURL should be a path relative to the help book folder.
    // - Otherwise, we hand the URL off to NSWorkspace. This should generally be avoided.

// Actions
- (IBAction)closeAllMainWindows:(id)sender;
- (IBAction)miniaturizeAll:(id)sender;
- (IBAction)cycleToNextMainWindow:(id)sender;
- (IBAction)cycleToPreviousMainWindow:(id)sender;
- (IBAction)toggleInspectorPanel:(id)sender;
- (IBAction)showPreferencesPanel:(id)sender;

// Check for new version of this application on Omni's web site.
- (IBAction)checkForNewVersion:(id)sender;

@end


// hooks for an external class to provide UI for OmniSoftwareUpdate
@protocol OASoftwareUpdateUI 
+ (void)checkSynchronouslyWithUIAttachedToWindow:(NSWindow *)aWindow;
// Use aWindow if you want to present your UI as a sheet
+ (void)newVersionAvailable:(NSDictionary *)versionInfo;
// forwarded callback from OFSoftwareUpdateChecker.
@end

#import <OmniAppKit/FrameworkDefines.h>

OmniAppKit_EXTERN NSString *OAFlagsChangedNotification; // Posted when we send a modfier-flags-changed event; notification object is the event
