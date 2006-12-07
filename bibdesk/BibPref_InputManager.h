//
//  BibPref_InputManager.h
//  Bibdesk
//
//  Created by Adam Maxwell on Fri Aug 27 2004.
//  Copyright (c) 2004 Adam R. Maxwell. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BibPrefController.h"

extern NSString *BDSKInputManagerID;

@interface BibPref_InputManager : OAPreferenceClient
{
    NSString *applicationSupportPath;
    NSString *inputManagerPath;
    IBOutlet NSTableView *appList;
    IBOutlet NSButton *enableButton;
    NSMutableArray *appListArray;
}

/*!
    @method     setBundleID
    @abstract   Sets the bundle identifier for all of the application paths in the input manager's plist.
    @discussion The input manager's plist dictionary key for this is "BundleID", even though it's a duplicate
		of the chosen application's CFBundleIdentifier, to avoid confusion in the input manager code.
*/
- (void)setBundleID;
/*!
    @method     bundleIDForPath:
    @abstract   Returns the CFBundleIdentifier for a given application bundle path.
    @param      path  Full path to the application bundle, e.g. /Applications/TextEdit.app.
    @result     The CFBundleIdentifier from the application's plist, e.g. com.apple.TextEdit for TextEdit.app.
*/
- (NSString *)bundleIDForPath:(NSString *)path;

- (IBAction)enableAutocompletion:(id)sender;
- (IBAction)addApplication:(id)sender;
- (IBAction)removeApplication:(id)sender;

/*!
    @method     cacheAppList
    @abstract   Write out a plist with the app names and bundle identifiers.
    @discussion This gets written to the input manager's application support hierarchy, not BibDesk's.
*/
- (void)cacheAppList;

@end
