// Copyright 1999-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSOutlineView-OAExtensions.h 68913 2005-10-03 19:36:19Z kc $


#import <OmniBase/SystemType.h>

#import <AppKit/NSOutlineView.h>

#import <OmniAppKit/NSTableView-OAExtensions.h>
#import <AppKit/NSNibDeclarations.h> // For IBAction, IBOutlet

@interface NSOutlineView (OAExtensions)

- (id)selectedItem;
- (NSArray *)selectedItems;

// Requires the parent(s) of the selected item to already be expanded. 
- (void)setSelectedItem:(id)item;
- (void)setSelectedItem:(id)item visibility:(OATableViewRowVisibility)visibility;
- (void)setSelectedItems:(NSArray *)items;
- (void)setSelectedItems:(NSArray *)items visibility:(OATableViewRowVisibility)visibility;

- (id)firstItem;

- (void)expandAllItemsAtLevel:(unsigned int)level;

- (void)expandItemAndChildren:(id)item;
- (void)collapseItemAndChildren:(id)item;

// Actions
- (IBAction)expandAll:(id)sender;
- (IBAction)contractAll:(id)sender;

@end
