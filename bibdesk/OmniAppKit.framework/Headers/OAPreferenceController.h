// Copyright 1997-2002 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header$

#import <OmniFoundation/OFObject.h>
#import <Foundation/NSGeometry.h>

@class NSArray, NSMutableArray, NSMutableDictionary;
@class NSBox, NSButton, NSImageView, NSMatrix, NSTabView, NSTextField, NSToolbar, NSView, NSWindow;
@class OAPreferenceClient, OAPreferenceClientRecord, OAPreferencesIconView, OAPreferencesShowAllIconView;
@class OAPreferencesMultipleIconView;

#import <AppKit/NSNibDeclarations.h> // For IBOutlet

typedef enum OAPreferencesViewStyle {
        OAPreferencesViewSingle = 0, // one client, so no navigation bar
        OAPreferencesViewMultiple = 1, // several clients, presented a la Mail or Terminal
        OAPreferencesViewCustomizable = 2 // many clients in one or more categories, presented a la System Prefs. 
} OAPreferencesViewStyle;

@interface OAPreferenceController : OFObject
{
    IBOutlet NSWindow *window;
    IBOutlet NSBox *preferenceBox;
    IBOutlet NSBox *iconsBox;
    IBOutlet NSView *globalControlsView;
    IBOutlet NSButton *helpButton;
    IBOutlet NSButton *returnToOriginalValuesButton;
    
    NSView *showAllIconsView; // not to be confused with the "Show All" button
    OAPreferencesIconView *multipleIconView;
    
    NSMutableArray *preferencesIconViews;
    NSMutableDictionary *categoryNamesToClientRecordsArrays;
    NSMutableDictionary *localizedCategoryNames;
    NSMutableDictionary *categoryPriorities;
    
    NSMutableArray *allClientRecords;

    OAPreferencesViewStyle viewStyle;
    
    NSToolbar *toolbar;
    NSArray *defaultToolbarItems;
    NSArray *allowedToolbarItems;

    OAPreferenceClientRecord *nonretained_currentClientRecord;
    OAPreferenceClient *nonretained_currentClient;    
}

+ (OAPreferenceController *)sharedPreferenceController;

// API
- (void)close;
- (void)setTitle:(NSString *)title;
- (void)setCurrentClientByClassName:(NSString *)name;
- (NSArray *)allClientRecords;
- (OAPreferenceClientRecord *)clientRecordWithShortTitle:(NSString *)shortTitle;
- (OAPreferenceClientRecord *)clientRecordWithIdentifier:(NSString *)identifier;
- (OAPreferenceClient *)clientWithShortTitle:(NSString *)shortTitle;
- (OAPreferenceClient *)clientWithIdentifier:(NSString *)identifier;
- (void)iconView:(OAPreferencesIconView *)iconView buttonHitAtIndex:(unsigned int)index;

// Actions
- (IBAction)showPreferencesPanel:(id)sender;
- (IBAction)restoreDefaults:(id)sender;
- (IBAction)showNextClient:(id)sender;
- (IBAction)showPreviousClient:(id)sender;
- (IBAction)setCurrentClientFromToolbarItem:(id)sender;
- (IBAction)showHelpForClient:(id)sender;


@end

