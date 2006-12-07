// Copyright 2003-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/SourceRelease_2005-10-03/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OASearchField.h 66043 2005-07-25 21:17:05Z kc $

#import "OABackgroundImageControl.h"

@class NSTimer;	// Foundation
@class NSMenu, NSMenuItem, NSTextField;	// AppKit

#import <AppKit/NSNibDeclarations.h> // For IBAction, IBOutlet

@interface OASearchField : OABackgroundImageControl
{
    IBOutlet id delegate;
    
    NSTextField *searchField;
    NSMenu *menu;
    id searchMode;
    NSTimer *partialStringActionDelayTimer;
    
    struct {
        unsigned int closeBoxVisible:1;
        unsigned int mouseDownInCloseBox:1;
        unsigned int isShowingSearchModeString:1;
        unsigned int isShowingMenu:1;
        unsigned int sendsWholeSearchString:1;
        unsigned int isSelectingText:1;
    } flags;
    struct {
        unsigned int searchFieldDidEndEditing:1;
        unsigned int searchField_didChooseSearchMode:1;
        unsigned int searchField_validateMenuItem:1;
        unsigned int control_textView_doCommandBySelector:1;
    } delegateRespondsTo;
}

// API

- (id)delegate;
- (void)setDelegate:(id)newValue;

- (NSMenu *)menu;
- (void)setMenu:(NSMenu *)aMenu;
    // This method sets the menu which pops up when the magnifying glass on the left is clicked.  Calling it will set the target and action of each item in aMenu, so do not count on those still being set upon return from this method.

- (void)selectText:(id)sender;
    
- (NSString *)stringValue;
    // The current search term.
    
- (id)searchMode;
    // The representedObject of the selected item in the search menu.
- (void)setSearchMode:(id)newSearchMode;
    // newSearchMode is assumed to be the representedObject of one of the items in the -menu.
- (void)updateSearchModeString;

- (BOOL)sendsActionOnEndEditing;
- (void)setSendsActionOnEndEditing:(BOOL)newValue;

- (BOOL)sendsWholeSearchString;
- (void)setSendsWholeSearchString:(BOOL)newValue;

- (void)clearSearch;

@end

@interface NSObject (OASearchFieldDelegate)
- (void)searchField:(OASearchField *)aSearchField didChooseSearchMode:(id)newSearchMode;
- (void)searchFieldDidEndEditing:(OASearchField *)aSearchField;
- (BOOL)searchField:(OASearchField *)aSearchField validateMenuItem:(NSMenuItem *)item;
@end
