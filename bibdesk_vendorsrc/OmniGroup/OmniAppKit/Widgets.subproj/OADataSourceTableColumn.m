// Copyright 2003-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniAppKit/OADataSourceTableColumn.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OADataSourceTableColumn.m,v 1.3 2004/02/10 04:07:37 kc Exp $");

@implementation OADataSourceTableColumn

- (id)dataCellForRow:(int)row;
{
    // Can't cache whether the data source implementes the extra data source method since table columns don't get notified of data source changes.  Instead, just assume that the data source implements it (otherwise, how would we get one of these?).

    // Doesn't default to [self dataCell] since otherwise the data source can't easily kill cells.
    // The dataSource can just return [tableColumn dataCell] if it wants.
    NSTableView *tableView = [self tableView];

    return [[tableView dataSource] tableView:tableView column:self dataCellForRow:row];
}

@end
