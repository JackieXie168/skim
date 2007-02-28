// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OAConfigurableColumnTableView.h 68913 2005-10-03 19:36:19Z kc $

#import <AppKit/NSTableView.h>

// This provides a context menu that allows the user to configured the list of displayed columns.

@class NSMatrix, NSWindow;

@interface OAConfigurableColumnTableView : NSTableView
{
    NSMenu *configurationMenu;
    struct {
        unsigned int menuString     : 1;
        unsigned int addSeparator   : 1;
        unsigned int allowToggle    : 1;
        unsigned int willActivate   : 1;
        unsigned int didActivate    : 1;
        unsigned int willDeactivate : 1;
        unsigned int didDeactivate  : 1;
    } confDataSourceFlags;
}

- (NSMenu *) configurationMenu;

- (NSArray *)inactiveTableColumns;

- (void)activateTableColumn:(NSTableColumn *)column;
- (void)deactivateTableColumn:(NSTableColumn *)column;
- (void)toggleTableColumn:(NSTableColumn *)column;
- (BOOL)isTableColumnActive:(NSTableColumn *)column;

@end

// These are all optional
@interface NSObject (OAConfigurableColumnTableViewExtendedDataSource)

// Returns a more detailed description of the table column (possibly wider than the header cell of the column should be).
- (NSString *) configurableColumnTableView: (OAConfigurableColumnTableView *) tableView
                       menuStringForColumn: (NSTableColumn *) column;

// If this return NO, the table column will not be present in the configuration menu (and thus cannot be disabled).
- (BOOL) configurableColumnTableView: (OAConfigurableColumnTableView *) tableView
           shouldAllowTogglingColumn: (NSTableColumn *) column;

- (BOOL) configurableColumnTableView: (OAConfigurableColumnTableView *) tableView
       shouldAddSeparatorAfterColumn: (NSTableColumn *) column;
       
- (void) configurableColumnTableView: (OAConfigurableColumnTableView *) tableView
                  willActivateColumn: (NSTableColumn *) column;
- (void) configurableColumnTableView: (OAConfigurableColumnTableView *) tableView
                   didActivateColumn: (NSTableColumn *) column;

- (void) configurableColumnTableView: (OAConfigurableColumnTableView *) tableView
                willDeactivateColumn: (NSTableColumn *) column;
- (void) configurableColumnTableView: (OAConfigurableColumnTableView *) tableView
                 didDeactivateColumn: (NSTableColumn *) column;
                 
@end
