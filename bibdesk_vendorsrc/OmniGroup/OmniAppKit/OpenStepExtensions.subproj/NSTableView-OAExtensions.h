// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSTableView-OAExtensions.h 68913 2005-10-03 19:36:19Z kc $

#import <AppKit/NSTableView.h>
#import <AppKit/NSNibDeclarations.h>

typedef enum _OATableViewRowVisibility {
    OATableViewRowVisibilityLeaveUnchanged,
    OATableViewRowVisibilityScrollToVisible,
    OATableViewRowVisibilityScrollToMiddleIfNotVisible
} OATableViewRowVisibility;

#import <OmniAppKit/OAFindControllerTargetProtocol.h>

@interface NSTableView (OAExtensions) <OAFindControllerTarget>

- (NSArray *)selectedRows;
    // An array of NSNumbers containing row indices.
- (NSRect)rectOfSelectedRows;
    // Returns the rectangle enclosing all of the selected rows or NSZeroRect if there are no selected items
- (void)scrollSelectedRowsToVisibility:(OATableViewRowVisibility)visibility;
    // Calls -rectOfSelectedRows and then scrolls it to visible.

- (NSFont *)font;
- (void)setFont:(NSFont *)font;

// Actions
- (IBAction)copy:(id)sender; // If you support dragging out, you'll automatically support copy.
- (IBAction)delete:(id)sender; // Data source must support -tableView:deleteRows:.
- (IBAction)cut:(id)sender; // cut == copy + delete
- (IBAction)paste:(id)sender; // Data source must support -tableView:addItemsFromPasteboard:.
- (IBAction)duplicate:(id)sender; // duplicate == copy + paste (without using the general pasteboard)

@end

@interface NSObject (NSTableViewOAExtendedDataSource)

// Searching
- (BOOL)tableView:(NSTableView *)tableView itemAtRow:(int)row matchesPattern:(id <OAFindPattern>)pattern;
    // Implement this if you want find support.
- (NSTableColumn *)tableViewTypeAheadSelectionColumn:(NSTableView *)tableView;
    // Return non-nil to enable type-ahead selection. Needs a column whose values are strings (or respond to -stringValue)... presumably the names of your rows' represented objects. If your table has only one column, we'll choose it by default unless you implement this method to return nil.

// Content editing actions
- (BOOL)tableView:(NSTableView *)tableView addItemsFromPasteboard:(NSPasteboard *)pasteboard;
    // Called by paste & duplicate. Return NO to disallow, YES if successful.
- (void)tableView:(NSTableView *)tableView deleteRows:(NSArray *)rows;
    // Called by -delete:, keyboard delete keys, and drag-to-trash. 'rows' is an array of NSNumbers containing row indices.

// Drag image control
- (NSArray *)tableViewColumnIdentifiersForDragImage:(NSTableView *)tableView;
    // If you have a table similar to a Finder list view, where one or more columns contain a representation of the object associated with each row, and additional columns contain supplemental information (like sizes and mod dates), implement this method to specify which column(s) should be part of the dragged image. (Because you want to show the user that you're dragging a file, not a file and a date and a byte count.)
- (BOOL)tableView:(NSTableView *)tableView shouldShowDragImageForRow:(int)row;
    // If you'd like to support dragging of multiple-row selections, but want to control which of the selected rows is valid for dragging, implement this method in addition to -tableView:writeRows:toPasteboard:. If none of the selected rows are valid, return NO in -tableView:writeRows:toPasteboard:. If some of them are, write the valid ones to the pasteboard and return YES in -tableView:writeRows:toPasteboard:, and implement this method to return NO for the invalid ones. This prevents them from being drawn as part of the drag image, so that the items the user appears to be dragging are in sync with the items she's actually dragging.

- (NSDragOperation)tableView:(NSTableView *)tableView draggingSourceOperationMaskForLocal:(BOOL)isLocal;

// Additional editing actions
- (void)tableView:(NSTableView *)tableView insertNewline:(id)sender;
    // You may want to edit the currently selected item or insert a new item when Return is pressed.
- (BOOL)tableViewShouldEditNextItemWhenEditingEnds:(NSTableView *)tableView;
    // Normally tables like to move you to the next row when you hit return after editing a cell, but that's not always desirable.

// Context menus
- (NSMenu *)tableView:(NSTableView *)tableView contextMenuForRow:(int)row column:(int)column;

@end
