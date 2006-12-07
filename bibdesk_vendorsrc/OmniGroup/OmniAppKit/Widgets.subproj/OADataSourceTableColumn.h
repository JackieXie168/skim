// Copyright 2003-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OADataSourceTableColumn.h,v 1.3 2004/02/10 04:07:37 kc Exp $

#import <AppKit/NSTableColumn.h>

@interface OADataSourceTableColumn : NSTableColumn
@end

@interface NSObject (OADataSourceTableColumn)
// This should have been a dataSource method in the first place.
- (NSCell *)tableView:(NSTableView *)tableView column:(OADataSourceTableColumn *)tableColumn dataCellForRow:(int)row;
@end
