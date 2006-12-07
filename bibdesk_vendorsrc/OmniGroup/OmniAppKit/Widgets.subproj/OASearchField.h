// Copyright 2003-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OASearchField.h,v 1.8 2004/02/10 04:07:38 kc Exp $

#import "OABackgroundImageControl.h"

@class NSTimer;	// Foundation
@class NSMenu, NSTextField;	// AppKit


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
    } flags;
}

// API

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

@end

@interface NSObject (OASearchFieldDelegate)
- (void)searchField:(OASearchField *)aSearchField didChooseSearchMode:(id)newSearchMode;
@end
