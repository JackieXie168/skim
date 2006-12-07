// Copyright 1999-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSOutlineView-OAExtensions.h,v 1.14 2003/04/25 07:39:31 rick Exp $


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
