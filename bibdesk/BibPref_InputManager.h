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
extern NSString *BDSKInputManagerLoadableApplications;

@interface BibPref_InputManager : OAPreferenceClient
{
    NSString *inputManagerPath;
    IBOutlet NSTableView *appList;
    IBOutlet NSButton *enableButton;
    NSMutableArray *appListArray;
    IBOutlet NSTableView *editorAutocompletionStringsTableView;
    NSMutableArray *enabledEditorAutocompletionStrings;
    IBOutlet NSPanel *addFieldSheet;
    IBOutlet NSTextField *addField;
    IBOutlet NSPopUpButton *addFieldPopupButton;
    IBOutlet NSTabView *acTabView;
}
/*!
    @method     bundleIDForPath:
    @abstract   Returns the CFBundleIdentifier for a given application bundle path.
    @param      path  Full path to the application bundle, e.g. /Applications/TextEdit.app.
    @result     The CFBundleIdentifier from the application's plist, e.g. com.apple.TextEdit for TextEdit.app.
*/
- (NSString *)bundleIDForPath:(NSString *)path;
- (BOOL)isInstalledVersionCurrent;
- (IBAction)enableAutocompletion:(id)sender;
- (IBAction)addApplication:(id)sender;
- (IBAction)removeApplication:(id)sender;
- (IBAction)addAutocompleteString:(id)sender;
- (IBAction)removeAutocompleteString:(id)sender;
- (IBAction)selectFieldToAutocomplete:(id)sender;
@end
